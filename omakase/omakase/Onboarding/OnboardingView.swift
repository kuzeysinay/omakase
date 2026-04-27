//
//  OnboardingView.swift
//  omakase
//

import SwiftUI

struct OnboardingView: View {

    @AppStorage("omakase.interests") private var storedInterests: String = ""
    @AppStorage("omakase.hasOnboarded") private var hasOnboarded: Bool = false

    @State private var interests: [String] = []

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
        }
        .onAppear {
            interests = FeedView.parse(interests: storedInterests)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Omakase")
                .font(.largeTitle.bold())
            Text("Tell us what you love. Your feed is generated fresh, just for you.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var continueButton: some View {
        Button {
            save()
        } label: {
            Text(interests.isEmpty ? "Add at least one interest" : "Start my feed")
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
