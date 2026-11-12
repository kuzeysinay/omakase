//
//  CommentsView.swift
//  omakase
//

import SwiftUI

/// A sheet view that shows comments for a shared post.
struct CommentsView: View {

    let postId: String
    let authService: AuthService

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var isLoading = true
    @State private var moderationErrorMessage: String?
    @State private var showReportConfirmation = false
    @State private var commentToBlockAuthor: Comment?

    private var l10n: L10n { L10n(lang: appLanguage) }
    private let maxCharacters = 280

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if comments.isEmpty {
                    emptyState
                } else {
                    commentList
                }

                if let moderationErrorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(moderationErrorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.08))
                }

                Divider()

                composerBar
            }
            .navigationTitle(commentsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(l10n.done)
                }
            }
            .task {
                await loadComments()
            }
            .onReceive(NotificationCenter.default.publisher(for: .omakaseDidUpdateBlockedUsers)) { _ in
                let blocked = FirestoreService.shared.blockedUIDs
                withAnimation {
                    comments.removeAll { blocked.contains($0.authorId) }
                }
            }
            .alert(l10n.reportComment, isPresented: $showReportConfirmation) {
                Button(l10n.ok, role: .cancel) { }
            } message: {
                Text(l10n.reportSubmittedToast)
            }
            .alert(
                l10n.confirmBlockUserTitle,
                isPresented: Binding(
                    get: { commentToBlockAuthor != nil },
                    set: { if !$0 { commentToBlockAuthor = nil } }
                )
            ) {
                Button(l10n.cancel, role: .cancel) {
                    commentToBlockAuthor = nil
                }
                Button(l10n.blockUser, role: .destructive) {
                    if let target = commentToBlockAuthor {
                        commentToBlockAuthor = nil
                        Task { await blockCommentAuthor(target) }
                    }
                }
            } message: {
                Text(l10n.confirmBlockUserMessage)
            }
        }
    }

    private var commentsTitle: String {
        l10n.lang == .turkish
            ? "\(comments.count) Yorum"
            : "\(comments.count) Comments"
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)
            Text(l10n.lang == .turkish ? "Henüz yorum yok" : "No comments yet")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var commentList: some View {
        List {
            ForEach(comments) { comment in
                commentRow(comment)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if comment.authorId == authService.uid {
                            Button(role: .destructive) {
                                Task { await deleteComment(comment) }
                            } label: {
                                Label(l10n.remove, systemImage: "trash")
                            }
                        }
                    }
            }
        }
        .listStyle(.plain)
    }

    private func commentRow(_ comment: Comment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            commentAvatar(photoURL: comment.authorPhotoURL)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.authorName)
                        .font(.caption).bold()
                    Text(comment.createdAt.localizedFormatted(for: appLanguage))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    if comment.authorId == authService.uid {
                        Button {
                            Task { await deleteComment(comment) }
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(l10n.remove)
                    } else {
                        Menu {
                            Button {
                                Task { await reportComment(comment) }
                            } label: {
                                Label(l10n.reportComment, systemImage: "flag")
                            }

                            Button(role: .destructive) {
                                commentToBlockAuthor = comment
                            } label: {
                                Label(l10n.blockUser, systemImage: "hand.raised")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(l10n.feedMoreActionsA11y)
                    }
                }

                Text(comment.text)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OmakaseTheme.wash, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(OmakaseTheme.stroke, lineWidth: 1)
        )
        .contextMenu {
            if comment.authorId == authService.uid {
                Button(role: .destructive) {
                    Task { await deleteComment(comment) }
                } label: {
                    Label(l10n.remove, systemImage: "trash")
                }
            } else {
                Button {
                    Task { await reportComment(comment) }
                } label: {
                    Label(l10n.reportComment, systemImage: "flag")
                }

                Button(role: .destructive) {
                    commentToBlockAuthor = comment
                } label: {
                    Label(l10n.blockUser, systemImage: "hand.raised")
                }
            }
        }
    }

    @ViewBuilder
    private func commentAvatar(photoURL: String?) -> some View {
        if let urlStr = photoURL, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                default:
                    commentAvatarPlaceholder
                }
            }
        } else {
            commentAvatarPlaceholder
        }
    }

    private var commentAvatarPlaceholder: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 24))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.secondary)
    }

    private var composerBar: some View {
        HStack(spacing: 8) {
            TextField(
                l10n.lang == .turkish ? "Yorum ekle…" : "Add a comment…",
                text: $newCommentText,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .lineLimit(1...4)
            .onChange(of: newCommentText) { _, newValue in
                moderationErrorMessage = nil
                if newValue.count > maxCharacters {
                    newCommentText = String(newValue.prefix(maxCharacters))
                }
            }

            if remainingCharacters < 50 {
                Text("\(remainingCharacters)")
                    .font(.caption2)
                    .foregroundStyle(remainingCharacters < 10 ? .red : .secondary)
                    .monospacedDigit()
            }

            Button {
                Task { await sendComment() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(OmakaseTheme.ink)
            }
            .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel(l10n.lang == .turkish ? "Yorum gönder" : "Send comment")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var remainingCharacters: Int {
        maxCharacters - newCommentText.count
    }

    // MARK: - Actions

    private func loadComments() async {
        isLoading = true
        do {
            comments = try await FirestoreService.shared.fetchComments(postId: postId)
        } catch {
            // Silently fail; user sees empty state
        }
        isLoading = false
    }

    private func sendComment() async {
        let text = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty,
              let uid = authService.uid,
              let name = authService.displayName else { return }

        // Pre-post UGC moderation filter (Guideline 1.2 Rule 1)
        guard ContentModerationService.isAppropriate(text, maxLength: maxCharacters) else {
            moderationErrorMessage = l10n.moderationErrorInappropriateText
            return
        }

        moderationErrorMessage = nil
        newCommentText = ""

        do {
            try await FirestoreService.shared.addComment(
                postId: postId,
                text: text,
                authorId: uid,
                authorName: name,
                authorPhotoURL: authService.photoURL?.absoluteString
            )
            await loadComments()
        } catch {
            newCommentText = text
        }
    }

    private func deleteComment(_ comment: Comment) async {
        guard let commentId = comment.id else { return }
        do {
            try await FirestoreService.shared.deleteComment(postId: postId, commentId: commentId)
            withAnimation {
                comments.removeAll { $0.id == commentId }
            }
        } catch {
            // Silently fail
        }
    }

    private func reportComment(_ comment: Comment) async {
        guard let commentId = comment.id,
              let uid = authService.uid else { return }
        do {
            try await FirestoreService.shared.reportComment(
                postId: postId,
                commentId: commentId,
                reportedAuthorUid: comment.authorId,
                reporterUid: uid
            )
            showReportConfirmation = true
        } catch {
            // Silently fail
        }
    }

    private func blockCommentAuthor(_ comment: Comment) async {
        guard let uid = authService.uid else { return }
        do {
            try await FirestoreService.shared.blockUser(
                targetUid: comment.authorId,
                targetDisplayName: comment.authorName,
                currentUid: uid
            )
            withAnimation {
                comments.removeAll { $0.authorId == comment.authorId }
            }
        } catch {
            // Silently fail
        }
    }
}
