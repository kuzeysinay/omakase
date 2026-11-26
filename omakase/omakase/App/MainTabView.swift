//
//  MainTabView.swift
//  omakase
//
//  Root navigation after authentication — three tabs:
//  1. "My Feed" (personal AI-generated feed)
//  2. "Timeline" (social feed of shared posts from followed users)
//  3. "Profile" (saved posts, membership, notifications, preferences)
//

import SwiftUI

enum AppTab: Hashable {
    case feed
    case community
    case profile
}

struct MainTabView: View {

    @Environment(\.appLanguage) private var appLanguage
    let authService: AuthService

    @State private var selectedTab: AppTab = .feed
    @State private var notificationManager = NotificationManager.shared
    @State private var deepLinkedPostId: String?

    private var l10n: L10n { L10n(lang: appLanguage) }

    init(authService: AuthService) {
        self.authService = authService
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.12)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView(authService: authService)
                .tag(AppTab.feed)
                .tabItem {
                    Label(l10n.tabMyFeed, systemImage: "fork.knife")
                        .accessibilityIdentifier("tab.feed")
                }

            TimelineView(
                authService: authService,
                deepLinkedPostId: $deepLinkedPostId
            )
            .tag(AppTab.community)
            .tabItem {
                Label(l10n.tabTimeline, systemImage: "person.2.fill")
                    .accessibilityIdentifier("tab.community")
            }

            ProfileTabView(authService: authService)
                .tag(AppTab.profile)
                .tabItem {
                    Label(l10n.tabProfile, systemImage: "person.crop.circle")
                        .accessibilityIdentifier("tab.profile")
                }
        }
        .tint(OmakaseTheme.ink)
        .onChange(of: selectedTab) { _, _ in
            HapticManager.selection()
        }
        .onAppear {
            handlePendingRoute(notificationManager.pendingRoute)
        }
        .onChange(of: notificationManager.pendingRoute) { _, route in
            handlePendingRoute(route)
        }
    }

    private func handlePendingRoute(_ route: NotificationDeepLink?) {
        guard let route else { return }
        switch route {
        case .feed:
            selectedTab = .feed
        case .community:
            selectedTab = .community
        case .sharedPost(let postId):
            selectedTab = .community
            deepLinkedPostId = postId
        }
        notificationManager.pendingRoute = nil
    }
}
