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

struct NotificationPostSeed: Codable, Equatable, Sendable {
    let id: String
    let title: String
    var topic: String
    var hasDeepDive: Bool
    var isBookmarked: Bool
    let createdAt: Date
}

struct PendingNotificationTopicRequest: Equatable, Sendable {
    let id: UUID
    let topic: String?
    let categoryId: String
}

@Observable
@MainActor
final class NotificationManager: NSObject {

    static let shared = NotificationManager()
    static let dailyMenuIdentifier = "omakase.daily-menu"
    static let dailyMenuIdentifierPrefix = "omakase.daily-menu"
    static let rollingDailyMenuDays = 7
    static let dailySlotsPerDay = 3
    static var allDailyMenuIdentifiers: [String] {
        var ids = [dailyMenuIdentifier]
        ids.append(contentsOf: (0..<rollingDailyMenuDays).map { "\(dailyMenuIdentifierPrefix).day-\($0)" })
        for d in 0..<rollingDailyMenuDays {
            for s in 0..<dailySlotsPerDay {
                ids.append("\(dailyMenuIdentifierPrefix).day-\(d)-slot-\(s)")
            }
        }
        return ids
    }

    // MARK: - Observable State

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var dailyReminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var commentPushEnabled: Bool
    var dailyDigestEnabled: Bool
    var pendingRoute: NotificationDeepLink?
    var pendingTopicRequest: PendingNotificationTopicRequest?

    func consumePendingTopicRequest() -> PendingNotificationTopicRequest? {
        defer { pendingTopicRequest = nil }
        return pendingTopicRequest
    }

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
    @ObservationIgnored
    private var recentPostSeeds: [NotificationPostSeed] = []

    private enum Keys {
        static let deviceID = "omakase.notification.device_id"
        static let dailyReminderEnabled = "omakase.notification.daily_enabled"
        static let reminderHour = "omakase.notification.reminder_hour"
        static let reminderMinute = "omakase.notification.reminder_minute"
        static let commentPushEnabled = "omakase.notification.comments_enabled"
        static let dailyDigestEnabled = "omakase.notification.digest_enabled"
        static let recentPostSeeds = "omakase.notification.recent_post_seeds"
    }

    private let categoryDailyMenu = "DAILY_MENU"
    private let categoryComment = "COMMENT_NOTIFICATION"
    private let categoryDigest = "SOCIAL_DIGEST"
    private static let maxStoredPostSeeds = 12

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
        if let seedData = d.data(forKey: Keys.recentPostSeeds),
           let decoded = try? JSONDecoder().decode([NotificationPostSeed].self, from: seedData) {
            self.recentPostSeeds = Array(decoded.prefix(Self.maxStoredPostSeeds))
        }
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

    // MARK: - Post-Seed Memory & 7-Day Rolling Daily Menu Scheduling

    func recordGeneratedPost(_ post: Post, language: AppLanguage) {
        guard let cleanTitle = Self.sanitizedPostTitle(post.title) else { return }
        let topic = Self.resolvedTopic(for: post, cleanTitle: cleanTitle, language: language)
        let hasDeepDive = !(post.deepDiveText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isBookmarked = BookmarkStore.shared.contains(postId: post.id)

        let seed = NotificationPostSeed(
            id: post.id.uuidString,
            title: cleanTitle,
            topic: topic,
            hasDeepDive: hasDeepDive,
            isBookmarked: isBookmarked,
            createdAt: post.createdAt
        )
        upsertPostSeed(seed)

        guard dailyReminderEnabled,
              authorizationStatus == .authorized || authorizationStatus == .provisional else {
            return
        }

        let interests = currentInterests()
        let completedToday = !AccessManager.shared.isPro && AccessManager.shared.snapshot.platesRemaining == 0
        Task { @MainActor in
            await scheduleDailyMenuReminder(
                interests: interests,
                language: language,
                menuCompletedToday: completedToday
            )
        }
    }

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
        let seeds = await hydrateSeedsIfNeeded(language: language)
        let cleanInterests = interests
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Remove any prior daily-menu requests (including legacy single-slot & 7-slot identifiers)
        // before installing the fresh 21-slot (3/day × 7 days) rolling schedule (local-notification-scheduling Rule 1).
        let existingPending = await center.pendingNotificationRequests()
        let staleIds = existingPending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.dailyMenuIdentifierPrefix) }
        if !staleIds.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: staleIds)
        }

        let now = Date()
        let cal = Calendar.current
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: now) ?? 1
        let slotTimes = dailySlotTimes()

        struct ScheduledSlot {
            let identifier: String
            let targetDate: Date
            let hour: Int
            let minute: Int
            let repeatsWeekly: Bool
        }

        var upcomingSlots: [ScheduledSlot] = []
        for dayOffset in 0..<Self.rollingDailyMenuDays {
            for (slotIndex, time) in slotTimes.enumerated() {
                let candidateToday = cal.date(byAdding: .day, value: dayOffset, to: now) ?? now
                let candidateDate = cal.date(
                    bySettingHour: time.hour,
                    minute: time.minute,
                    second: 0,
                    of: candidateToday
                ) ?? candidateToday

                // If today's earlier slot has already passed, push this slot one week ahead
                // so all 21 scheduled deliveries are strictly in the future.
                let effectiveDate: Date
                let isWrappedLastDay: Bool
                if dayOffset == 0 && candidateDate <= now {
                    effectiveDate = cal.date(byAdding: .day, value: Self.rollingDailyMenuDays, to: candidateDate) ?? candidateDate
                    isWrappedLastDay = true
                } else {
                    effectiveDate = candidateDate
                    isWrappedLastDay = (dayOffset == Self.rollingDailyMenuDays - 1)
                }

                upcomingSlots.append(
                    ScheduledSlot(
                        identifier: "\(Self.dailyMenuIdentifierPrefix).day-\(dayOffset)-slot-\(slotIndex)",
                        targetDate: effectiveDate,
                        hour: time.hour,
                        minute: time.minute,
                        repeatsWeekly: isWrappedLastDay
                    )
                )
            }
        }
        upcomingSlots.sort { $0.targetDate < $1.targetDate }

        let excludedTitles = Set(
            seeds.map(\.title)
                + BookmarkStore.shared.entries.map(\.title)
                + cleanInterests
        )
        let unseenCandidates = SubTopicDiscoveryStore.shared.pickUnseenNotificationCandidates(
            count: upcomingSlots.count,
            preferredInterests: cleanInterests,
            excludedTitles: excludedTitles,
            language: language,
            dayOfYear: dayOfYear
        )

        var previousArchetype: DailyNotificationArchetype?
        var previousSeedId: String?
        var previousSignature: String?
        var nextUnseenIndex = 0

        for (index, slot) in upcomingSlots.enumerated() {
            let content = UNMutableNotificationContent()
            let bucket = Self.rollNotificationBucket()

            if bucket == .unseenHeadline && nextUnseenIndex < unseenCandidates.count {
                let candidate = unseenCandidates[nextUnseenIndex]
                nextUnseenIndex += 1
                let copy = Self.composeUnseenTeaser(
                    slot: index,
                    dayOfYear: dayOfYear,
                    candidate: candidate,
                    l10n: l10n
                )
                content.title = copy.title
                content.body = copy.body
                content.userInfo = [
                    "route": "feed",
                    "unseenTopic": candidate.topic,
                    "categoryId": candidate.category.id,
                    "openPaywallIfOut": true
                ]
            } else if bucket == .classicDailyMenu {
                let topics = Self.rotatedTopics(
                    from: cleanInterests,
                    seed: nil,
                    shift: index + dayOfYear,
                    l10n: l10n
                )
                let topicPair: [String]
                if cleanInterests.isEmpty {
                    topicPair = [topics.first, topics.second]
                } else if cleanInterests.count == 1 {
                    topicPair = [cleanInterests[0]]
                } else {
                    topicPair = [topics.first, topics.second]
                }
                content.title = l10n.dailyMenuNotificationTitle
                content.body = l10n.dailyMenuNotificationBody(interests: topicPair)
                content.userInfo = [
                    "route": "feed",
                    "openPaywallIfOut": true
                ]
            } else {
                let livePlatesCount = Self.effectivePlatesCount(for: slot.targetDate, calendar: cal)
                let selection = Self.composeDailySlot(
                    slot: index,
                    dayOfYear: dayOfYear,
                    seeds: seeds,
                    interests: cleanInterests,
                    platesCount: livePlatesCount,
                    l10n: l10n,
                    previousArchetype: previousArchetype,
                    previousSeedId: previousSeedId,
                    previousSignature: previousSignature
                )
                previousArchetype = selection.archetype
                previousSeedId = selection.seedId
                previousSignature = "\(selection.title)|\(selection.body)"

                content.title = selection.title
                content.body = selection.body
                content.userInfo = [
                    "route": "feed",
                    "seedPostId": selection.seedId ?? "",
                    "openPaywallIfOut": true
                ]
            }

            content.sound = .default
            content.categoryIdentifier = categoryDailyMenu
            content.threadIdentifier = Self.dailyMenuIdentifierPrefix

            let trigger: UNCalendarNotificationTrigger
            if slot.repeatsWeekly {
                // Keep the 7th day repeating weekly so 3 daily prime-time reminders never stall if the user is away 7+ days.
                var weeklyComps = cal.dateComponents([.weekday], from: slot.targetDate)
                weeklyComps.hour = slot.hour
                weeklyComps.minute = slot.minute
                trigger = UNCalendarNotificationTrigger(dateMatching: weeklyComps, repeats: true)
            } else {
                var dateComps = cal.dateComponents([.year, .month, .day], from: slot.targetDate)
                dateComps.hour = slot.hour
                dateComps.minute = slot.minute
                trigger = UNCalendarNotificationTrigger(dateMatching: dateComps, repeats: false)
            }

            let request = UNNotificationRequest(
                identifier: slot.identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                ErrorReporter.record(error, mapped: .unknown, area: "notification_schedule_local")
            }
        }
    }

    /// Computes 3 well-spaced daily prime-time slots within `08:00–21:45` (never during `22:00–08:00` quiet hours),
    /// anchored around the user's preferred time, afternoon break (`15:30`), and evening prime time (`21:00`).
    private func dailySlotTimes() -> [(hour: Int, minute: Int)] {
        let minAllowed = 8 * 60        // 08:00
        let maxAllowed = 21 * 60 + 45  // 21:45
        let minSpacing = 210           // 3.5 hours minimum gap between daily deliveries

        let rawAnchor = reminderHour * 60 + reminderMinute
        let anchor = min(max(rawAnchor, minAllowed), maxAllowed)

        let preferredPairs: [(Int, Int)] = [
            (15 * 60 + 30, 21 * 60),       // 15:30 + 21:00 (default with 09:00 anchor)
            (10 * 60, 21 * 60),            // 10:00 + 21:00 (when user sets afternoon time)
            (10 * 60, 15 * 60 + 30),       // 10:00 + 15:30 (when user sets evening time)
            (9 * 60, 21 * 60),             // 09:00 + 21:00 (when user sets ~13:00-14:00)
            (9 * 60, 21 * 60 + 45),        // 09:00 + 21:45 (when user sets ~18:00)
            (9 * 60, 15 * 60 + 30),
            (8 * 60 + 30, 14 * 60),
            (8 * 60, 18 * 60)
        ]

        for (p1, p2) in preferredPairs {
            let sorted = [anchor, p1, p2].sorted()
            if sorted[1] - sorted[0] >= minSpacing && sorted[2] - sorted[1] >= minSpacing {
                return sorted.map { ($0 / 60, $0 % 60) }
            }
        }

        // Mathematical fallback: pick two evenly spaced points in [08:00, 21:45] respecting minSpacing.
        var chosen = [anchor]
        let grid = stride(from: minAllowed, through: maxAllowed, by: 30)
        for _ in 0..<2 {
            if let best = grid.max(by: { a, b in
                let gapA = chosen.map { abs($0 - a) }.min() ?? 0
                let gapB = chosen.map { abs($0 - b) }.min() ?? 0
                return gapA < gapB
            }) {
                chosen.append(best)
            }
        }
        return chosen.sorted().map { ($0 / 60, $0 % 60) }
    }

    func cancelDailyMenuReminder() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let pendingIds = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.dailyMenuIdentifierPrefix) }
        if !pendingIds.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: pendingIds)
        }

        let delivered = await center.deliveredNotifications()
        let deliveredIds = delivered
            .map { $0.request.identifier }
            .filter { $0.hasPrefix(Self.dailyMenuIdentifierPrefix) }
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
            "language": lang,
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
            "language": lang,
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

    // MARK: - Post-Seed Memory & Copy Composition Helpers

    private enum DailyNotificationArchetype: Int, CaseIterable {
        case unfinishedDeepDive
        case threadContinuation
        case unexpectedPairing
        case archiveEcho
        case antiAlgorithmRitual
    }

    private struct DailySlotComposition {
        let archetype: DailyNotificationArchetype
        let title: String
        let body: String
        let seedId: String?
    }

    private func upsertPostSeed(_ seed: NotificationPostSeed) {
        recentPostSeeds.removeAll {
            $0.id == seed.id || $0.title.caseInsensitiveCompare(seed.title) == .orderedSame
        }
        recentPostSeeds.insert(seed, at: 0)
        if recentPostSeeds.count > Self.maxStoredPostSeeds {
            recentPostSeeds = Array(recentPostSeeds.prefix(Self.maxStoredPostSeeds))
        }
        persistPostSeeds()
    }

    private func persistPostSeeds() {
        guard let data = try? JSONEncoder().encode(recentPostSeeds) else { return }
        defaults.set(data, forKey: Keys.recentPostSeeds)
    }

    private func hydrateSeedsIfNeeded(language: AppLanguage) async -> [NotificationPostSeed] {
        var merged = recentPostSeeds
        var didChange = false

        for entry in BookmarkStore.shared.entries {
            let entryDeepDive = !(entry.deepDiveText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let entryId = entry.id.uuidString
            if let existingIdx = merged.firstIndex(where: { $0.id == entryId }) {
                if !merged[existingIdx].isBookmarked || (entryDeepDive && !merged[existingIdx].hasDeepDive) {
                    merged[existingIdx].isBookmarked = true
                    merged[existingIdx].hasDeepDive = merged[existingIdx].hasDeepDive || entryDeepDive
                    didChange = true
                }
            } else if let cleanTitle = Self.sanitizedPostTitle(entry.title) {
                let categoryName = InterestCategory.resolveMainCategory(
                    categoryId: entry.collectionName,
                    tags: entry.tags,
                    title: cleanTitle,
                    text: entry.text
                ).localizedName(for: language)
                let topic = entry.tags.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                    ?? categoryName
                merged.append(
                    NotificationPostSeed(
                        id: entryId,
                        title: cleanTitle,
                        topic: topic,
                        hasDeepDive: entryDeepDive,
                        isBookmarked: true,
                        createdAt: entry.postCreatedAt
                    )
                )
                didChange = true
            }
        }

        if merged.count < 4 {
            let cachedPosts = await PostCacheService.shared.loadCachedPosts(limit: 10)
            for post in cachedPosts {
                let postId = post.id.uuidString
                guard !merged.contains(where: { $0.id == postId }),
                      let cleanTitle = Self.sanitizedPostTitle(post.title) else {
                    continue
                }
                let hasDeepDive = !(post.deepDiveText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                merged.append(
                    NotificationPostSeed(
                        id: postId,
                        title: cleanTitle,
                        topic: Self.resolvedTopic(for: post, cleanTitle: cleanTitle, language: language),
                        hasDeepDive: hasDeepDive,
                        isBookmarked: BookmarkStore.shared.contains(postId: post.id),
                        createdAt: post.createdAt
                    )
                )
                didChange = true
            }
        }

        var seenIds = Set<String>()
        var seenTitles = Set<String>()
        merged.sort { $0.createdAt > $1.createdAt }
        let deduped = merged.filter { seed in
            seenIds.insert(seed.id).inserted && seenTitles.insert(seed.title.lowercased()).inserted
        }
        let capped = Array(deduped.prefix(Self.maxStoredPostSeeds))
        if didChange || capped != recentPostSeeds {
            recentPostSeeds = capped
            persistPostSeeds()
        }
        return capped
    }

    private static func sanitizedPostTitle(_ raw: String, maxLength: Int = 54) -> String? {
        let collapsed = raw
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”«»「」'"))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !collapsed.isEmpty,
              collapsed.caseInsensitiveCompare("Diving deeper...") != .orderedSame,
              collapsed != "..." else {
            return nil
        }

        guard collapsed.count > maxLength else {
            return collapsed
        }

        let cutoff = collapsed.index(collapsed.startIndex, offsetBy: maxLength - 1)
        let prefix = String(collapsed[..<cutoff])
        if let lastSpace = prefix.lastIndex(of: " "),
           prefix.distance(from: prefix.startIndex, to: lastSpace) > maxLength / 2 {
            return String(prefix[..<lastSpace]).trimmingCharacters(in: .whitespaces) + "…"
        }
        return prefix.trimmingCharacters(in: .whitespaces) + "…"
    }

    private static func resolvedTopic(
        for post: Post,
        cleanTitle: String,
        language: AppLanguage
    ) -> String {
        if let tag = post.tags
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .first(where: { !$0.isEmpty }) {
            return tag
        }
        return InterestCategory.resolveMainCategory(
            categoryId: post.categoryId,
            tags: post.tags,
            title: cleanTitle,
            text: post.text
        ).localizedName(for: language)
    }

    private static func rotatedTopics(
        from interests: [String],
        seed: NotificationPostSeed?,
        shift: Int,
        l10n: L10n
    ) -> (first: String, second: String) {
        if interests.count >= 2 {
            let firstIdx = shift % interests.count
            let secondIdx = (firstIdx + 1) % interests.count
            return (interests[firstIdx], interests[secondIdx])
        }
        if let only = interests.first {
            let seedTopic = seed?.topic.trimmingCharacters(in: .whitespacesAndNewlines)
            let second = (seedTopic?.isEmpty == false && seedTopic?.caseInsensitiveCompare(only) != .orderedSame)
                ? seedTopic!
                : l10n.dailyMenuDefaultSecondTopic
            return (only, second)
        }
        let seedTopic = seed?.topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let first = (seedTopic?.isEmpty == false) ? seedTopic! : l10n.dailyMenuDefaultTopic
        let second = (first.caseInsensitiveCompare(l10n.dailyMenuDefaultSecondTopic) == .orderedSame)
            ? l10n.dailyMenuDefaultTopic
            : l10n.dailyMenuDefaultSecondTopic
        return (first, second)
    }

    private static func pickSeed(
        from seeds: [NotificationPostSeed],
        slot: Int,
        previousSeedId: String?,
        prefer: ((NotificationPostSeed) -> Bool)? = nil
    ) -> NotificationPostSeed? {
        guard !seeds.isEmpty else { return nil }
        let rotated = (0..<seeds.count).map { seeds[(slot + $0) % seeds.count] }
        if let prefer {
            if let match = rotated.first(where: { prefer($0) && $0.id != previousSeedId }) {
                return match
            }
            if let match = rotated.first(where: prefer) {
                return match
            }
        }
        return rotated.first(where: { $0.id != previousSeedId }) ?? rotated.first
    }

    func refreshScheduledRemindersForQuotaChange() async {
        guard dailyReminderEnabled,
              authorizationStatus == .authorized || authorizationStatus == .provisional else {
            return
        }
        let completedToday = !AccessManager.shared.isPro && AccessManager.shared.snapshot.platesRemaining == 0
        await scheduleDailyMenuReminder(
            interests: currentInterests(),
            language: currentLanguage(),
            menuCompletedToday: completedToday
        )
    }

    private static func effectivePlatesCount(for targetDate: Date, calendar: Calendar) -> Int? {
        if AccessManager.shared.isPro {
            return nil
        }
        if calendar.isDateInToday(targetDate) {
            let remaining = AccessManager.shared.snapshot.platesRemaining
            return remaining > 0 ? remaining : nil
        }
        let limit = AccessManager.shared.snapshot.platesLimit
        return limit > 0 ? limit : 3
    }

    private static func composeDailySlot(
        slot: Int,
        dayOfYear: Int,
        seeds: [NotificationPostSeed],
        interests: [String],
        platesCount: Int?,
        l10n: L10n,
        previousArchetype: DailyNotificationArchetype?,
        previousSeedId: String?,
        previousSignature: String?
    ) -> DailySlotComposition {
        let allArchetypes = DailyNotificationArchetype.allCases
        let offset = (slot + dayOfYear) % allArchetypes.count
        var ordered = (0..<allArchetypes.count).map { allArchetypes[(offset + $0) % allArchetypes.count] }

        // Lead with an unread Deep Dive hook on the very first day if one is waiting.
        if slot == 0, seeds.contains(where: { !$0.hasDeepDive }) {
            ordered.removeAll { $0 == .unfinishedDeepDive }
            ordered.insert(.unfinishedDeepDive, at: 0)
        }

        if let previousArchetype, ordered.count > 1 {
            ordered.removeAll { $0 == previousArchetype }
            ordered.append(previousArchetype)
        }

        for archetype in ordered {
            let composition: DailySlotComposition?
            switch archetype {
            case .unfinishedDeepDive:
                if let seed = pickSeed(from: seeds, slot: slot, previousSeedId: previousSeedId, prefer: { !$0.hasDeepDive }) {
                    composition = DailySlotComposition(
                        archetype: .unfinishedDeepDive,
                        title: l10n.dailyMenuDeepDiveTitle(title: seed.title),
                        body: l10n.dailyMenuDeepDiveBody(platesCount: platesCount),
                        seedId: seed.id
                    )
                } else {
                    composition = nil
                }

            case .threadContinuation:
                if let seed = pickSeed(from: seeds, slot: slot, previousSeedId: previousSeedId) {
                    let topics = rotatedTopics(from: interests, seed: seed, shift: slot + dayOfYear, l10n: l10n)
                    composition = DailySlotComposition(
                        archetype: .threadContinuation,
                        title: l10n.dailyMenuThreadTitle,
                        body: l10n.dailyMenuThreadBody(title: seed.title, topic: topics.first),
                        seedId: seed.id
                    )
                } else {
                    composition = nil
                }

            case .unexpectedPairing:
                let seed = pickSeed(from: seeds, slot: slot, previousSeedId: previousSeedId)
                let topics = rotatedTopics(from: interests, seed: seed, shift: slot + dayOfYear, l10n: l10n)
                let body = seed.map {
                    l10n.dailyMenuPairingWithPostBody(title: $0.title, second: topics.second, platesCount: platesCount)
                } ?? l10n.dailyMenuPairingEditorialBody
                composition = DailySlotComposition(
                    archetype: .unexpectedPairing,
                    title: l10n.dailyMenuPairingTitle(first: topics.first, second: topics.second),
                    body: body,
                    seedId: seed?.id
                )

            case .archiveEcho:
                if let seed = pickSeed(from: seeds, slot: slot, previousSeedId: previousSeedId, prefer: { $0.isBookmarked }) {
                    let topics = rotatedTopics(from: interests, seed: seed, shift: slot + dayOfYear + 1, l10n: l10n)
                    composition = DailySlotComposition(
                        archetype: .archiveEcho,
                        title: l10n.dailyMenuEchoTitle(topic: topics.first),
                        body: l10n.dailyMenuEchoBody(title: seed.title, topic: topics.first),
                        seedId: seed.id
                    )
                } else {
                    composition = nil
                }

            case .antiAlgorithmRitual:
                let seed = pickSeed(from: seeds, slot: slot, previousSeedId: previousSeedId)
                let topics = rotatedTopics(from: interests, seed: seed, shift: slot + dayOfYear, l10n: l10n)
                let body = seed.map {
                    l10n.dailyMenuRitualWithPostBody(title: $0.title, topic: topics.first)
                } ?? l10n.dailyMenuRitualEditorialBody(topic: topics.first, platesCount: platesCount)
                composition = DailySlotComposition(
                    archetype: .antiAlgorithmRitual,
                    title: l10n.dailyMenuRitualTitle(platesCount: platesCount),
                    body: body,
                    seedId: seed?.id
                )
            }

            if let composition {
                let signature = "\(composition.title)|\(composition.body)"
                if signature != previousSignature {
                    return composition
                }
            }
        }

        // Final fallback when a brand-new user has 0 posts and few interests.
        let topics = rotatedTopics(from: interests, seed: nil, shift: slot + dayOfYear, l10n: l10n)
        let fallbackInterests = interests.isEmpty ? [topics.first, topics.second] : [topics.first]
        return DailySlotComposition(
            archetype: .antiAlgorithmRitual,
            title: l10n.dailyMenuNotificationTitle,
            body: l10n.dailyMenuNotificationBody(interests: fallbackInterests),
            seedId: nil
        )
    }

    private static func composeUnseenTeaser(
        slot: Int,
        dayOfYear: Int,
        candidate: (topic: String, category: InterestCategory),
        l10n: L10n
    ) -> (title: String, body: String) {
        let categoryName = candidate.category.localizedName(for: l10n.lang)
        let cleanTitle = sanitizedPostTitle(candidate.topic) ?? candidate.topic
        switch (slot + dayOfYear) % 5 {
        case 0:
            return (
                title: l10n.dailyUnseenSpotlightTitle(category: categoryName, title: cleanTitle),
                body: l10n.dailyUnseenSpotlightBody
            )
        case 1:
            return (
                title: l10n.dailyUnseenCounterTitle,
                body: l10n.dailyUnseenCounterBody(title: cleanTitle, category: categoryName)
            )
        case 2:
            return (
                title: l10n.dailyUnseenBackstageTitle(title: cleanTitle),
                body: l10n.dailyUnseenBackstageBody(category: categoryName)
            )
        case 3:
            return (
                title: l10n.dailyUnseenDiscoveryTitle(category: categoryName),
                body: l10n.dailyUnseenDiscoveryBody(title: cleanTitle)
            )
        default:
            return (
                title: l10n.dailyUnseenRitualTitle(category: categoryName),
                body: l10n.dailyUnseenRitualBody(title: cleanTitle)
            )
        }
    }

    private enum NotificationBucket {
        case unseenHeadline   // 50% chance
        case richArchetype    // 40% chance
        case classicDailyMenu // 10% chance
    }

    private static func rollNotificationBucket() -> NotificationBucket {
        let roll = Double.random(in: 0..<1)
        if roll < 0.50 {
            return .unseenHeadline
        } else if roll < 0.90 {
            return .richArchetype
        } else {
            return .classicDailyMenu
        }
    }

    private func applyTappedNotificationUserInfo(
        route: String?,
        postId: String?,
        unseenTopic: String?,
        categoryId: String?,
        openPaywallIfOut: Bool
    ) {
        let cleanTopic = unseenTopic?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let cleanTopic, !cleanTopic.isEmpty {
            pendingTopicRequest = PendingNotificationTopicRequest(
                id: UUID(),
                topic: cleanTopic,
                categoryId: categoryId ?? ""
            )
            pendingRoute = .feed
            return
        }
        if openPaywallIfOut {
            pendingTopicRequest = PendingNotificationTopicRequest(
                id: UUID(),
                topic: nil,
                categoryId: ""
            )
            pendingRoute = .feed
            return
        }
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
            let unseenTopic = userInfo["unseenTopic"] as? String
            let categoryId = userInfo["categoryId"] as? String
            let openPaywallIfOut = (userInfo["openPaywallIfOut"] as? Bool) ?? false
            Task { @MainActor in
                NotificationManager.shared.applyTappedNotificationUserInfo(
                    route: route,
                    postId: postId,
                    unseenTopic: unseenTopic,
                    categoryId: categoryId,
                    openPaywallIfOut: openPaywallIfOut
                )
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
