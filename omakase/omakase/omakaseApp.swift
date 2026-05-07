//
//  omakaseApp.swift
//  omakase
//
//  Created by Kuzey on 22.04.2026.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct omakaseApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
