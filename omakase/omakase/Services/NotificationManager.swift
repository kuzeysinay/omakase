//
//  NotificationManager.swift
//  omakase
//
//  Manages UserNotifications authorization, local "Today's Menu" calendar reminders,
//  APNs/FCM device token registration, and deep-link routing in strict conformance
//  with Apple's UserNotifications and HIG Knowledge Contracts.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import Observation
import UIKit
import UserNotifications

extension Notification.Name {
    static let omakaseDidReceiveForegroundNotification = Notification.Name("omakase.didReceiveForegroundNotification")
}

enum NotificationDeepLink: Equatable, Sendable {
    case feed
    case community
    case sharedPost(postId: String)
}

enum LimitCardRemindResult: Equatable, Sendable {
    case scheduled(timeText: String)
    case denied
    case notGranted
}

@Observable
@MainActor
final class NotificationManager: NSObject {

    static let shared = NotificationManager()
    static let dailyMenuIdentifier = "omakase.daily-menu"

    // MARK: - Observable State

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var dailyReminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var commentPushEnabled: Bool
    var dailyDigestEnabled: Bool
    var pendingRoute: NotificationDeepLink?

    var reminderDateBinding: Date {
        Calendar.current.date(
            bySettingHour: reminderHour,
            minute: reminderMinute,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    var formattedReminderTime: String {
        String(format: "%02d:%02d", reminderHour, reminderMinute)
    }

    // MARK: - Private State

    @ObservationIgnored
    private let defaults = UserDefaults.standard
    @ObservationIgnored
    private var currentUID: String?
    @ObservationIgnored
    private var lastUploadedFCMToken: String?
    @ObservationIgnored
    private var apnsRetryCount: Int = 0
    @ObservationIgnored
    private var apnsRetryTask: Task<Void, Never>?

    private enum Keys {
        static let deviceID = "omakase.notification.device_id"
        static let dailyReminderEnabled = "omakase.notification.daily_enabled"
        static let reminderHour = "omakase.notification.reminder_hour"
        static let reminderMinute = "omakase.notification.reminder_minute"
        static let commentPushEnabled = "omakase.notification.comments_enabled"
        static let dailyDigestEnabled = "omakase.notification.digest_enabled"
    }

    private let categoryDailyMenu = "DAILY_MENU"
    private let categoryComment = "COMMENT_NOTIFICATION"
    private let categoryDigest = "SOCIAL_DIGEST"

    private var deviceId: String {
        if let existing = defaults.string(forKey: Keys.deviceID), !existing.isEmpty {
            return existing
        }
        let generated = UUID().uuidString.lowercased()
        defaults.set(generated, forKey: Keys.deviceID)
        return generated
    }

    private override init() {
        let d = UserDefaults.standard
        self.dailyReminderEnabled = d.object(forKey: Keys.dailyReminderEnabled) as? Bool ?? false
        self.reminderHour = d.object(forKey: Keys.reminderHour) as? Int ?? 9
        self.reminderMinute = d.object(forKey: Keys.reminderMinute) as? Int ?? 0
        self.commentPushEnabled = d.object(forKey: Keys.commentPushEnabled) as? Bool ?? true
        self.dailyDigestEnabled = d.object(forKey: Keys.dailyDigestEnabled) as? Bool ?? true
        super.init()
    }

    // MARK: - Launch Registration (Rules: categories once at launch, delegate before finishLaunching)

    func registerNotificationCategories(language: AppLanguage) {
        let l10n = L10n(lang: language)
        // Per HIG Notifications Rule 7: never add an "Open App" action; keep custom actions empty for v1.0.
        let dailyCategory = UNNotificationCategory(
            identifier: categoryDailyMenu,
            actions: [],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: l10n.hiddenPreviewDailyMenu,
            options: []
        )
        let commentCategory = UNNotificationCategory(
            identifier: categoryComment,
            actions: [],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: l10n.hiddenPreviewComment,
            options: []
        )
        let digestCategory = UNNotificationCategory(
            identifier: categoryDigest,
            actions: [],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: l10n.hiddenPreviewDigest,
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([
            dailyCategory,
            commentCategory,
            digestCategory
        ])
    }

    // MARK: - Authorization (authorization-request Rules 1-5)

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorizationIfNeeded() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let current = await center.notificationSettings()
        authorizationStatus = current.authorizationStatus

        guard current.authorizationStatus == .notDetermined else {
            return current.authorizationStatus
        }

        do {
            // Request only [.alert, .sound]; never request .badge (Rule 3 & HIG notifications Rule 8).
            _ = try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            ErrorReporter.record(error, mapped: .unknown, area: "notification_request_auth")
        }

        let updated = await center.notificationSettings()
        authorizationStatus = updated.authorizationStatus
        return updated.authorizationStatus
    }

    func openSystemNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Preferences & Firestore Sync

    func syncAuthUser(uid: String?) async {
        currentUID = uid
        guard let uid, !uid.isEmpty else {
            lastUploadedFCMToken = nil
            return
        }

        await refreshAuthorizationStatus()
        await loadRemotePreferences(uid: uid)
        await syncFCMTokenIfPossible()

        let lang = currentLanguage()
        let interests = currentInterests()
        let completedToday = !AccessManager.shared.isPro && AccessManager.shared.snapshot.platesRemaining == 0
        await syncDailyReminderOnForeground(
            interests: interests,
            language: lang,
            menuCompletedToday: completedToday
        )
    }

    func setDailyReminderEnabled(
        _ enabled: Bool,
        interests: [String],
        language: AppLanguage,
        menuCompletedToday: Bool
    ) async -> Bool {
        if enabled {
            let status = await requestAuthorizationIfNeeded()
            guard status == .authorized || status == .provisional else {
                dailyReminderEnabled = false
                persistLocalPreferences()
                return false
            }
            dailyReminderEnabled = true
            persistLocalPreferences()
            await saveRemotePreferences()
            await scheduleDailyMenuReminder(
                interests: interests,
                language: language,
                menuCompletedToday: menuCompletedToday
            )
            return true
        } else {
            dailyReminderEnabled = false
            persistLocalPreferences()
            await saveRemotePreferences()
            await cancelDailyMenuReminder()
            return true
        }
    }

    func updateReminderTime(
        _ date: Date,
        interests: [String],
        language: AppLanguage,
        menuCompletedToday: Bool
    ) async {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        reminderHour = comps.hour ?? 9
        reminderMinute = comps.minute ?? 0
        persistLocalPreferences()
        await saveRemotePreferences()
        if dailyReminderEnabled {
            await scheduleDailyMenuReminder(
                interests: interests,
                language: language,
                menuCompletedToday: menuCompletedToday
            )
        }
    }

    func setCommentPushEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            let status = await requestAuthorizationIfNeeded()
            guard status == .authorized || status == .provisional else {
                commentPushEnabled = false
                persistLocalPreferences()
                return false
            }
        }
        commentPushEnabled = enabled
        persistLocalPreferences()
        await saveRemotePreferences()
        return true
    }

    func setDailyDigestEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            let status = await requestAuthorizationIfNeeded()
            guard status == .authorized || status == .provisional else {
                dailyDigestEnabled = false
                persistLocalPreferences()
                return false
            }
        }
        dailyDigestEnabled = enabled
        persistLocalPreferences()
        await saveRemotePreferences()
        return true
    }

    func updatePreferencesForLanguageChange(_ language: AppLanguage) async {
        registerNotificationCategories(language: language)
        await saveRemotePreferences(languageOverride: language)
        if dailyReminderEnabled {
            let completedToday = !AccessManager.shared.isPro && AccessManager.shared.snapshot.platesRemaining == 0
            await scheduleDailyMenuReminder(
                interests: currentInterests(),
                language: language,
                menuCompletedToday: completedToday
            )
        }
    }

    func enableDailyReminderFromLimitCard(
        interests: [String],
        language: AppLanguage
    ) async -> LimitCardRemindResult {
        await refreshAuthorizationStatus()
        if authorizationStatus == .denied {
            return .denied
        }

        let finalStatus: UNAuthorizationStatus
        if authorizationStatus == .notDetermined {
            finalStatus = await requestAuthorizationIfNeeded()
        } else {
            finalStatus = authorizationStatus
        }

        switch finalStatus {
        case .authorized, .provisional, .ephemeral:
            dailyReminderEnabled = true
            persistLocalPreferences()
            await saveRemotePreferences(languageOverride: language)
            await scheduleDailyMenuReminder(
                interests: interests,
                language: language,
                menuCompletedToday: true
            )
            return .scheduled(timeText: formattedReminderTime)
        case .denied:
            return .denied
        default:
            return .notGranted
        }
    }

    // MARK: - Local Daily Menu Scheduling & Cleanup

    func syncDailyReminderOnForeground(
        interests: [String],
        language: AppLanguage,
        menuCompletedToday: Bool
    ) async {
        await refreshAuthorizationStatus()
        guard dailyReminderEnabled else { return }
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            await cancelDailyMenuReminder()
            return
        }
        await scheduleDailyMenuReminder(
            interests: interests,
            language: language,
            menuCompletedToday: menuCompletedToday
        )
    }

    func scheduleDailyMenuReminder(
        interests: [String],
        language: AppLanguage,
        menuCompletedToday: Bool
    ) async {
        guard dailyReminderEnabled,
              authorizationStatus == .authorized || authorizationStatus == .provisional else {
            return
        }

        let center = UNUserNotificationCenter.current()
        let l10n = L10n(lang: language)
        let rotated = Self.pickRotatedInterests(interests)

        let content = UNMutableNotificationContent()
        content.title = l10n.dailyMenuNotificationTitle
        content.body = l10n.dailyMenuNotificationBody(interests: rotated)
        content.sound = .default
        content.categoryIdentifier = categoryDailyMenu
        content.userInfo = ["route": "feed"]

        let now = Date()
        let cal = Calendar.current
        let todayTarget = cal.date(
            bySettingHour: reminderHour,
            minute: reminderMinute,
            second: 0,
            of: now
        )

        let trigger: UNCalendarNotificationTrigger
        if menuCompletedToday, let todayTarget, todayTarget > now {
            // Suppress today's reminder when menu is already completed; schedule specifically for tomorrow.
            let tomorrow = cal.date(byAdding: .day, value: 1, to: now) ?? now
            var tomorrowComps = cal.dateComponents([.year, .month, .day], from: tomorrow)
            tomorrowComps.hour = reminderHour
            tomorrowComps.minute = reminderMinute
            trigger = UNCalendarNotificationTrigger(dateMatching: tomorrowComps, repeats: false)
        } else {
            var dailyComps = DateComponents()
            dailyComps.hour = reminderHour
            dailyComps.minute = reminderMinute
            trigger = UNCalendarNotificationTrigger(dateMatching: dailyComps, repeats: true)
        }

        let request = UNNotificationRequest(
            identifier: Self.dailyMenuIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            ErrorReporter.record(error, mapped: .unknown, area: "notification_schedule_local")
        }
    }

    func cancelDailyMenuReminder() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let pendingIds = pending
            .map(\.identifier)
            .filter { $0 == Self.dailyMenuIdentifier }
        if !pendingIds.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: pendingIds)
        }

        let delivered = await center.deliveredNotifications()
        let deliveredIds = delivered
            .map { $0.request.identifier }
            .filter { $0 == Self.dailyMenuIdentifier }
        if !deliveredIds.isEmpty {
            center.removeDeliveredNotifications(withIdentifiers: deliveredIds)
        }

        do {
            try await center.setBadgeCount(0)
        } catch {
            ErrorReporter.record(error, mapped: .unknown, area: "notification_clear_badge")
        }
    }

    // MARK: - APNs & FCM Device Registration (remote-push-registration Rules 1-5)

    func handleAPNsTokenRegistered(_ deviceToken: Data) {
        apnsRetryCount = 0
        apnsRetryTask?.cancel()
        apnsRetryTask = nil
        // Forward raw Data unmodified to FirebaseMessaging APNs bridge (Rule 4).
        Messaging.messaging().apnsToken = deviceToken
        Task { @MainActor in
            await syncFCMTokenIfPossible()
        }
    }

    func handleAPNsRegistrationFailed(_ error: Error) {
        ErrorReporter.record(error, mapped: .unknown, area: "apns_registration")
        guard apnsRetryCount < 3 else { return }
        apnsRetryCount += 1
        let delaySeconds: UInt64
        switch apnsRetryCount {
        case 1: delaySeconds = 5
        case 2: delaySeconds = 15
        default: delaySeconds = 45
        }
        apnsRetryTask?.cancel()
        apnsRetryTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delaySeconds))
            guard !Task.isCancelled else { return }
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func handleFCMTokenReceived(_ fcmToken: String) async {
        let clean = fcmToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, let uid = currentUID ?? Auth.auth().currentUser?.uid else { return }
        await upsertDeviceDocument(uid: uid, fcmToken: clean)
    }

    func unregisterCurrentDevice(uid: String) async {
        guard !uid.isEmpty else { return }
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .collection("devices")
                .document(deviceId)
                .delete()
            lastUploadedFCMToken = nil
        } catch {
            ErrorReporter.record(error, mapped: .unknown, area: "notification_unregister_device")
        }
    }

    // MARK: - Social Push Event Trigger (fire-and-forget to Cloud Run)

    func notifySocialEvent(
        type: String,
        targetUid: String? = nil,
        postId: String? = nil,
        actorName: String? = nil,
        commentPreview: String? = nil
    ) {
        guard currentUID != nil || Auth.auth().currentUser != nil else { return }
        Task {
            var payload: [String: Any] = ["event_type": type]
            if let targetUid, !targetUid.isEmpty { payload["target_uid"] = targetUid }
            if let postId, !postId.isEmpty { payload["post_id"] = postId }
            if let actorName, !actorName.isEmpty { payload["actor_name"] = String(actorName.prefix(100)) }
            if let commentPreview, !commentPreview.isEmpty {
                payload["comment_preview"] = String(commentPreview.prefix(160))
            }

            guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
            let url = APITokenProvider.baseURL.appendingPathComponent("notifications/events")
            var request = URLRequest(url: url, timeoutInterval: 10)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body

            let authed = await APITokenProvider.shared.authorizedRequest(request)
            _ = try? await URLSession.shared.data(for: authed)
        }
    }

    // MARK: - Private Helpers

    private func persistLocalPreferences() {
        defaults.set(dailyReminderEnabled, forKey: Keys.dailyReminderEnabled)
        defaults.set(reminderHour, forKey: Keys.reminderHour)
        defaults.set(reminderMinute, forKey: Keys.reminderMinute)
        defaults.set(commentPushEnabled, forKey: Keys.commentPushEnabled)
        defaults.set(dailyDigestEnabled, forKey: Keys.dailyDigestEnabled)
    }

    private func loadRemotePreferences(uid: String) async {
        let ref = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("notification_prefs")
            .document("settings")
        do {
            let snap = try await ref.getDocument()
            if snap.exists, let data = snap.data() {
                dailyReminderEnabled = data["dailyReminderEnabled"] as? Bool ?? dailyReminderEnabled
                reminderHour = data["reminderHour"] as? Int ?? reminderHour
                reminderMinute = data["reminderMinute"] as? Int ?? reminderMinute
                commentPushEnabled = data["commentPushEnabled"] as? Bool ?? commentPushEnabled
                dailyDigestEnabled = data["dailyDigestEnabled"] as? Bool ?? dailyDigestEnabled
                persistLocalPreferences()

                let currentTZ = TimeZone.current.identifier
                let currentLang = currentLanguage().rawValue
                if (data["timezone"] as? String) != currentTZ || (data["language"] as? String) != currentLang {
                    await saveRemotePreferences()
                }
            } else {
                await saveRemotePreferences()
            }
        } catch {
            ErrorReporter.record(error, mapped: .unknown, area: "notification_load_prefs")
        }
    }

    private func saveRemotePreferences(languageOverride: AppLanguage? = nil) async {
        guard let uid = currentUID ?? Auth.auth().currentUser?.uid else { return }
        let lang = (languageOverride ?? currentLanguage()).rawValue
        let data: [String: Any] = [
            "dailyReminderEnabled": dailyReminderEnabled,
            "reminderHour": reminderHour,
            "reminderMinute": reminderMinute,
            "commentPushEnabled": commentPushEnabled,
            "dailyDigestEnabled": dailyDigestEnabled,
            "timezone": TimeZone.current.identifier,
            "language": lang == "tr" ? "tr" : "en",
            "updatedAt": FieldValue.serverTimestamp()
        ]
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .collection("notification_prefs")
                .document("settings")
                .setData(data, merge: true)
        } catch {
            ErrorReporter.record(error, mapped: .unknown, area: "notification_save_prefs")
        }
    }

    private func syncFCMTokenIfPossible() async {
        guard let uid = currentUID ?? Auth.auth().currentUser?.uid else { return }
        guard Messaging.messaging().apnsToken != nil else { return }
        do {
            let token = try await Messaging.messaging().token()
            let clean = token.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { return }
            await upsertDeviceDocument(uid: uid, fcmToken: clean)
        } catch {
            ErrorReporter.record(error, mapped: .unknown, area: "fcm_token_fetch")
        }
    }

    private func upsertDeviceDocument(uid: String, fcmToken: String) async {
        let lang = currentLanguage().rawValue
        let payload: [String: Any] = [
            "fcmToken": String(fcmToken.prefix(512)),
            "platform": "ios",
            "language": lang == "tr" ? "tr" : "en",
            "timezone": String(TimeZone.current.identifier.prefix(64)),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .collection("devices")
                .document(deviceId)
                .setData(payload, merge: true)
            lastUploadedFCMToken = fcmToken
        } catch {
            ErrorReporter.record(error, mapped: .unknown, area: "notification_save_device")
        }
    }

    private func currentLanguage() -> AppLanguage {
        AppLanguage.resolved(from: defaults)
    }

    private func currentInterests() -> [String] {
        let raw = defaults.string(forKey: "omakase.interests") ?? ""
        return raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func pickRotatedInterests(_ interests: [String]) -> [String] {
        guard !interests.isEmpty else { return [] }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let firstIdx = dayOfYear % interests.count
        if interests.count == 1 {
            return [interests[firstIdx]]
        }
        let secondIdx = (firstIdx + 1) % interests.count
        return [interests[firstIdx], interests[secondIdx]]
    }

    private func applyTappedNotificationUserInfo(route: String?, postId: String?) {
        if let postId, !postId.isEmpty {
            pendingRoute = .sharedPost(postId: postId)
        } else if route == "community" {
            pendingRoute = .community
        } else {
            pendingRoute = .feed
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate & MessagingDelegate

extension NotificationManager: UNUserNotificationCenterDelegate, MessagingDelegate {

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Suppress foreground banner per v1.0 spec & HIG notifications Rule 6; update UI unobtrusively instead.
        completionHandler([])
        Task { @MainActor in
            NotificationCenter.default.post(name: .omakaseDidReceiveForegroundNotification, object: nil)
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            let userInfo = response.notification.request.content.userInfo
            let route = userInfo["route"] as? String
            let postId = userInfo["postId"] as? String
            Task { @MainActor in
                NotificationManager.shared.applyTappedNotificationUserInfo(route: route, postId: postId)
            }
        case UNNotificationDismissActionIdentifier:
            break
        default:
            break
        }
        completionHandler()
    }

    nonisolated func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        guard let fcmToken, !fcmToken.isEmpty else { return }
        Task { @MainActor in
            await NotificationManager.shared.handleFCMTokenReceived(fcmToken)
        }
    }
}
