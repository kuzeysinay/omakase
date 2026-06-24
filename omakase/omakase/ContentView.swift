//
//  ContentView.swift
//  omakase
//

import SwiftUI

struct ContentView: View {
    @AppStorage("omakase.hasOnboarded") private var hasOnboarded: Bool = false
    @AppStorage("omakase.language") private var languageCode: String = AppLanguage.english.rawValue
    @AppStorage("omakase.appearance") private var appearanceCode: String = AppAppearance.system.rawValue

    @State private var authService = AuthService()

    private var resolvedLanguage: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    private var resolvedAppearance: AppAppearance {
        AppAppearance(rawValue: appearanceCode) ?? .system
    }

    @State private var showSplash = true

    var body: some View {
        ZStack {
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
            .preferredColorScheme(resolvedAppearance.colorScheme)

            if showSplash {
                ZStack {
                    Color(UIColor.systemBackground)
                        .ignoresSafeArea()
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
