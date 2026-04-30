//
//  ContentView.swift
//  omakase
//

import SwiftUI

struct ContentView: View {
    @AppStorage("omakase.hasOnboarded") private var hasOnboarded: Bool = false
    @AppStorage("omakase.language") private var languageCode: String = AppLanguage.english.rawValue

    private var resolvedLanguage: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    var body: some View {
        Group {
            if hasOnboarded {
                FeedView()
            } else {
                OnboardingView()
            }
        }
        .animation(.default, value: hasOnboarded)
        .environment(\.locale, Locale(identifier: resolvedLanguage.localeIdentifier))
        .environment(\.appLanguage, resolvedLanguage)
    }
}

#Preview {
    ContentView()
}
