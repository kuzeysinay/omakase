//
//  AuthService.swift
//  omakase
//

import Foundation
import Observation
import AuthenticationServices
import CryptoKit
import Security
import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import GoogleSignInSwift

/// Centralised authentication state that the rest of the app observes.
///
/// Wraps Firebase Auth + Sign in with Apple + Google Sign-In so that view code
/// never imports third-party auth SDKs directly.
@Observable
@MainActor
final class AuthService: NSObject {

    // MARK: - Published state

    /// The currently signed-in Firebase user, or `nil` when signed out.
    private(set) var currentUser: User?
    /// `true` while a sign-in or account operation is in flight.
    private(set) var isSigningIn: Bool = false
    private(set) var errorMessage: String?
    private(set) var infoMessage: String?

    var isAuthenticated: Bool { currentUser != nil }
    var uid: String? { currentUser?.uid }
    var displayName: String? { currentUser?.displayName }
    var email: String? { currentUser?.email }
    var photoURL: URL? { currentUser?.photoURL }

    // MARK: - Private state

    @ObservationIgnored
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    @ObservationIgnored
    private var revocationObserver: NSObjectProtocol?
    @ObservationIgnored
    private var foregroundObserver: NSObjectProtocol?
    @ObservationIgnored
    private var currentRawNonce: String?
    @ObservationIgnored
    private var activeAppleController: ASAuthorizationController?
    @ObservationIgnored
    private weak var presentingWindow: UIWindow?

    // MARK: - Init

    override init() {
        super.init()
        // Listen for Firebase Auth state changes (auto-login on cold launch).
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                if let uid = user?.uid {
                    _ = try? await FirestoreService.shared.fetchBlockedUIDs(currentUid: uid)
                }
            }
        }

        // Observe Sign in with Apple credential revocation while the app is running (Rule 6).
        revocationObserver = NotificationCenter.default.addObserver(
            forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.signOut()
            }
        }

        // Check Apple ID credential state on foreground (Rule 2).
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.verifyPersistedAppleCredentialState()
            }
        }

        // Initial launch check for persisted Apple ID credential state (Rule 2).
        Task { @MainActor [weak self] in
            await self?.verifyPersistedAppleCredentialState()
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        if let revocationObserver {
            NotificationCenter.default.removeObserver(revocationObserver)
        }
        if let foregroundObserver {
            NotificationCenter.default.removeObserver(foregroundObserver)
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
        guard ContentModerationService.isAppropriate(trimmedName, maxLength: 40) else {
            errorMessage = l10n.moderationErrorInappropriateText
            return
        }
        guard cleanUsername.count >= 3 else {
            errorMessage = l10n.authUsernameTooShort
            return
        }
        guard ContentModerationService.isAppropriate(cleanUsername, maxLength: 20) else {
            errorMessage = l10n.moderationErrorInappropriateText
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
            case .requiresRecentLogin:
                return l10n.accountDeleteRequiresReauth
            default:
                break
            }
        }
        return error.localizedDescription
    }

    // MARK: - Sign in with Apple (Guideline 4.8)

    func signInWithApple() {
        guard !isSigningIn else { return }
        clearMessages()

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            errorMessage = "Unable to find presentation window."
            return
        }

        isSigningIn = true
        presentingWindow = window

        let rawNonce = Self.randomNonceString()
        currentRawNonce = rawNonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(rawNonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        activeAppleController = controller
        controller.performRequests()
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
            let nsError = error as NSError
            // GIDSignInErrorCode.canceled == -5: do not surface cancellation as an error.
            if nsError.code != -5 {
                errorMessage = error.localizedDescription
            }
        }

        isSigningIn = false
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            FirestoreService.shared.clearBlockedCache()
            currentUser = nil
            Task {
                await Self.deleteKeychainAppleUserID()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete Account (Guideline 5.1.1(v))

    func deleteAccount(l10n: L10n) async -> Bool {
        guard let user = Auth.auth().currentUser else { return false }
        let uid = user.uid
        isSigningIn = true
        clearMessages()

        do {
            // 1. Delete all associated user data in Cloud Firestore first (while still authenticated as owner).
            try await FirestoreService.shared.deleteAllUserData(uid: uid)

            // 2. Delete the Firebase Auth user record.
            try await user.delete()

            // 3. Clean up local session & preferences.
            GIDSignIn.sharedInstance.signOut()
            await Self.deleteKeychainAppleUserID()
            UserDefaults.standard.removeObject(forKey: "omakase.interests")
            UserDefaults.standard.set(false, forKey: "omakase.hasOnboarded")
            UserDefaults.standard.removeObject(forKey: "omakase.letterboxd_username")
            currentUser = nil
            isSigningIn = false
            return true
        } catch {
            let nsError = error as NSError
            if nsError.domain == AuthErrorDomain,
               let code = AuthErrorCode(rawValue: nsError.code),
               code == .requiresRecentLogin {
                // Firestore data is already purged; sign out locally so the user can re-authenticate if needed.
                signOut()
                errorMessage = l10n.accountDeleteRequiresReauth
            } else {
                errorMessage = Self.friendlyErrorMessage(for: error, l10n: l10n)
            }
            isSigningIn = false
            return false
        }
    }

    // MARK: - Sign in with Apple Credential State & Nonce Helpers

    private func verifyPersistedAppleCredentialState() async {
        guard let appleUserID = await Self.readKeychainAppleUserID(), !appleUserID.isEmpty else { return }
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: appleUserID) { [weak self] state, _ in
            Task { @MainActor in
                guard let self else { return }
                switch state {
                case .authorized:
                    break // Trust cached session (Rule 3)
                case .revoked, .notFound:
                    self.signOut() // Discard stale session (Rule 4)
                case .transferred:
                    await self.migrateAppleUserIdentifier(from: appleUserID) // Distinct migration handling (Rule 5)
                @unknown default:
                    self.signOut()
                }
            }
        }
    }

    private func migrateAppleUserIdentifier(from staleIdentifier: String) async {
        // The team-transfer identifier is stale, though the Apple ID relationship remains valid.
        await Self.deleteKeychainAppleUserID()
    }

    private nonisolated static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private nonisolated static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Keychain Persistence for Apple User Identifier (Off-Main-Thread per Security Contract)

    private nonisolated static let keychainService = "kuzeysinay.omakase.auth"
    private nonisolated static let keychainAppleUserAccount = "appleIDUser"

    private nonisolated static func saveKeychainAppleUserID(_ userID: String) async {
        await Task.detached {
            let data = Data(userID.utf8)
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: keychainAppleUserAccount,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                kSecValueData as String: data
            ]
            let status = SecItemAdd(addQuery as CFDictionary, nil)
            switch status {
            case errSecSuccess:
                break
            case errSecDuplicateItem:
                let matchQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: keychainService,
                    kSecAttrAccount as String: keychainAppleUserAccount
                ]
                let attributesToUpdate: [String: Any] = [
                    kSecValueData as String: data
                ]
                _ = SecItemUpdate(matchQuery as CFDictionary, attributesToUpdate as CFDictionary)
            default:
                break
            }
        }.value
    }

    private nonisolated static func readKeychainAppleUserID() async -> String? {
        await Task.detached {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: keychainAppleUserAccount,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            switch status {
            case errSecSuccess:
                guard let data = item as? Data else { return nil }
                return String(data: data, encoding: .utf8)
            case errSecItemNotFound:
                return nil
            default:
                return nil
            }
        }.value
    }

    private nonisolated static func deleteKeychainAppleUserID() async {
        await Task.detached {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: keychainAppleUserAccount
            ]
            let status = SecItemDelete(query as CFDictionary)
            switch status {
            case errSecSuccess, errSecItemNotFound:
                break
            default:
                break
            }
        }.value
    }
}

// MARK: - ASAuthorizationControllerDelegate & PresentationContextProviding

extension AuthService: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let window = presentingWindow {
            return window
        }
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        return scene?.windows.first ?? UIWindow()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        activeAppleController = nil

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            isSigningIn = false
            return
        }

        guard let rawNonce = currentRawNonce else {
            isSigningIn = false
            return
        }
        currentRawNonce = nil

        guard let appleIDToken = credential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            errorMessage = "Unable to fetch identity token from Apple."
            isSigningIn = false
            return
        }

        let appleUserID = credential.user
        let fullName = credential.fullName

        // Format fullName on first authorization (nil on repeat sign-ins per Rule 4).
        let formattedFirstAuthName: String? = {
            guard let fullName else { return nil }
            let formatter = PersonNameComponentsFormatter()
            let formatted = formatter.string(from: fullName).trimmingCharacters(in: .whitespacesAndNewlines)
            return formatted.isEmpty ? nil : formatted
        }()

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: rawNonce,
            fullName: fullName
        )

        Task { @MainActor in
            do {
                // Persist the stable Apple user identifier in Keychain (never email or identityToken).
                await Self.saveKeychainAppleUserID(appleUserID)

                let authResult = try await Auth.auth().signIn(with: firebaseCredential)

                if let formattedFirstAuthName, (authResult.user.displayName ?? "").isEmpty {
                    let changeReq = authResult.user.createProfileChangeRequest()
                    changeReq.displayName = formattedFirstAuthName
                    try? await changeReq.commitChanges()
                    try? await authResult.user.reload()
                }

                let updatedUser = Auth.auth().currentUser ?? authResult.user
                try await FirestoreService.shared.ensureUserProfile(
                    for: updatedUser,
                    customDisplayName: formattedFirstAuthName
                )

                if let profile = try? await FirestoreService.shared.fetchUserProfile(uid: updatedUser.uid),
                   !profile.interests.isEmpty {
                    UserDefaults.standard.set(profile.interests.joined(separator: ", "), forKey: "omakase.interests")
                    UserDefaults.standard.set(true, forKey: "omakase.hasOnboarded")
                }

                currentUser = updatedUser
            } catch {
                errorMessage = error.localizedDescription
            }
            isSigningIn = false
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        activeAppleController = nil
        currentRawNonce = nil
        isSigningIn = false

        guard let authError = error as? ASAuthorizationError else {
            errorMessage = error.localizedDescription
            return
        }

        // Rule 5: Switch on ASAuthorizationError.Code and never surface .canceled as an error.
        switch authError.code {
        case .canceled:
            break
        case .failed, .invalidResponse, .notHandled, .unknown:
            errorMessage = authError.localizedDescription
        @unknown default:
            errorMessage = authError.localizedDescription
        }
    }
}
