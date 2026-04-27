//
//  BookmarksSheet.swift
//  omakase
//

import SwiftUI

struct BookmarksSheet: View {

    let store: BookmarksStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.items.isEmpty {
                    ContentUnavailableView(
                        "No bookmarks yet",
                        systemImage: "bookmark",
                        description: Text("Finish a post, then tap the bookmark on the card to save it here.")
                    )
                } else {
                    List {
                        ForEach(store.items) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Saved bite" : item.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(item.text)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(5)
                                Text("Saved \(item.savedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { store.remove(at: $0) }
                    }
                }
            }
            .navigationTitle("Bookmarked")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
