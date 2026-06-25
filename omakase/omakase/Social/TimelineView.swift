//
//  TimelineView.swift
//  omakase
//

import SwiftUI

/// Social timeline tab — shows posts shared by people the current user follows.
struct TimelineView: View {

    @Environment(\.appLanguage) private var appLanguage
    let authService: AuthService

    @State private var viewModel: TimelineViewModel
    @State private var showUserSearch = false
    @State private var showProfile = false
    @State private var selectedAuthorId: String?

    private var l10n: L10n { L10n(lang: appLanguage) }

    init(authService: AuthService) {
        self.authService = authService
        _viewModel = State(initialValue: TimelineViewModel(authService: authService))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView(l10n.loadingTimeline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.posts.isEmpty {
                    emptyState
                } else {
                    postList
                }
            }
            .navigationTitle(l10n.tabTimeline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showUserSearch = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.primary.opacity(0.85))
                    }
                    .accessibilityLabel(l10n.findPeople)

                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.primary.opacity(0.85))
                    }
                    .accessibilityLabel(l10n.myProfile)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadTimeline()
            }
            .sheet(isPresented: $showUserSearch) {
                UserSearchView(authService: authService)
                    .environment(\.appLanguage, appLanguage)
            }
            .sheet(isPresented: $showProfile) {
                if let uid = authService.uid {
                    MyProfileSheet(authService: authService)
                        .environment(\.appLanguage, appLanguage)
                }
            }
            .sheet(item: $selectedAuthorId) { authorId in
                UserProfileSheet(
                    userId: authorId,
                    authService: authService
                )
                .environment(\.appLanguage, appLanguage)
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)

            Text(l10n.timelineEmptyHeadline)
                .font(.headline)

            Text(l10n.timelineEmptyDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showUserSearch = true
            } label: {
                Label(l10n.findPeople, systemImage: "person.badge.plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var postList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.followingUIDs.isEmpty {
                    discoverBanner
                }

                ForEach(viewModel.posts, id: \.id) { post in
                    TimelinePostCard(
                        post: post,
                        authService: authService,
                        onAuthorTap: {
                            selectedAuthorId = post.authorId
                        },
                        onDelete: {
                            Task {
                                if let postId = post.id {
                                    try? await FirestoreService.shared.deleteSharedPost(postId: postId)
                                    withAnimation {
                                        viewModel.removePost(id: postId)
                                    }
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var discoverBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(l10n.discoverBannerTitle)
                    .font(.subheadline.bold())
                Text(l10n.discoverBannerDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - String conformance for sheet(item:)

extension String: @retroactive Identifiable {
    public var id: String { self }
}
