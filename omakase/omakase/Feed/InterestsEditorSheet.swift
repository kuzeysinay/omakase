//
//  InterestsEditorSheet.swift
//  omakase
//

import SwiftUI

/// Inline editor for the comma-separated `omakase.interests` string — no full onboarding reset.
struct InterestsEditorSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Binding var storedInterests: String

    @State private var chips: [String] = []
    @State private var draft: String = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Add a taste…", text: $draft)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .focused($fieldFocused)
                            .submitLabel(.done)
                            .onSubmit(commitDraft)
                        Button {
                            commitDraft()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .disabled(trimmedDraft.isEmpty)
                    }
                } header: {
                    Text("Add interests")
                }

                if !chips.isEmpty {
                    Section {
                        ForEach(chips, id: \.self) { chip in
                            HStack {
                                Text(chip)
                                Spacer()
                                Button {
                                    chips.removeAll { $0 == chip }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        Text("Current tastes (\(chips.count))")
                    }
                }
            }
            .navigationTitle("Your tastes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        persist()
                        dismiss()
                    }
                }
            }
            .onAppear {
                chips = FeedView.parse(interests: storedInterests)
                fieldFocused = true
            }
        }
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func commitDraft() {
        let v = trimmedDraft
        guard !v.isEmpty else { return }
        if !chips.contains(where: { $0.caseInsensitiveCompare(v) == .orderedSame }) {
            chips.append(v)
        }
        draft = ""
    }

    private func persist() {
        storedInterests = chips.joined(separator: ", ")
    }
}
