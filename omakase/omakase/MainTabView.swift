//
//  MainTabView.swift
//  omakase
//

import SwiftUI

/// Root navigation after authentication — two tabs:
/// 1. "My Feed" (personal AI-generated feed)
/// 2. "Timeline" (social feed of shared posts from followed users)
struct MainTabView: View {

    @Environment(\.appLanguage) private var appLanguage
    let authService: AuthService

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        TabView {
            FeedView(authService: authService)
                .tabItem {
                    Label(l10n.tabMyFeed, systemImage: "fork.knife")
                }

            TimelineView(authService: authService)
                .tabItem {
                    Label(l10n.tabTimeline, systemImage: "person.2.fill")
                }
        }
        .tint(OmakaseTheme.ink)
    }
}
