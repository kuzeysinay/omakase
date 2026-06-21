//
//  OnboardingView.swift
//  omakase
//

import SwiftUI

struct OnboardingView: View {

    @Environment(\.appLanguage) private var appLanguage
    @AppStorage("omakase.interests") private var storedInterests: String = ""
    @AppStorage("omakase.hasOnboarded") private var hasOnboarded: Bool = false

    @State private var interests: [String] = []

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    InterestsEditorForm(interests: $interests)

                    Spacer(minLength: 32)
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                continueButton
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    LanguagePicker()
                }
            }
        }
        .onAppear {
            interests = FeedView.parse(interests: storedInterests)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .padding(.bottom, 8)
            Text(l10n.appTitle)
                .font(.largeTitle.bold())
            Text(l10n.onboardingTagline)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var continueButton: some View {
        Button {
            save()
        } label: {
            Text(interests.isEmpty ? l10n.onboardingNeedInterest : l10n.onboardingStartFeed)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(interests.isEmpty)
    }

    // MARK: - Actions

    private func save() {
        storedInterests = interests.joined(separator: ", ")
        hasOnboarded = true
    }
}

#Preview {
    OnboardingView()
}
