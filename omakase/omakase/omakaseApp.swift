//
//  omakaseApp.swift
//  omakase
//
//  Created by Kuzey on 22.04.2026.
//

import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn

@main
struct omakaseApp: App {

    let modelContainer: ModelContainer

    init() {
        FirebaseApp.configure()
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
