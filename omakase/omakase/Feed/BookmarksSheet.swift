//
//  BookmarksSheet.swift
//  omakase
//

import SwiftUI

struct BookmarksSheet: View {

    @Bindable var bookmarkStore: BookmarkStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if bookmarkStore.entries.isEmpty {
                    ContentUnavailableView {
                        Label("No bookmarks", systemImage: "bookmark")
                    } description: {
                        Text("Save a finished post from your feed to read it again here.")
                    }
                } else {
                    List {
                        ForEach(bookmarkStore.entries) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                     ? "Saved post"
                                     : entry.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(entry.postCreatedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(entry.text)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(4)
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    bookmarkStore.remove(id: entry.id)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if !bookmarkStore.entries.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Remove all saved", systemImage: "trash", role: .destructive) {
                                bookmarkStore.removeAll()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
    }
}
