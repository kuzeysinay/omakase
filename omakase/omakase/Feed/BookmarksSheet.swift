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

    // MARK: - Selection state

    @State private var isEditing = false
    @State private var selection: Set<UUID> = []

    // MARK: - Confirmation alert state

    enum PendingDelete {
        case single(UUID)
        case selected
        case all
    }
    @State private var pendingDelete: PendingDelete?
    @State private var showDeleteConfirmation = false

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
                    List(selection: isEditing ? $selection : nil) {
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
                                    pendingDelete = .single(entry.id)
                                    showDeleteConfirmation = true
                                } label: {
                                    Label(l10n.remove, systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if isEditing && !selection.isEmpty {
                            VStack(spacing: 0) {
                                Divider().opacity(0.35)
                                Button(role: .destructive) {
                                    pendingDelete = .selected
                                    showDeleteConfirmation = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "trash")
                                        Text(l10n.deleteSelectedCount(selection.count))
                                    }
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                .controlSize(.large)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                            .background(.bar)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: isEditing)
                    .animation(.easeInOut(duration: 0.25), value: selection.isEmpty)
                }
            }
            .navigationTitle(l10n.savedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? l10n.done : l10n.done) {
                        if isEditing {
                            isEditing = false
                            selection.removeAll()
                        } else {
                            dismiss()
                        }
                    }
                }
                if !bookmarkStore.entries.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            Button(isEditing ? l10n.cancel : l10n.selectEdit) {
                                if isEditing {
                                    isEditing = false
                                    selection.removeAll()
                                } else {
                                    isEditing = true
                                }
                            }
                            if !isEditing {
                                Menu {
                                    Button(l10n.removeAllSaved, systemImage: "trash", role: .destructive) {
                                        pendingDelete = .all
                                        showDeleteConfirmation = true
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                            }
                        }
                    }
                }
            }
            .alert(deleteAlertTitle, isPresented: $showDeleteConfirmation) {
                Button(l10n.cancel, role: .cancel) {
                    pendingDelete = nil
                }
                Button(l10n.remove, role: .destructive) {
                    executePendingDelete()
                }
            } message: {
                Text(deleteAlertMessage)
            }
            .onChange(of: bookmarkStore.entries.count) { _, newCount in
                // Exit edit mode if all bookmarks were deleted.
                if newCount == 0 {
                    isEditing = false
                    selection.removeAll()
                }
            }
        }
    }

    // MARK: - Alert helpers

    private var deleteAlertTitle: String {
        switch pendingDelete {
        case .single:
            return l10n.confirmDeleteTitle
        case .selected:
            return l10n.confirmDeleteSelectedTitle(selection.count)
        case .all:
            return l10n.confirmDeleteAllTitle
        case nil:
            return ""
        }
    }

    private var deleteAlertMessage: String {
        switch pendingDelete {
        case .single:
            return l10n.confirmDeleteMessage
        case .selected:
            return l10n.confirmDeleteSelectedMessage(selection.count)
        case .all:
            return l10n.confirmDeleteAllMessage
        case nil:
            return ""
        }
    }

    private func executePendingDelete() {
        guard let action = pendingDelete else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            switch action {
            case .single(let id):
                bookmarkStore.remove(id: id)
            case .selected:
                for id in selection {
                    bookmarkStore.remove(id: id)
                }
                selection.removeAll()
            case .all:
                bookmarkStore.removeAll()
            }
        }
        pendingDelete = nil
    }
}
