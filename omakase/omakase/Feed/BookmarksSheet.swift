//
//  BookmarksSheet.swift
//  omakase
//

import SwiftUI

// MARK: - Level 1: Collection List

struct BookmarksSheet: View {

    @Environment(\.appLanguage) private var appLanguage
    @Bindable var bookmarkStore: BookmarkStore
    @Environment(\.dismiss) private var dismiss

    private var l10n: L10n { L10n(lang: appLanguage) }

    // MARK: - New-collection alert state

    @State private var showNewCollectionAlert = false
    @State private var newCollectionName = ""

    // MARK: - Rename-collection alert state

    @State private var showRenameAlert = false
    @State private var renameTarget = ""
    @State private var renameNewName = ""

    // MARK: - Delete-collection confirmation state

    @State private var showDeleteCollectionConfirmation = false
    @State private var deleteCollectionTarget = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(bookmarkStore.collectionNames, id: \.self) { name in
                    NavigationLink(value: name) {
                        HStack {
                            Label(name, systemImage: name == "All" ? "tray.full.fill" : "folder.fill")
                            Spacer()
                            Text("\(bookmarkStore.entryCount(in: name))")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if name != "All" {
                            Button(role: .destructive) {
                                deleteCollectionTarget = name
                                showDeleteCollectionConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                renameTarget = name
                                renameNewName = name
                                showRenameAlert = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { collectionName in
                CollectionEntriesView(
                    bookmarkStore: bookmarkStore,
                    collectionName: collectionName
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l10n.done) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newCollectionName = ""
                        showNewCollectionAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New Collection", isPresented: $showNewCollectionAlert) {
                TextField("Collection Name", text: $newCollectionName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    bookmarkStore.createCollection(name: newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
            .alert("Rename Collection", isPresented: $showRenameAlert) {
                TextField("Collection Name", text: $renameNewName)
                Button("Cancel", role: .cancel) { }
                Button("Rename") {
                    let trimmed = renameNewName.trimmingCharacters(in: .whitespacesAndNewlines)
                    bookmarkStore.renameCollection(old: renameTarget, new: trimmed)
                }
            }
            .alert("Delete Collection", isPresented: $showDeleteCollectionConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Keep Bookmarks") {
                    withAnimation {
                        bookmarkStore.deleteCollection(name: deleteCollectionTarget, deleteEntries: false)
                    }
                }
                Button("Delete All", role: .destructive) {
                    withAnimation {
                        bookmarkStore.deleteCollection(name: deleteCollectionTarget, deleteEntries: true)
                    }
                }
            } message: {
                Text("Delete \"\(deleteCollectionTarget)\"? You can keep its bookmarks (moved to All) or delete them too.")
            }
        }
    }
}

// MARK: - Level 2: Entries in a Collection

private struct CollectionEntriesView: View {

    @Environment(\.appLanguage) private var appLanguage
    @Bindable var bookmarkStore: BookmarkStore
    let collectionName: String

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

    private var filteredEntries: [BookmarkEntry] {
        bookmarkStore.entries(in: collectionName)
    }

    var body: some View {
        Group {
            if filteredEntries.isEmpty {
                ContentUnavailableView {
                    Label(l10n.noBookmarks, systemImage: "bookmark")
                } description: {
                    Text(l10n.bookmarksHint)
                }
            } else {
                List(selection: isEditing ? $selection : nil) {
                    ForEach(filteredEntries) { entry in
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
                        .contextMenu {
                            moveToMenu(for: entry.id)
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
        .navigationTitle(collectionName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !filteredEntries.isEmpty {
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
        .onChange(of: filteredEntries.count) { _, newCount in
            if newCount == 0 {
                isEditing = false
                selection.removeAll()
            }
        }
    }

    // MARK: - Move-to submenu

    @ViewBuilder
    private func moveToMenu(for entryId: UUID) -> some View {
        let otherCollections = bookmarkStore.collectionNames.filter { $0 != collectionName }
        if !otherCollections.isEmpty {
            Menu("Move to…") {
                ForEach(otherCollections, id: \.self) { target in
                    Button(target) {
                        withAnimation {
                            bookmarkStore.moveToCollection(entryId: entryId, collection: target)
                        }
                    }
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
                bookmarkStore.removeAll(in: collectionName)
            }
        }
        pendingDelete = nil
    }
}
