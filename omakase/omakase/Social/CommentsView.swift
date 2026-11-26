//
//  CommentsView.swift
//  omakase
//

import SwiftUI
import UserNotifications

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
    @State private var toastMessage: String?
    @State private var loadError: OmakaseError?
    @State private var notificationManager = NotificationManager.shared
    @State private var hasSentCommentInSession = false
    @AppStorage("omakase.dismissedCommentNotifPrompt") private var dismissedNotifPrompt = false

    private var l10n: L10n { L10n(lang: appLanguage) }
    private let maxCharacters = 280

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let loadError, comments.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(.secondary)
                        Text(loadError.message(l10n: l10n))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                        Button(l10n.tryAgain) {
                            Task { await loadComments() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(OmakaseTheme.chipActiveFill)
                    }
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

                if hasSentCommentInSession,
                   !dismissedNotifPrompt,
                   notificationManager.authorizationStatus == .notDetermined {
                    HStack(spacing: 10) {
                        Image(systemName: "bell")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(OmakaseTheme.ink)
                        Text(l10n.commentNotificationPromptTitle)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 4)
                        Button(l10n.turnOnCTA) {
                            Task {
                                _ = await notificationManager.requestAuthorizationIfNeeded()
                                dismissedNotifPrompt = true
                            }
                        }
                        .font(.caption.weight(.bold))
                        .buttonStyle(.borderedProminent)
                        .tint(OmakaseTheme.chipActiveFill)
                        .controlSize(.mini)

                        Button {
                            dismissedNotifPrompt = true
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(OmakaseTheme.wash)
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
            .toast(message: $toastMessage)
        }
    }

    private var commentsTitle: String {
        l10n.commentsCountTitle(comments.count)
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)
            Text(l10n.noCommentsYet)
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
            MonogramAvatarView(name: comment.authorName, size: 28)

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

    private var composerBar: some View {
        HStack(spacing: 8) {
            TextField(
                l10n.addCommentPlaceholder,
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
            .accessibilityLabel(l10n.sendCommentA11y)
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
        loadError = nil
        do {
            comments = try await FirestoreService.shared.fetchComments(postId: postId)
        } catch {
            let mapped = OmakaseError.from(error, context: .commentLoad)
            ErrorReporter.record(error, mapped: mapped, area: "comments_load")
            loadError = mapped
            if !comments.isEmpty {
                toastMessage = mapped.message(l10n: l10n)
            }
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
            let commentId = try await FirestoreService.shared.addComment(
                postId: postId,
                text: text,
                authorId: uid,
                authorName: name,
                authorPhotoURL: nil
            )
            hasSentCommentInSession = true
            NotificationManager.shared.notifySocialEvent(
                type: "comment",
                postId: postId,
                commentId: commentId,
                actorName: name,
                commentPreview: text
            )
            await notificationManager.refreshAuthorizationStatus()
            await loadComments()
        } catch {
            newCommentText = text
            let mapped = OmakaseError.from(error, context: .commentSend)
            ErrorReporter.record(error, mapped: mapped, area: "comments_send")
            toastMessage = mapped.message(l10n: l10n)
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
            let mapped = OmakaseError.from(error, context: .commentDelete)
            ErrorReporter.record(error, mapped: mapped, area: "comments_delete")
            toastMessage = mapped.message(l10n: l10n)
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
            let mapped = OmakaseError.from(error, context: .report)
            ErrorReporter.record(error, mapped: mapped, area: "comments_report")
            toastMessage = mapped.message(l10n: l10n)
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
            toastMessage = l10n.userBlockedToast
        } catch {
            let mapped = OmakaseError.from(error, context: .block)
            ErrorReporter.record(error, mapped: mapped, area: "comments_block")
            toastMessage = mapped.message(l10n: l10n)
        }
    }
}
