//
//  ContentView.swift
//  omakase
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("omakase.hasOnboarded") private var hasOnboarded: Bool = false
    @AppStorage("omakase.language") private var languageCode: String = AppLanguage.systemDefault.rawValue
    @AppStorage("omakase.appearance") private var appearanceCode: String = AppAppearance.system.rawValue

    @State private var authService = AuthService()

    private var resolvedLanguage: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .systemDefault
    }

    private var resolvedAppearance: AppAppearance {
        AppAppearance(rawValue: appearanceCode) ?? .system
    }

    @State private var showSplash = true

    var body: some View {
        ZStack {
            Group {
                if !authService.isAuthenticated {
                    // Step 1: Sign in or Sign up (Email / Google / Apple)
                    AuthView(authService: authService)
                } else if authService.needsProfileSetup {
                    // Step 1.5: Choose display name & unique @username (Apple / Google / incomplete profiles)
                    ProfileSetupView(authService: authService)
                } else if !hasOnboarded {
                    // Step 2: Onboarding introduction
                    OnboardingView(authService: authService)
                } else {
                    // Step 3: Main app with tab bar
                    MainTabView(authService: authService)
                }
            }
            .animation(.default, value: authService.isAuthenticated)
            .animation(.default, value: authService.needsProfileSetup)
            .animation(.default, value: hasOnboarded)
            .environment(\.locale, Locale(identifier: resolvedLanguage.localeIdentifier))
            .environment(\.appLanguage, resolvedLanguage)
            .preferredColorScheme(resolvedAppearance.colorScheme)
            .tint(OmakaseTheme.ink)

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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && authService.isAuthenticated {
                Task {
                    await AccessManager.shared.refreshAccessStatus()
                    let raw = UserDefaults.standard.string(forKey: "omakase.interests") ?? ""
                    let parsed = raw
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    let completedToday = !AccessManager.shared.isPro && AccessManager.shared.snapshot.platesRemaining == 0
                    await NotificationManager.shared.syncDailyReminderOnForeground(
                        interests: parsed,
                        language: resolvedLanguage,
                        menuCompletedToday: completedToday
                    )
                }
            }
        }
        .onChange(of: languageCode) { _, _ in
            Task {
                await NotificationManager.shared.updatePreferencesForLanguageChange(resolvedLanguage)
            }
        }
    }
}

#Preview {
    ContentView()
}
