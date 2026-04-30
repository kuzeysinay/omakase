//
//  AdjustTastesSheet.swift
//  omakase
//

import SwiftUI

/// Sheet to edit interests without leaving the feed; keeps AI “Ideas to try”.
struct AdjustTastesSheet: View {

    @Environment(\.appLanguage) private var appLanguage
    @AppStorage("omakase.interests") private var storedInterests: String = ""
    @Environment(\.dismiss) private var dismiss

    private var l10n: L10n { L10n(lang: appLanguage) }

    @State private var interests: [String]

    init() {
        let raw = UserDefaults.standard.string(forKey: "omakase.interests") ?? ""
        _interests = State(initialValue: FeedView.parse(interests: raw))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(l10n.adjustTastesBlurb)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    InterestsEditorForm(interests: $interests)
                        .environment(\.appLanguage, appLanguage)
                }
                .padding()
            }
            .navigationTitle(l10n.yourTastes)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l10n.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(l10n.save) {
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
