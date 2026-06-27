//
//  PostCacheService.swift
//  omakase
//

import Foundation
import SwiftData

@MainActor
class PostCacheService {
    static let shared = PostCacheService()

    private var modelContainer: ModelContainer?

    func configure(container: ModelContainer) {
        self.modelContainer = container
    }

    func cachePost(_ post: Post) async {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        let cached = CachedPost(from: post)
        context.insert(cached)
        try? context.save()
    }

    func loadCachedPosts(limit: Int = 50) async -> [Post] {
        guard let container = modelContainer else { return [] }
        let context = container.mainContext
        var descriptor = FetchDescriptor<CachedPost>(
            sortBy: [SortDescriptor(\CachedPost.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        do {
            let cached = try context.fetch(descriptor)
            return cached.map { $0.toPost() }.reversed()
        } catch {
            return []
        }
    }

    func clearOldPosts(olderThan days: Int = 30) async {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let descriptor = FetchDescriptor<CachedPost>(
            predicate: #Predicate { $0.cachedAt < cutoff }
        )
        do {
            let old = try context.fetch(descriptor)
            for post in old { context.delete(post) }
            try? context.save()
        } catch {}
    }

    var hasCachedPosts: Bool {
        get async {
            guard let container = modelContainer else { return false }
            let context = container.mainContext
            var descriptor = FetchDescriptor<CachedPost>()
            descriptor.fetchLimit = 1
            return (try? context.fetchCount(descriptor)) ?? 0 > 0
        }
    }
}
