//
//  AuthService.swift
//  omakase
//

import Foundation
import Observation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import GoogleSignInSwift

/// Centralised authentication state that the rest of the app observes.
///
/// Wraps Firebase Auth + Google Sign-In so that view code never imports
/// either SDK directly.
@Observable
@MainActor
final class AuthService {

    // MARK: - Published state

    /// The currently signed-in Firebase user, or `nil` when signed out.
    private(set) var currentUser: User?
    /// `true` while a sign-in attempt is in flight.
    private(set) var isSigningIn: Bool = false
    private(set) var errorMessage: String?

    var isAuthenticated: Bool { currentUser != nil }
    var uid: String? { currentUser?.uid }
    var displayName: String? { currentUser?.displayName }
    var email: String? { currentUser?.email }
    var photoURL: URL? { currentUser?.photoURL }

    // MARK: - Init

    nonisolated(unsafe) private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        // Listen for Firebase Auth state changes (auto-login on cold launch).
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        guard !isSigningIn else { return }
        isSigningIn = true
        errorMessage = nil

        do {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                errorMessage = "Unable to find root view controller."
                isSigningIn = false
                return
            }

            // Configure Google Sign-In with the Firebase client ID.
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                errorMessage = "Firebase client ID not found. Check GoogleService-Info.plist."
                isSigningIn = false
                return
            }
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google Sign-In succeeded but no ID token was returned."
                isSigningIn = false
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            currentUser = authResult.user

            // Ensure a Firestore profile document exists for this user.
            try await FirestoreService.shared.ensureUserProfile(for: authResult.user)

        } catch {
            errorMessage = error.localizedDescription
        }

        isSigningIn = false
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
