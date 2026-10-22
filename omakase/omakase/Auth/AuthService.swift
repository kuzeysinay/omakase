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
    private(set) var infoMessage: String?

    var isAuthenticated: Bool { currentUser != nil }
    var uid: String? { currentUser?.uid }
    var displayName: String? { currentUser?.displayName }
    var email: String? { currentUser?.email }
    var photoURL: URL? { currentUser?.photoURL }

    // MARK: - Init

    @ObservationIgnored
    private var authStateHandle: AuthStateDidChangeListenerHandle?

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

    func clearMessages() {
        errorMessage = nil
        infoMessage = nil
    }

    func setError(_ message: String?) {
        errorMessage = message
        infoMessage = nil
    }

    // MARK: - Email Sign-Up & Sign-In

    func signUpWithEmail(
        displayName: String,
        username: String,
        email: String,
        password: String,
        l10n: L10n
    ) async {
        guard !isSigningIn else { return }
        clearMessages()

        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUsername = UserProfile.sanitizeUsername(username)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = l10n.authErrorNameRequired
            return
        }
        guard cleanUsername.count >= 3 else {
            errorMessage = l10n.authUsernameTooShort
            return
        }
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            errorMessage = l10n.authErrorInvalidEmail
            return
        }
        guard password.count >= 6 else {
            errorMessage = l10n.authErrorWeakPassword
            return
        }

        isSigningIn = true

        do {
            let available = (try? await FirestoreService.shared.isUsernameAvailable(cleanUsername)) ?? true
            guard available else {
                errorMessage = l10n.authUsernameTaken
                isSigningIn = false
                return
            }

            let authResult = try await Auth.auth().createUser(withEmail: trimmedEmail, password: password)

            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = trimmedName
            try? await changeRequest.commitChanges()
            try? await authResult.user.reload()

            let updatedUser = Auth.auth().currentUser ?? authResult.user

            // Ensure new users always go through the full onboarding flow (interest selection)
            UserDefaults.standard.set("", forKey: "omakase.interests")
            UserDefaults.standard.set(false, forKey: "omakase.hasOnboarded")

            try await FirestoreService.shared.ensureUserProfile(
                for: updatedUser,
                customDisplayName: trimmedName,
                customUsername: cleanUsername
            )

            currentUser = updatedUser
        } catch {
            errorMessage = Self.friendlyErrorMessage(for: error, l10n: l10n)
        }

        isSigningIn = false
    }

    func signInWithEmail(
        email: String,
        password: String,
        l10n: L10n
    ) async {
        guard !isSigningIn else { return }
        clearMessages()

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            errorMessage = l10n.authErrorInvalidEmail
            return
        }
        guard !password.isEmpty else {
            errorMessage = l10n.authErrorInvalidCredential
            return
        }

        isSigningIn = true

        do {
            let authResult = try await Auth.auth().signIn(withEmail: trimmedEmail, password: password)
            try await FirestoreService.shared.ensureUserProfile(for: authResult.user)

            if let profile = try? await FirestoreService.shared.fetchUserProfile(uid: authResult.user.uid),
               !profile.interests.isEmpty {
                UserDefaults.standard.set(profile.interests.joined(separator: ", "), forKey: "omakase.interests")
                UserDefaults.standard.set(true, forKey: "omakase.hasOnboarded")
            }

            currentUser = authResult.user
        } catch {
            errorMessage = Self.friendlyErrorMessage(for: error, l10n: l10n)
        }

        isSigningIn = false
    }

    func sendPasswordReset(email: String, l10n: L10n) async {
        guard !isSigningIn else { return }
        clearMessages()

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            errorMessage = l10n.authErrorEnterEmailForReset
            return
        }

        isSigningIn = true
        do {
            try await Auth.auth().sendPasswordReset(withEmail: trimmedEmail)
            infoMessage = l10n.authResetPasswordSent
        } catch {
            errorMessage = Self.friendlyErrorMessage(for: error, l10n: l10n)
        }
        isSigningIn = false
    }

    private static func friendlyErrorMessage(for error: Error, l10n: L10n) -> String {
        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain,
           let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .invalidEmail:
                return l10n.authErrorInvalidEmail
            case .emailAlreadyInUse:
                return l10n.authErrorEmailInUse
            case .weakPassword:
                return l10n.authErrorWeakPassword
            case .wrongPassword, .invalidCredential, .userNotFound:
                return l10n.authErrorInvalidCredential
            default:
                break
            }
        }
        return error.localizedDescription
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        guard !isSigningIn else { return }
        isSigningIn = true
        clearMessages()

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
