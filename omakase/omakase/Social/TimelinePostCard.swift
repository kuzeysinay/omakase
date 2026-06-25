//
//  TimelinePostCard.swift
//  omakase
//

import SwiftUI

/// A card showing a shared post in the social timeline.
/// Visual style intentionally mirrors the AI feed's ReelsPostCard —
/// same typography, same action-bar layout — extended with author info,
/// reactions, comments, and optional deep dive sheet.
struct TimelinePostCard: View {

    let post: SharedPost
    let authService: AuthService
    var onAuthorTap: () -> Void
    var onDelete: (() -> Void)? = nil

    @Environment(\.appLanguage) private var appLanguage
    private var l10n: L10n { L10n(lang: appLanguage) }

    @State private var myReaction: String?
    @State private var localReactionCounts: [String: Int] = [:]
    @State private var showComments = false
    @State private var showDeepDive = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // MARK: Author header — mirrors postHeader in ReelsPostCard
            authorHeader

            // MARK: Title
            if !post.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(post.title)
                    .font(.headline)
                    .lineLimit(3)
            }

            // MARK: Body
            Text(post.text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            // MARK: Tags
            if !post.tags.isEmpty {
                tagChips
            }

            // MARK: Action bar
            actionBar

        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            localReactionCounts = post.reactionCounts ?? [:]
        }
        .task {
            guard let uid = authService.uid,
                  let postId = post.id else { return }
            myReaction = await FirestoreService.shared.fetchMyReaction(postId: postId, uid: uid)
        }
        .sheet(isPresented: $showComments) {
            CommentsView(postId: post.id ?? "", authService: authService)
                .environment(\.appLanguage, appLanguage)
        }
        .sheet(isPresented: $showDeepDive) {
            deepDiveSheet
                .environment(\.appLanguage, appLanguage)
        }
    }

    // MARK: - Author header

    private var authorHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            Button(action: onAuthorTap) {
                HStack(spacing: 10) {
                    authorAvatar
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.authorName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(post.sharedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if post.authorId == authService.uid {
                Menu {
                    Button(role: .destructive) {
                        onDelete?()
                    } label: {
                        Label(
                            l10n.lang == .turkish ? "Gönderiyi Sil" : "Delete Post",
                            systemImage: "trash"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }
                .tint(.primary)
            } else {
                Image(systemName: "arrow.up.right.circle")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private var authorAvatar: some View {
        if let urlStr = post.authorPhotoURL, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                default:
                    avatarPlaceholder
                }
            }
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 32))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.secondary)
    }

    // MARK: - Tags

    private var tagChips: some View {
        FlowLayout(spacing: 6) {
            ForEach(post.tags, id: \.self) { tag in
                Text(tag.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.08), in: Capsule())
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action bar

    private var actionBar: some View {
        HStack(spacing: 0) {

            // Deep Dive button — only visible if the shared post has a deep dive
            if let deepDive = post.deepDiveText, !deepDive.isEmpty {
                Button {
                    showDeepDive = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "fish.fill")
                            .font(.title2)
                        Text(l10n.lang == .turkish ? "İnceleme" : "Deep Dive")
                            .font(.caption2)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .frame(width: 56)
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                .accessibilityLabel(l10n.lang == .turkish ? "Derinlemesine incelemeyi oku" : "Read deep dive")
            }

            // Reactions
            reactionBar

            Spacer()

            // Comments
            commentButton
        }
        .padding(.top, 4)
    }

    // MARK: - Reactions

    private var reactionBar: some View {
        HStack(spacing: 6) {
            ForEach(ReactionEmoji.allCases, id: \.rawValue) { reaction in
                let emoji = reaction.rawValue
                let count = localReactionCounts[emoji] ?? 0
                let isSelected = myReaction == emoji

                Button {
                    Task { await toggleReaction(emoji) }
                } label: {
                    HStack(spacing: 4) {
                        Text(emoji)
                            .font(.callout)
                        if count > 0 {
                            Text("\(count)")
                                .font(.caption2).bold()
                                .monospacedDigit()
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        isSelected
                            ? Color.primary.opacity(0.12)
                            : Color.secondary.opacity(0.08),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule().stroke(
                            isSelected ? Color.primary.opacity(0.4) : .clear,
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Comments

    private var commentButton: some View {
        Button {
            showComments = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bubble.right")
                    .font(.body)
                if let count = post.commentCount, count > 0 {
                    Text("\(count)")
                        .font(.caption2).bold()
                        .monospacedDigit()
                }
            }
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(l10n.lang == .turkish ? "Yorumlar" : "Comments")
    }

    // MARK: - Deep Dive Sheet
    //
    // Deep dive text is complete (no streaming here),
    // so no skeleton or LIVE badge is needed.

    private var deepDiveSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let deepDive = post.deepDiveText, !deepDive.isEmpty {
                        let clean = String(deepDive.drop(while: { $0.isWhitespace || $0.isNewline }))
                        Text(clean)
                            .font(.body)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    }
                    Spacer(minLength: 48)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(l10n.lang == .turkish ? "Derinlemesine İnceleme" : "Deep Dive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "fish.fill")
                        .foregroundStyle(.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDeepDive = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(l10n.lang == .turkish ? "Kapat" : "Close")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Reaction logic

    private func toggleReaction(_ emoji: String) async {
        guard let uid = authService.uid,
              let postId = post.id else { return }

        do {
            if let current = myReaction {
                localReactionCounts[current, default: 0] -= 1
                if localReactionCounts[current, default: 0] <= 0 {
                    localReactionCounts.removeValue(forKey: current)
                }
                try await FirestoreService.shared.removeReaction(postId: postId, emoji: current, uid: uid)

                if current == emoji {
                    myReaction = nil
                    return
                }
            }

            localReactionCounts[emoji, default: 0] += 1
            myReaction = emoji
            try await FirestoreService.shared.addReaction(postId: postId, emoji: emoji, uid: uid)
        } catch {
            myReaction = await FirestoreService.shared.fetchMyReaction(postId: postId, uid: uid)
            localReactionCounts = post.reactionCounts ?? [:]
        }
    }
}

// MARK: - Flow layout (self-contained copy)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layoutRows(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layoutRows(
            proposal: ProposedViewSize(width: bounds.width, height: bounds.height),
            subviews: subviews
        )
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private struct LayoutResult {
        var size: CGSize
        var positions: [CGPoint]
    }

    private func layoutRows(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return LayoutResult(
            size: CGSize(width: totalWidth, height: currentY + rowHeight),
            positions: positions
        )
    }
}
