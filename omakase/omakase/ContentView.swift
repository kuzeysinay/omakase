//
//  ContentView.swift
//  omakase
//

import SwiftUI

struct ContentView: View {
    @AppStorage("omakase.hasOnboarded") private var hasOnboarded: Bool = false
    @AppStorage("omakase.language") private var languageCode: String = AppLanguage.english.rawValue

    @State private var authService = AuthService()

    private var resolvedLanguage: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    var body: some View {
        Group {
            if !authService.isAuthenticated {
                // Step 1: Sign in with Google
                AuthView(authService: authService)
            } else if !hasOnboarded {
                // Step 2: Onboarding (pick interests)
                OnboardingView()
            } else {
                // Step 3: Main app with tab bar
                MainTabView(authService: authService)
            }
        }
        .animation(.default, value: authService.isAuthenticated)
        .animation(.default, value: hasOnboarded)
        .environment(\.locale, Locale(identifier: resolvedLanguage.localeIdentifier))
        .environment(\.appLanguage, resolvedLanguage)
    }
}

#Preview {
    ContentView()
}
