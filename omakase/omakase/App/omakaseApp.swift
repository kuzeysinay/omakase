//
//  omakaseApp.swift
//  omakase
//
//  Created by Kuzey on 22.04.2026.
//

import FirebaseCore
import FirebaseMessaging
import GoogleSignIn
import SwiftData
import SwiftUI
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Assign delegate before finishing launch so cold-launch notification taps are never missed
        // (notification-delegate-handling Rule 1).
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        let lang = AppLanguage.resolved()
        NotificationManager.shared.registerNotificationCategories(language: lang)
        Messaging.messaging().delegate = NotificationManager.shared

        // Register for APNs independently of UNUserNotificationCenter authorization
        // (remote-push-registration Rule 1).
        application.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationManager.shared.handleAPNsTokenRegistered(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationManager.shared.handleAPNsRegistrationFailed(error)
    }
}

@main
struct omakaseApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    let modelContainer: ModelContainer

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        AccessManager.shared.configure()
        do {
            modelContainer = try ModelContainer(for: CachedPost.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        PostCacheService.shared.configure(container: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
