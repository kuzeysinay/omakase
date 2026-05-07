//
//  AuthView.swift
//  omakase
//

import SwiftUI
import GoogleSignInSwift

/// Sign-in screen shown before the user has authenticated with Google.
struct AuthView: View {

    @Environment(\.appLanguage) private var appLanguage
    let authService: AuthService

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App branding
            VStack(spacing: 12) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 72, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)

                Text(l10n.appTitle)
                    .font(.largeTitle.bold())

                Text(l10n.authTagline)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Google Sign-In button
            VStack(spacing: 16) {
                Button {
                    Task {
                        await authService.signInWithGoogle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if authService.isSigningIn {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.primary)
                        }
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.body.weight(.medium))
                        Text(l10n.signInWithGoogle)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(authService.isSigningIn)

                if let error = authService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
