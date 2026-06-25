//
//  FirestoreService.swift
//  omakase
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Singleton that handles all Firestore read/write operations for the social layer.
@MainActor
final class FirestoreService {

    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Users

    /// Create the user profile document if it doesn't already exist.
    func ensureUserProfile(for user: User) async throws {
        let ref = db.collection("users").document(user.uid)
        let snapshot = try await ref.getDocument()

        if !snapshot.exists {
            let profile = UserProfile(
                id: user.uid,
                displayName: user.displayName ?? "Omakase User",
                email: user.email ?? "",
                photoURL: user.photoURL?.absoluteString,
                interests: [],
                createdAt: .now
            )
            try ref.setData(from: profile)
        }
    }

    /// Update the user's interests array in Firestore.
    func updateInterests(_ interests: [String], uid: String) async throws {
        try await db.collection("users").document(uid).updateData([
            "interests": interests
        ])
    }

    /// Fetch a single user profile by UID.
    func fetchUserProfile(uid: String) async throws -> UserProfile? {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        return try? snapshot.data(as: UserProfile.self)
    }

    /// Search users by name (case-insensitive prefix match).
    func searchUsers(query: String, currentUid: String) async throws -> [UserProfile] {
        let lowered = query.lowercased()
        let end = lowered + "\u{f8ff}"

        let snapshot = try await db.collection("users")
            .whereField("searchableName", isGreaterThanOrEqualTo: lowered)
            .whereField("searchableName", isLessThan: end)
            .limit(to: 20)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: UserProfile.self) }
            .filter { $0.id != currentUid }
    }

    // MARK: - Follow / Unfollow

    func follow(targetUid: String, targetDisplayName: String, currentUid: String, currentDisplayName: String) async throws {
        let batch = db.batch()

        // Add to current user's following subcollection
        let followingRef = db.collection("users").document(currentUid)
            .collection("following").document(targetUid)
        batch.setData([
            "followedAt": FieldValue.serverTimestamp(),
            "targetDisplayName": targetDisplayName
        ], forDocument: followingRef)

        // Add to target user's followers subcollection
        let followerRef = db.collection("users").document(targetUid)
            .collection("followers").document(currentUid)
        batch.setData([
            "followedAt": FieldValue.serverTimestamp(),
            "followerDisplayName": currentDisplayName
        ], forDocument: followerRef)

        try await batch.commit()
    }

    func unfollow(targetUid: String, currentUid: String) async throws {
        let batch = db.batch()

        let followingRef = db.collection("users").document(currentUid)
            .collection("following").document(targetUid)
        batch.deleteDocument(followingRef)

        let followerRef = db.collection("users").document(targetUid)
            .collection("followers").document(currentUid)
        batch.deleteDocument(followerRef)

        try await batch.commit()
    }

    /// Check if currentUser follows targetUid.
    func isFollowing(targetUid: String, currentUid: String) async throws -> Bool {
        let doc = try await db.collection("users").document(currentUid)
            .collection("following").document(targetUid)
            .getDocument()
        return doc.exists
    }

    /// Fetch UIDs of all users the current user follows.
    func fetchFollowingUIDs(currentUid: String) async throws -> [String] {
        let snapshot = try await db.collection("users").document(currentUid)
            .collection("following")
            .getDocuments()
        return snapshot.documents.map { $0.documentID }
    }

    /// Fetch count of followers for a user.
    func fetchFollowerCount(uid: String) async throws -> Int {
        let snapshot = try await db.collection("users").document(uid)
            .collection("followers")
            .getDocuments()
        return snapshot.documents.count
    }

    /// Fetch count of users a user is following.
    func fetchFollowingCount(uid: String) async throws -> Int {
        let snapshot = try await db.collection("users").document(uid)
            .collection("following")
            .getDocuments()
        return snapshot.documents.count
    }

    // MARK: - Shared Posts

    /// Share a post to the communal timeline.
    func sharePost(_ post: Post, author: User) async throws {
        let shared = SharedPost(
            authorId: author.uid,
            authorName: author.displayName ?? "Omakase User",
            authorPhotoURL: author.photoURL?.absoluteString,
            title: post.title,
            text: post.text,
            tags: post.tags,
            originalCreatedAt: post.createdAt,
            sharedAt: .now,
            deepDiveText: post.deepDiveText
        )
        _ = try db.collection("shared_posts").addDocument(from: shared)
    }

    /// Check if the current user already shared this exact post (by matching text hash).
    func hasSharedPost(text: String, authorId: String) async throws -> Bool {
        let snapshot = try await db.collection("shared_posts")
            .whereField("authorId", isEqualTo: authorId)
            .whereField("text", isEqualTo: text)
            .limit(to: 1)
            .getDocuments()
        return !snapshot.documents.isEmpty
    }

    /// Delete a shared post by ID (for when a user deletes it from the social feed or their profile).
    func deleteSharedPost(postId: String) async throws {
        try await db.collection("shared_posts").document(postId).delete()
    }

    /// Unshare (delete) a post from the communal timeline.
    func unsharePost(text: String, authorId: String) async throws {
        let snapshot = try await db.collection("shared_posts")
            .whereField("authorId", isEqualTo: authorId)
            .whereField("text", isEqualTo: text)
            .getDocuments()

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }

    /// Fetch shared posts from users the current user follows, ordered by recency.
    func fetchTimeline(followingUIDs: [String]) async throws -> [SharedPost] {
        guard !followingUIDs.isEmpty else { return [] }

        // Firestore `whereField(in:)` supports at most 30 values per query.
        // Split into batches if needed.
        var allPosts: [SharedPost] = []

        for chunk in followingUIDs.chunked(into: 30) {
            let snapshot = try await db.collection("shared_posts")
                .whereField("authorId", in: chunk)
                .limit(to: 50)
                .getDocuments()

            let posts = snapshot.documents.compactMap { try? $0.data(as: SharedPost.self) }
            allPosts.append(contentsOf: posts)
        }

        // Sort combined results by sharedAt descending.
        return allPosts.sorted { $0.sharedAt > $1.sharedAt }
    }

    /// Fetch the "Discover" timeline — all shared posts, regardless of following.
    func fetchDiscoverTimeline(limit: Int = 50) async throws -> [SharedPost] {
        let snapshot = try await db.collection("shared_posts")
            .order(by: "sharedAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: SharedPost.self) }
    }

    /// Fetch shared posts from a specific user.
    func fetchUserTimeline(uid: String, limit: Int = 50) async throws -> [SharedPost] {
        let snapshot = try await db.collection("shared_posts")
            .whereField("authorId", isEqualTo: uid)
            .limit(to: limit)
            .getDocuments()
            
        var posts = snapshot.documents.compactMap { try? $0.data(as: SharedPost.self) }
        posts.sort { $0.sharedAt > $1.sharedAt }
        return posts
    }

    // MARK: - Reactions

    func addReaction(postId: String, emoji: String, uid: String) async throws {
        let batch = db.batch()

        let reactionRef = db.collection("shared_posts").document(postId)
            .collection("reactions").document(uid)
        batch.setData([
            "emoji": emoji,
            "reactedAt": FieldValue.serverTimestamp()
        ], forDocument: reactionRef)

        let postRef = db.collection("shared_posts").document(postId)
        batch.updateData([
            "reactionCounts.\(emoji)": FieldValue.increment(Int64(1)),
            "totalReactions": FieldValue.increment(Int64(1))
        ], forDocument: postRef)

        try await batch.commit()
    }

    func removeReaction(postId: String, emoji: String, uid: String) async throws {
        let batch = db.batch()

        let reactionRef = db.collection("shared_posts").document(postId)
            .collection("reactions").document(uid)
        batch.deleteDocument(reactionRef)

        let postRef = db.collection("shared_posts").document(postId)
        batch.updateData([
            "reactionCounts.\(emoji)": FieldValue.increment(Int64(-1)),
            "totalReactions": FieldValue.increment(Int64(-1))
        ], forDocument: postRef)

        try await batch.commit()
    }

    func fetchMyReaction(postId: String, uid: String) async -> String? {
        do {
            let doc = try await db.collection("shared_posts").document(postId)
                .collection("reactions").document(uid).getDocument()
            return doc.data()?["emoji"] as? String
        } catch {
            return nil
        }
    }

    // MARK: - Comments

    func addComment(postId: String, text: String, authorId: String, authorName: String, authorPhotoURL: String?) async throws {
        let batch = db.batch()

        let commentRef = db.collection("shared_posts").document(postId)
            .collection("comments").document()
        batch.setData([
            "authorId": authorId,
            "authorName": authorName,
            "authorPhotoURL": authorPhotoURL as Any,
            "text": String(text.prefix(280)),
            "createdAt": FieldValue.serverTimestamp(),
        ], forDocument: commentRef)

        let postRef = db.collection("shared_posts").document(postId)
        batch.updateData([
            "commentCount": FieldValue.increment(Int64(1))
        ], forDocument: postRef)

        try await batch.commit()
    }

    func fetchComments(postId: String, limit: Int = 50) async throws -> [Comment] {
        let snap = try await db.collection("shared_posts").document(postId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .limit(to: limit)
            .getDocuments()
        return snap.documents.compactMap { try? $0.data(as: Comment.self) }
    }

    func deleteComment(postId: String, commentId: String) async throws {
        let batch = db.batch()

        let commentRef = db.collection("shared_posts").document(postId)
            .collection("comments").document(commentId)
        batch.deleteDocument(commentRef)

        let postRef = db.collection("shared_posts").document(postId)
        batch.updateData([
            "commentCount": FieldValue.increment(Int64(-1))
        ], forDocument: postRef)

        try await batch.commit()
    }

    func reportComment(postId: String, commentId: String, reporterUid: String) async throws {
        try await db.collection("shared_posts").document(postId)
            .collection("comments").document(commentId)
            .updateData([
                "reportedBy": FieldValue.arrayUnion([reporterUid])
            ])
    }
}

// MARK: - Array chunking helper

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
