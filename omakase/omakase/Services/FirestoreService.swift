//
//  FirestoreService.swift
//  omakase
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

extension Notification.Name {
    static let omakaseDidUpdateBlockedUsers = Notification.Name("omakase.didUpdateBlockedUsers")
}

enum ProfileUpdateError: Error, Equatable {
    case invalidDisplayName
    case invalidUsername
    case usernameTaken
    case cooldownActive(daysRemaining: Int)
}

/// Singleton that handles all Firestore read/write operations for the social layer.
@MainActor
final class FirestoreService {

    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    /// Cached set of blocked user UIDs for the active signed-in user.
    private(set) var blockedUIDs: Set<String> = []

    private init() {}

    // MARK: - Users

    /// Create the user profile document if it doesn't already exist.
    func ensureUserProfile(
        for user: User,
        customDisplayName: String? = nil,
        customUsername: String? = nil
    ) async throws {
        let ref = db.collection("users").document(user.uid)
        let snapshot = try await ref.getDocument()

        let resolvedName: String = {
            if let custom = customDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
                return custom
            }
            if let existing = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines), !existing.isEmpty {
                return existing
            }
            if let email = user.email, let prefix = email.split(separator: "@").first, !prefix.isEmpty {
                return String(prefix)
            }
            return "Omakase User"
        }()

        let resolvedUsername: String? = {
            if let custom = customUsername {
                let clean = UserProfile.sanitizeUsername(custom)
                if clean.count >= 3 { return clean }
            }
            return nil
        }()

        if !snapshot.exists {
            let hasExplicitHandle = (resolvedUsername != nil)
            // Do not store private `email` in the publicly readable `users/{uid}` document (S-04 PII protection).
            let profile = UserProfile(
                id: user.uid,
                displayName: resolvedName,
                username: resolvedUsername,
                email: "",
                photoURL: nil,
                interests: [],
                createdAt: .now,
                usernameUpdatedAt: hasExplicitHandle ? .now : nil,
                profileSetupCompleted: hasExplicitHandle
            )
            if let handle = resolvedUsername {
                let handleRef = db.collection("usernames").document(handle)
                try await handleRef.setData([
                    "uid": user.uid,
                    "createdAt": FieldValue.serverTimestamp()
                ])
            }
            try ref.setData(from: profile)
        } else {
            var updates: [String: Any] = [
                // Scrub legacy PII and third-party avatar URLs from public user documents.
                "email": FieldValue.delete(),
                "photoURL": FieldValue.delete()
            ]
            if let custom = customDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
                updates["displayName"] = custom
                updates["searchableName"] = custom.lowercased()
            }
            if let clean = resolvedUsername {
                let handleRef = db.collection("usernames").document(clean)
                try? await handleRef.setData([
                    "uid": user.uid,
                    "createdAt": FieldValue.serverTimestamp()
                ])
                updates["username"] = clean
                updates["searchableUsername"] = clean.lowercased()
                updates["usernameUpdatedAt"] = FieldValue.serverTimestamp()
                updates["profileSetupCompleted"] = true
            }
            try await ref.updateData(updates)
        }

        _ = try? await fetchBlockedUIDs(currentUid: user.uid)
    }

    /// Check if a `@username` is available across both `usernames/{handle}` and `users`.
    func isUsernameAvailable(_ rawUsername: String, excludingUid: String? = nil) async throws -> Bool {
        let clean = UserProfile.sanitizeUsername(rawUsername)
        guard clean.count >= 3 else { return false }

        // 1. Check atomic reservation doc
        let handleDoc = try? await db.collection("usernames").document(clean).getDocument()
        if let handleDoc, handleDoc.exists {
            let ownerUid = handleDoc.data()?["uid"] as? String
            if ownerUid != excludingUid {
                return false
            }
        }

        // 2. Also check legacy `users` collection for handles created before `usernames/` existed
        let snapshot = try await db.collection("users")
            .whereField("searchableUsername", isEqualTo: clean.lowercased())
            .limit(to: 2)
            .getDocuments()

        for doc in snapshot.documents {
            if doc.documentID != excludingUid {
                return false
            }
        }
        return true
    }

    /// Updates display name and/or atomically claims a unique `@username` with 14-day cooldown enforcement.
    @discardableResult
    func updateUserProfile(
        uid: String,
        displayName: String,
        newUsername: String,
        markSetupCompleted: Bool = false
    ) async throws -> UserProfile {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, trimmedName.count <= 60, ContentModerationService.isAppropriate(trimmedName) else {
            throw ProfileUpdateError.invalidDisplayName
        }

        let cleanUsername = UserProfile.sanitizeUsername(newUsername)
        guard cleanUsername.count >= 3, cleanUsername.count <= 20, ContentModerationService.isAppropriate(cleanUsername) else {
            throw ProfileUpdateError.invalidUsername
        }

        let userRef = db.collection("users").document(uid)
        let currentProfile = try await fetchUserProfile(uid: uid)
        let oldUsername = currentProfile?.username.map { UserProfile.sanitizeUsername($0) }
        let usernameChanged = (oldUsername != cleanUsername)

        if usernameChanged {
            // Enforce 14-day cooldown only if user already had a username set previously.
            if let existing = currentProfile,
               let existingHandle = existing.username, !existingHandle.isEmpty,
               !existing.canChangeUsernameNow {
                throw ProfileUpdateError.cooldownActive(daysRemaining: existing.daysUntilNextUsernameChange)
            }

            let available = try await isUsernameAvailable(cleanUsername, excludingUid: uid)
            guard available else {
                throw ProfileUpdateError.usernameTaken
            }

            // Atomically claim the new handle in `usernames/{cleanUsername}`.
            let newHandleRef = db.collection("usernames").document(cleanUsername)
            do {
                try await newHandleRef.setData([
                    "uid": uid,
                    "createdAt": FieldValue.serverTimestamp()
                ])
            } catch {
                // Only map to `.usernameTaken` if the handle is actually owned by another user;
                // otherwise propagate the real Firestore/network error.
                if let existingDoc = try? await newHandleRef.getDocument(),
                   existingDoc.exists,
                   (existingDoc.data()?["uid"] as? String) != uid {
                    throw ProfileUpdateError.usernameTaken
                }
                throw error
            }
        } else if let existingHandle = oldUsername, !existingHandle.isEmpty {
            // Backfill `usernames/{handle}` reservation for legacy users keeping their handle.
            let handleRef = db.collection("usernames").document(existingHandle)
            let snap = try? await handleRef.getDocument()
            if snap?.exists != true {
                try? await handleRef.setData([
                    "uid": uid,
                    "createdAt": FieldValue.serverTimestamp()
                ])
            }
        }

        var updates: [String: Any] = [
            "displayName": trimmedName,
            "searchableName": trimmedName.lowercased()
        ]
        if usernameChanged {
            updates["username"] = cleanUsername
            updates["searchableUsername"] = cleanUsername.lowercased()
            updates["usernameUpdatedAt"] = FieldValue.serverTimestamp()
        }
        if markSetupCompleted {
            updates["profileSetupCompleted"] = true
        }

        try await userRef.updateData(updates)

        // Release the old username reservation after the user doc update succeeds.
        if usernameChanged, let old = oldUsername, !old.isEmpty, old != cleanUsername {
            try? await db.collection("usernames").document(old).delete()
        }

        return (try? await fetchUserProfile(uid: uid)) ?? UserProfile(
            id: uid,
            displayName: trimmedName,
            username: cleanUsername,
            email: "",
            interests: currentProfile?.interests ?? [],
            createdAt: currentProfile?.createdAt ?? .now,
            usernameUpdatedAt: usernameChanged ? .now : currentProfile?.usernameUpdatedAt,
            profileSetupCompleted: markSetupCompleted ? true : currentProfile?.profileSetupCompleted
        )
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

    /// Search users by display name or @username (case-insensitive prefix match), excluding blocked users.
    func searchUsers(query: String, currentUid: String) async throws -> [UserProfile] {
        let stripped = query.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "@"))
            .lowercased()
        guard !stripped.isEmpty else { return [] }
        let end = stripped + "\u{f8ff}"

        if blockedUIDs.isEmpty {
            _ = try? await fetchBlockedUIDs(currentUid: currentUid)
        }

        async let nameQuery = db.collection("users")
            .whereField("searchableName", isGreaterThanOrEqualTo: stripped)
            .whereField("searchableName", isLessThan: end)
            .limit(to: 20)
            .getDocuments()

        async let handleQuery = db.collection("users")
            .whereField("searchableUsername", isGreaterThanOrEqualTo: stripped)
            .whereField("searchableUsername", isLessThan: end)
            .limit(to: 20)
            .getDocuments()

        let (nameSnap, handleSnap) = try await (nameQuery, handleQuery)
        var seen = Set<String>()
        var combined: [UserProfile] = []

        for doc in handleSnap.documents + nameSnap.documents {
            guard doc.documentID != currentUid,
                  !blockedUIDs.contains(doc.documentID),
                  !seen.contains(doc.documentID) else { continue }
            if let user = try? doc.data(as: UserProfile.self) {
                seen.insert(doc.documentID)
                combined.append(user)
            }
        }
        return combined
    }

    // MARK: - Block / Unblock Users (Guideline 1.2)

    func fetchBlockedUIDs(currentUid: String) async throws -> Set<String> {
        let snapshot = try await db.collection("users").document(currentUid)
            .collection("blocked_users")
            .getDocuments()
        let uids = Set(snapshot.documents.map { $0.documentID })
        self.blockedUIDs = uids
        return uids
    }

    func isUserBlocked(targetUid: String) -> Bool {
        blockedUIDs.contains(targetUid)
    }

    /// Block an abusive user: records the block in `users/{currentUid}/blocked_users/{targetUid}`,
    /// severs follow relationships in both directions so the blocked user can no longer reach the blocker,
    /// and updates the in-memory filter set immediately.
    func blockUser(targetUid: String, targetDisplayName: String, currentUid: String) async throws {
        guard targetUid != currentUid else { return }

        blockedUIDs.insert(targetUid)
        NotificationCenter.default.post(name: .omakaseDidUpdateBlockedUsers, object: targetUid)

        let batch = db.batch()

        let blockRef = db.collection("users").document(currentUid)
            .collection("blocked_users").document(targetUid)
        batch.setData([
            "blockedUid": targetUid,
            "displayName": String(targetDisplayName.prefix(100)),
            "blockedAt": FieldValue.serverTimestamp()
        ], forDocument: blockRef)

        // Sever following/follower links in both directions
        let myFollowingRef = db.collection("users").document(currentUid)
            .collection("following").document(targetUid)
        batch.deleteDocument(myFollowingRef)

        let theirFollowersRef = db.collection("users").document(targetUid)
            .collection("followers").document(currentUid)
        batch.deleteDocument(theirFollowersRef)

        let theirFollowingRef = db.collection("users").document(targetUid)
            .collection("following").document(currentUid)
        batch.deleteDocument(theirFollowingRef)

        let myFollowersRef = db.collection("users").document(currentUid)
            .collection("followers").document(targetUid)
        batch.deleteDocument(myFollowersRef)

        try await batch.commit()
    }

    func unblockUser(targetUid: String, currentUid: String) async throws {
        blockedUIDs.remove(targetUid)
        NotificationCenter.default.post(name: .omakaseDidUpdateBlockedUsers, object: targetUid)

        try await db.collection("users").document(currentUid)
            .collection("blocked_users").document(targetUid)
            .delete()
    }

    func clearBlockedCache() {
        blockedUIDs.removeAll()
    }

    // MARK: - Follow / Unfollow

    func follow(targetUid: String, targetDisplayName: String, currentUid: String, currentDisplayName: String) async throws {
        let batch = db.batch()

        // Add to current user's following subcollection
        let followingRef = db.collection("users").document(currentUid)
            .collection("following").document(targetUid)
        batch.setData([
            "followedAt": FieldValue.serverTimestamp(),
            "targetDisplayName": String(targetDisplayName.prefix(100))
        ], forDocument: followingRef)

        // Add to target user's followers subcollection
        let followerRef = db.collection("users").document(targetUid)
            .collection("followers").document(currentUid)
        batch.setData([
            "followedAt": FieldValue.serverTimestamp(),
            "followerDisplayName": String(currentDisplayName.prefix(100))
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

    /// Fetch UIDs of all users the current user follows (excluding blocked users).
    func fetchFollowingUIDs(currentUid: String) async throws -> [String] {
        _ = try? await fetchBlockedUIDs(currentUid: currentUid)
        let snapshot = try await db.collection("users").document(currentUid)
            .collection("following")
            .getDocuments()
        return snapshot.documents
            .map { $0.documentID }
            .filter { !blockedUIDs.contains($0) }
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
        let userProfile = try? await fetchUserProfile(uid: author.uid)
        let resolvedName = userProfile?.displayName ?? author.displayName ?? "Omakase User"
        let resolvedUsername = userProfile?.username
        let shared = SharedPost(
            authorId: author.uid,
            authorName: resolvedName,
            authorUsername: resolvedUsername,
            authorPhotoURL: nil,
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

    /// Fetch shared posts from users the current user follows, ordered by recency, excluding blocked users.
    func fetchTimeline(followingUIDs: [String]) async throws -> [SharedPost] {
        let cleanUIDs = followingUIDs.filter { !blockedUIDs.contains($0) }
        guard !cleanUIDs.isEmpty else { return [] }

        var allPosts: [SharedPost] = []

        for chunk in cleanUIDs.chunked(into: 30) {
            let snapshot = try await db.collection("shared_posts")
                .whereField("authorId", in: chunk)
                .limit(to: 50)
                .getDocuments()

            let posts = snapshot.documents
                .compactMap { try? $0.data(as: SharedPost.self) }
                .filter { !blockedUIDs.contains($0.authorId) }
            allPosts.append(contentsOf: posts)
        }

        return allPosts.sorted { $0.sharedAt > $1.sharedAt }
    }

    /// Fetch the "Discover" timeline — all shared posts, excluding blocked users.
    func fetchDiscoverTimeline(limit: Int = 50) async throws -> [SharedPost] {
        let snapshot = try await db.collection("shared_posts")
            .order(by: "sharedAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: SharedPost.self) }
            .filter { !blockedUIDs.contains($0.authorId) }
    }

    /// Fetch shared posts from a specific user.
    func fetchUserTimeline(uid: String, limit: Int = 50) async throws -> [SharedPost] {
        guard !blockedUIDs.contains(uid) else { return [] }
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

    @discardableResult
    func addComment(postId: String, text: String, authorId: String, authorName: String, authorPhotoURL: String?) async throws -> String {
        let batch = db.batch()

        let commentRef = db.collection("shared_posts").document(postId)
            .collection("comments").document()
        var commentData: [String: Any] = [
            "authorId": authorId,
            "authorName": String(authorName.prefix(100)),
            "text": String(text.prefix(280)),
            "createdAt": FieldValue.serverTimestamp(),
        ]
        if let authorPhotoURL {
            commentData["authorPhotoURL"] = authorPhotoURL
        }
        batch.setData(commentData, forDocument: commentRef)

        let postRef = db.collection("shared_posts").document(postId)
        batch.updateData([
            "commentCount": FieldValue.increment(Int64(1))
        ], forDocument: postRef)

        try await batch.commit()
        return commentRef.documentID
    }

    func fetchComments(postId: String, limit: Int = 50) async throws -> [Comment] {
        let snap = try await db.collection("shared_posts").document(postId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .limit(to: limit)
            .getDocuments()
        return snap.documents
            .compactMap { try? $0.data(as: Comment.self) }
            .filter { !blockedUIDs.contains($0.authorId) }
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

    // MARK: - Moderation Reports (Guideline 1.2)

    func reportComment(postId: String, commentId: String, reportedAuthorUid: String? = nil, reporterUid: String) async throws {
        let batch = db.batch()

        let commentRef = db.collection("shared_posts").document(postId)
            .collection("comments").document(commentId)
        batch.updateData([
            "reportedBy": FieldValue.arrayUnion([reporterUid])
        ], forDocument: commentRef)

        let reportRef = db.collection("moderation_reports").document()
        var reportData: [String: Any] = [
            "reporterUid": reporterUid,
            "targetType": "comment",
            "targetId": commentId,
            "postId": postId,
            "commentId": commentId,
            "reason": "Objectionable comment reported by user",
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let reportedAuthorUid {
            reportData["reportedAuthorUid"] = reportedAuthorUid
        }
        batch.setData(reportData, forDocument: reportRef)

        try await batch.commit()
    }

    func reportPost(postId: String, reportedAuthorUid: String, reporterUid: String, reason: String = "Objectionable post reported by user") async throws {
        let batch = db.batch()

        let postRef = db.collection("shared_posts").document(postId)
        batch.updateData([
            "reportedBy": FieldValue.arrayUnion([reporterUid])
        ], forDocument: postRef)

        let reportRef = db.collection("moderation_reports").document()
        batch.setData([
            "reporterUid": reporterUid,
            "targetType": "post",
            "targetId": postId,
            "postId": postId,
            "reportedAuthorUid": reportedAuthorUid,
            "reason": String(reason.prefix(1000)),
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: reportRef)

        try await batch.commit()
    }

    func reportUser(reportedUid: String, reporterUid: String, reason: String = "Abusive user profile reported by user") async throws {
        let reportRef = db.collection("moderation_reports").document()
        try await reportRef.setData([
            "reporterUid": reporterUid,
            "targetType": "user",
            "targetId": reportedUid,
            "reportedAuthorUid": reportedUid,
            "reason": String(reason.prefix(1000)),
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    func reportAIPost(postId: String, reporterUid: String, reason: String, postSnippet: String) async throws {
        let reportRef = db.collection("moderation_reports").document()
        let combinedReason = postSnippet.isEmpty ? reason : "\(reason) | \(postSnippet)"
        try await reportRef.setData([
            "reporterUid": reporterUid,
            "targetType": "ai_post",
            "targetId": String(postId.prefix(256)),
            "postId": String(postId.prefix(256)),
            "reason": String(combinedReason.prefix(1000)),
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Account & Data Deletion (Guideline 5.1.1(v))

    /// Permanently removes the user's Firestore data: shared posts, social graph edges, blocked users list, and profile document.
    func deleteAllUserData(uid: String) async throws {
        // 0. Release reserved `@username` handle if present
        if let profile = try? await fetchUserProfile(uid: uid),
           let handle = profile.username, !handle.isEmpty {
            let clean = UserProfile.sanitizeUsername(handle)
            if !clean.isEmpty {
                try? await db.collection("usernames").document(clean).delete()
            }
        }

        // 1. Delete all shared posts authored by this user
        let sharedPostsSnap = try? await db.collection("shared_posts")
            .whereField("authorId", isEqualTo: uid)
            .getDocuments()
        if let docs = sharedPostsSnap?.documents, !docs.isEmpty {
            for chunk in docs.chunked(into: 400) {
                let batch = db.batch()
                for doc in chunk {
                    batch.deleteDocument(doc.reference)
                }
                try? await batch.commit()
            }
        }

        // 2. Clean up following subcollection and reciprocal followers entries
        let followingSnap = try? await db.collection("users").document(uid)
            .collection("following")
            .getDocuments()
        if let docs = followingSnap?.documents, !docs.isEmpty {
            let batch = db.batch()
            for doc in docs {
                let targetUid = doc.documentID
                batch.deleteDocument(doc.reference)
                let reciprocalRef = db.collection("users").document(targetUid)
                    .collection("followers").document(uid)
                batch.deleteDocument(reciprocalRef)
            }
            try? await batch.commit()
        }

        // 3. Clean up followers subcollection and reciprocal following entries
        let followersSnap = try? await db.collection("users").document(uid)
            .collection("followers")
            .getDocuments()
        if let docs = followersSnap?.documents, !docs.isEmpty {
            let batch = db.batch()
            for doc in docs {
                let followerUid = doc.documentID
                batch.deleteDocument(doc.reference)
                let reciprocalRef = db.collection("users").document(followerUid)
                    .collection("following").document(uid)
                batch.deleteDocument(reciprocalRef)
            }
            try? await batch.commit()
        }

        // 4. Clean up blocked_users subcollection
        let blockedSnap = try? await db.collection("users").document(uid)
            .collection("blocked_users")
            .getDocuments()
        if let docs = blockedSnap?.documents, !docs.isEmpty {
            let batch = db.batch()
            for doc in docs {
                batch.deleteDocument(doc.reference)
            }
            try? await batch.commit()
        }

        // 5. Clean up registered devices and notification preferences
        let devicesSnap = try? await db.collection("users").document(uid)
            .collection("devices")
            .getDocuments()
        if let docs = devicesSnap?.documents, !docs.isEmpty {
            let batch = db.batch()
            for doc in docs {
                batch.deleteDocument(doc.reference)
            }
            try? await batch.commit()
        }

        let prefsSnap = try? await db.collection("users").document(uid)
            .collection("notification_prefs")
            .getDocuments()
        if let docs = prefsSnap?.documents, !docs.isEmpty {
            let batch = db.batch()
            for doc in docs {
                batch.deleteDocument(doc.reference)
            }
            try? await batch.commit()
        }

        // 6. Delete the user profile document itself
        try await db.collection("users").document(uid).delete()
        clearBlockedCache()
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
