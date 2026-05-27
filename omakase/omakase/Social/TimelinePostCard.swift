//
//  TimelinePostCard.swift
//  omakase
//

import SwiftUI

/// A card showing a shared post in the social timeline, with author info.
struct TimelinePostCard: View {

    let post: SharedPost
    let authService: AuthService
    var onAuthorTap: () -> Void

    @Environment(\.appLanguage) private var appLanguage
    private var l10n: L10n { L10n(lang: appLanguage) }

    @State private var myReaction: String?
    @State private var localReactionCounts: [String: Int] = [:]
    @State private var showComments = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author header
            Button(action: onAuthorTap) {
                HStack(spacing: 10) {
                    authorAvatar
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.authorName)
                            .font(.subheadline).bold()
                            .foregroundStyle(.primary)
                        Text(post.sharedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right.circle")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            // Post title
            if !post.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(post.title)
                    .font(.headline)
                    .lineLimit(2)
            }

            // Post body
            Text(post.text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            // Tags
            if !post.tags.isEmpty {
                tagChips
            }

            // Reaction bar
            reactionBar

            // Comment button
            commentButton
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.separator, lineWidth: 0.5)
        )
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
    }

    // MARK: - Subviews

    @ViewBuilder
    private var authorAvatar: some View {
        if let urlStr = post.authorPhotoURL, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
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
            .font(.system(size: 28))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.secondary)
    }

    private var tagChips: some View {
        FlowLayout(spacing: 6) {
            ForEach(post.tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reactionBar: some View {
        HStack(spacing: 8) {
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
                            ? Color.accentColor.opacity(0.2)
                            : Color.secondary.opacity(0.08),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule().stroke(
                            isSelected ? Color.accentColor : .clear,
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    private var commentButton: some View {
        Button {
            showComments = true
        } label: {
            HStack(spacing: 4) {
                Text("💬")
                    .font(.callout)
                if let count = post.commentCount, count > 0 {
                    Text("\(count)")
                        .font(.caption2).bold()
                        .monospacedDigit()
                }
            }
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reaction Logic

    private func toggleReaction(_ emoji: String) async {
        guard let uid = authService.uid,
              let postId = post.id else { return }

        do {
            if let current = myReaction {
                // Remove old reaction
                localReactionCounts[current, default: 0] -= 1
                if localReactionCounts[current, default: 0] <= 0 {
                    localReactionCounts.removeValue(forKey: current)
                }
                try await FirestoreService.shared.removeReaction(postId: postId, emoji: current, uid: uid)

                if current == emoji {
                    // Tapped the same emoji — just remove
                    myReaction = nil
                    return
                }
            }

            // Add new reaction
            localReactionCounts[emoji, default: 0] += 1
            myReaction = emoji
            try await FirestoreService.shared.addReaction(postId: postId, emoji: emoji, uid: uid)
        } catch {
            // Revert optimistic update on failure
            myReaction = await FirestoreService.shared.fetchMyReaction(postId: postId, uid: uid)
            localReactionCounts = post.reactionCounts ?? [:]
        }
    }
}

/// Simple flow layout that wraps chips onto new rows.
/// (Duplicated from FeedView to keep the Social module self-contained;
/// in a production app this would be in a shared package.)
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
