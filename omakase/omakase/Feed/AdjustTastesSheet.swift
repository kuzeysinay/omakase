//
//  AdjustTastesSheet.swift
//  omakase
//

import SwiftUI

/// Sheet to edit interests without leaving the feed; keeps AI “Ideas to try”.
struct AdjustTastesSheet: View {

    @AppStorage("omakase.interests") private var storedInterests: String = ""
    @Environment(\.dismiss) private var dismiss

    @State private var interests: [String]

    init() {
        let raw = UserDefaults.standard.string(forKey: "omakase.interests") ?? ""
        _interests = State(initialValue: FeedView.parse(interests: raw))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Tune what Omakase cooks for you. Add, remove, or steal ideas below — your feed updates right away.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    InterestsEditorForm(interests: $interests)
                }
                .padding()
            }
            .navigationTitle("Your tastes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        storedInterests = interests.joined(separator: ", ")
                        dismiss()
                    }
                    .disabled(interests.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
