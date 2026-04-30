//
//  BookmarksSheet.swift
//  omakase
//

import SwiftUI

struct BookmarksSheet: View {

    @Environment(\.appLanguage) private var appLanguage
    @Bindable var bookmarkStore: BookmarkStore
    @Environment(\.dismiss) private var dismiss

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        NavigationStack {
            Group {
                if bookmarkStore.entries.isEmpty {
                    ContentUnavailableView {
                        Label(l10n.noBookmarks, systemImage: "bookmark")
                    } description: {
                        Text(l10n.bookmarksHint)
                    }
                } else {
                    List {
                        ForEach(bookmarkStore.entries) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                     ? l10n.savedPostFallbackTitle
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
                                    Label(l10n.remove, systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(l10n.savedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l10n.done) { dismiss() }
                }
                if !bookmarkStore.entries.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(l10n.removeAllSaved, systemImage: "trash", role: .destructive) {
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
