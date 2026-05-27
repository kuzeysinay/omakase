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

                Divider()

                composerBar
            }
            .navigationTitle("\(comments.count) Comments")
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
                }
            }
            .task {
                await loadComments()
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)
            Text("No comments yet")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var commentList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(comments) { comment in
                    commentRow(comment)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func commentRow(_ comment: Comment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            commentAvatar(photoURL: comment.authorPhotoURL)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.authorName)
                        .font(.caption).bold()
                    Text(comment.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(comment.text)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.separator, lineWidth: 0.5)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if comment.authorId == authService.uid {
                Button(role: .destructive) {
                    Task { await deleteComment(comment) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .contextMenu {
            if comment.authorId != authService.uid {
                Button {
                    Task { await reportComment(comment) }
                } label: {
                    Label("Report", systemImage: "exclamationmark.triangle")
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
            TextField("Add a comment…", text: $newCommentText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .onChange(of: newCommentText) { _, newValue in
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
                    .foregroundStyle(.tint)
            }
            .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
            // Restore text on failure
            newCommentText = text
        }
    }

    private func deleteComment(_ comment: Comment) async {
        guard let commentId = comment.id else { return }
        do {
            try await FirestoreService.shared.deleteComment(postId: postId, commentId: commentId)
            comments.removeAll { $0.id == commentId }
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
                reporterUid: uid
            )
        } catch {
            // Silently fail
        }
    }
}
