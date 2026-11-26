//
//  AuthView.swift
//  omakase
//

import SwiftUI
import GoogleSignInSwift

/// Frictionless, multi-step Twitter/X-style authentication & sign-up flow.
struct AuthView: View {

    enum AuthStep: Equatable {
        case welcome
        case signUpCredentials   // Step 1/3: Email & Password
        case signUpDisplayName   // Step 2/3: Public Display Name
        case signUpUsername      // Step 3/3: Unique @username + Live Profile Preview
        case signIn              // Existing email account sign-in
    }

    private enum Field: Hashable {
        case email
        case password
        case displayName
        case username
    }

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let authService: AuthService
    var onClose: (() -> Void)? = nil

    @State private var step: AuthStep = .welcome
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var isPasswordVisible: Bool = false

    // Username availability check state
    @State private var isCheckingUsername: Bool = false
    @State private var isUsernameAvailable: Bool? = nil
    @State private var hasManuallyEditedUsername: Bool = false

    @FocusState private var focusedField: Field?

    private var l10n: L10n { L10n(lang: appLanguage) }

    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: "@")
        return parts.count == 2 && parts[1].contains(".") && parts[0].count >= 1
    }

    private var isPasswordValid: Bool {
        password.count >= 8
    }

    private var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var sanitizedUsername: String {
        UserProfile.sanitizeUsername(username)
    }

    private var usernameSuggestions: [String] {
        var candidates: [String] = []
        let fromName = UserProfile.sanitizeUsername(displayName)
        if fromName.count >= 3 {
            candidates.append(fromName)
        }
        let nameParts = displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .map { UserProfile.sanitizeUsername($0) }
            .filter { !$0.isEmpty }
        if nameParts.count >= 2 {
            let underscoreJoined = "\(nameParts[0])_\(nameParts[1])"
            if underscoreJoined.count >= 3 && !candidates.contains(underscoreJoined) {
                candidates.append(String(underscoreJoined.prefix(20)))
            }
        }
        if let emailPrefix = email.split(separator: "@").first {
            let cleanEmail = UserProfile.sanitizeUsername(String(emailPrefix))
            if cleanEmail.count >= 3 && !candidates.contains(cleanEmail) {
                candidates.append(cleanEmail)
            }
        }
        if let first = candidates.first {
            let numbered = String("\(first)01".prefix(20))
            if !candidates.contains(numbered) {
                candidates.append(numbered)
            }
        }
        return Array(ContentModerationService.filterAppropriate(candidates).prefix(3))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                OmakaseASCIIBackdrop(
                    reduceMotion: reduceMotion,
                    opacityMultiplier: step == .welcome ? 0.92 : 0.55
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar

                    ScrollView {
                        VStack(spacing: 24) {
                            switch step {
                            case .welcome:
                                welcomeContent
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                        removal: .opacity
                                    ))
                            case .signUpCredentials:
                                signUpStep1Credentials
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            case .signUpDisplayName:
                                signUpStep2DisplayName
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            case .signUpUsername:
                                signUpStep3Username
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            case .signIn:
                                signInContent
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onChange(of: username) { _, newValue in
            let clean = UserProfile.sanitizeUsername(newValue)
            if clean != newValue {
                username = clean
            }
            checkUsernameAvailabilityDebounced(clean)
        }
    }

    // MARK: - Custom Top Bar with Progress Indicator

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack {
                if step != .welcome {
                    Button {
                        navigateBack()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.primary.opacity(0.06))
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(l10n.backA11y)
                    .accessibilityIdentifier("auth.topBar.backButton")
                } else if let onClose {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(l10n.closeLabel)
                    .accessibilityIdentifier("auth.topBar.closeButton")
                } else {
                    Spacer().frame(width: 40, height: 40)
                }

                Spacer()

                if let progress = signUpProgress {
                    HStack(spacing: 6) {
                        ForEach(1...3, id: \.self) { index in
                            Capsule()
                                .fill(index <= progress ? OmakaseTheme.chipActiveFill : Color.primary.opacity(0.12))
                                .frame(width: index == progress ? 28 : 14, height: 5)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: progress)
                        }
                    }
                } else {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .opacity(step == .signIn ? 1 : 0)
                }

                Spacer()

                LanguagePicker()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
    }

    private var signUpProgress: Int? {
        switch step {
        case .signUpCredentials: return 1
        case .signUpDisplayName: return 2
        case .signUpUsername: return 3
        default: return nil
        }
    }

    // MARK: - Screen 0: Welcome Screen

    private var welcomeContent: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 24)

            // Hero Branding
            VStack(spacing: 14) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)

                Text(l10n.appTitle)
                    .font(.system(size: 36, weight: .bold, design: .default))

                Text(l10n.authTagline)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }

            Spacer().frame(height: 16)

            messageBanner

            // Primary Actions
            VStack(spacing: 12) {
                // 1. Continue with Apple (Guideline 4.8 equivalent primary login option)
                appleButton

                // 2. Continue with Google
                googleButton

                // Divider
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(height: 1)
                    Text(l10n.authOrDivider)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(height: 1)
                }
                .padding(.vertical, 4)

                // 3. Create account with Email (Starts multi-step wizard)
                Button {
                    HapticManager.light()
                    authService.clearMessages()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        step = .signUpCredentials
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        focusedField = .email
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope.fill")
                            .font(.body.weight(.medium))
                        Text(l10n.authCreateAccountButton)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(OmakaseTheme.chipActiveText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(OmakaseTheme.chipActiveFill)
                    )
                }
                .buttonStyle(OmakaseChipButtonStyle())
                .accessibilityIdentifier("auth.welcome.createAccountButton")
            }

            // Switch to Sign-In
            Button {
                HapticManager.light()
                authService.clearMessages()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    step = .signIn
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    focusedField = .email
                }
            } label: {
                Text(l10n.authSwitchToSignInPrompt)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("auth.welcome.signInButton")

            // Support & Legal links accessible before sign-in (Guideline 1.5 & 5.1.1(i))
            HStack(spacing: 12) {
                if let termsURL = URL(string: "https://getomakase.app/terms.html") {
                    Link(l10n.termsOfUse, destination: termsURL)
                }
                Text("•").foregroundStyle(.tertiary)
                if let privacyURL = URL(string: "https://getomakase.app/privacy.html") {
                    Link(l10n.privacyPolicy, destination: privacyURL)
                }
                Text("•").foregroundStyle(.tertiary)
                if let supportURL = URL(string: "mailto:destek@getomakase.app") {
                    Link(l10n.contactSupport, destination: supportURL)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    // MARK: - Step 1 / 3: Email & Password

    private var signUpStep1Credentials: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.authStep1Title)
                    .font(.title.bold())
                    .accessibilityIdentifier("auth.signup.step1.title")
                Text(l10n.authStep1Subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                // Email Field
                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)

                    TextField(l10n.authEmailLabel, text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: .email)
                        .onSubmit { focusedField = .password }
                        .accessibilityIdentifier("auth.signup.emailField")

                    if isEmailValid {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(fieldBackground(isFocused: focusedField == .email))

                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)

                        Group {
                            if isPasswordVisible {
                                TextField(l10n.authPasswordLabel, text: $password)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .accessibilityIdentifier("auth.signup.passwordVisibleField")
                            } else {
                                SecureField(l10n.authPasswordLabel, text: $password)
                                    .accessibilityIdentifier("auth.signup.passwordField")
                            }
                        }
                        .textContentType(.newPassword)
                        .submitLabel(.continue)
                        .focused($focusedField, equals: .password)
                        .onSubmit { advanceFromStep1() }

                        Button {
                            HapticManager.light()
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                                .frame(width: 32, height: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(l10n.passwordVisibilityA11y)
                        .accessibilityIdentifier("auth.signup.passwordVisibilityButton")
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(fieldBackground(isFocused: focusedField == .password))

                    // Subtle password requirement indicator
                    HStack(spacing: 6) {
                        Image(systemName: isPasswordValid ? "checkmark.circle.fill" : "circle")
                            .font(.caption)
                            .foregroundStyle(isPasswordValid ? .green : .secondary)
                        Text(isPasswordValid ? l10n.authPasswordHintValid : l10n.authPasswordHintRequirement)
                            .font(.caption)
                            .foregroundStyle(isPasswordValid ? .primary : .secondary)
                    }
                    .padding(.leading, 4)
                }
            }

            messageBanner

            Button {
                advanceFromStep1()
            } label: {
                HStack(spacing: 8) {
                    Text(l10n.authContinueButton)
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(OmakaseTheme.chipActiveText)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(OmakaseTheme.chipActiveFill)
                )
            }
            .buttonStyle(OmakaseChipButtonStyle())
            .padding(.top, 4)
            .accessibilityIdentifier("auth.signup.step1.continueButton")
        }
    }

    // MARK: - Step 2 / 3: Display Name (Görünür İsim)

    private var signUpStep2DisplayName: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.authStep2Title)
                    .font(.title.bold())
                    .accessibilityIdentifier("auth.signup.step2.title")
                Text(l10n.authStep2Subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "person.text.rectangle")
                        .foregroundStyle(.secondary)
                        .frame(width: 22)

                    TextField(l10n.authDisplayNamePlaceholder, text: $displayName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.continue)
                        .focused($focusedField, equals: .displayName)
                        .onChange(of: displayName) { _, newValue in
                            if newValue.count > 40 {
                                displayName = String(newValue.prefix(40))
                            }
                        }
                        .onSubmit { advanceFromStep2() }
                        .accessibilityIdentifier("auth.signup.displayNameField")

                    if !trimmedDisplayName.isEmpty {
                        Button {
                            displayName = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(l10n.clearTextA11y)
                        .accessibilityIdentifier("auth.signup.clearDisplayNameButton")
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(fieldBackground(isFocused: focusedField == .displayName))

                Text("\(trimmedDisplayName.count)/40")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 4)
            }

            messageBanner

            Button {
                advanceFromStep2()
            } label: {
                HStack(spacing: 8) {
                    Text(l10n.authContinueButton)
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(OmakaseTheme.chipActiveText)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(OmakaseTheme.chipActiveFill)
                )
            }
            .buttonStyle(OmakaseChipButtonStyle())
            .accessibilityIdentifier("auth.signup.step2.continueButton")
        }
    }

    // MARK: - Step 3 / 3: @Username + Live Twitter-Style Profile Preview

    private var signUpStep3Username: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.authStep3Title)
                    .font(.title.bold())
                    .accessibilityIdentifier("auth.signup.step3.title")
                Text(l10n.authStep3Subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Twitter-style Live Profile Preview Card
            VStack(alignment: .leading, spacing: 8) {
                Text(l10n.authProfilePreviewLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(OmakaseTheme.chipActiveFill)
                            .frame(width: 50, height: 50)
                        Text(initials(from: trimmedDisplayName))
                            .font(.headline.bold())
                            .foregroundStyle(Color(uiColor: .systemBackground))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(trimmedDisplayName.isEmpty ? l10n.authNamePlaceholder : trimmedDisplayName)
                            .font(.headline.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text("@\(sanitizedUsername.isEmpty ? l10n.authUsernamePlaceholder : sanitizedUsername)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.09), lineWidth: 1)
                        )
                )
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("auth.signup.previewCard")
            }

            // @username Input Field
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("@")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)

                    TextField(l10n.authUsernamePlaceholder, text: $username)
                        .font(.body.weight(.medium))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($focusedField, equals: .username)
                        .onTapGesture {
                            hasManuallyEditedUsername = true
                        }
                        .onSubmit { completeSignUp() }
                        .accessibilityIdentifier("auth.signup.usernameField")

                    if isCheckingUsername {
                        ProgressView()
                            .controlSize(.small)
                    } else if sanitizedUsername.count >= 3, let available = isUsernameAvailable {
                        Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(available ? .green : .red)
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 54)
                .background(fieldBackground(isFocused: focusedField == .username))

                // Availability status text
                if sanitizedUsername.count >= 3, !isCheckingUsername, let available = isUsernameAvailable {
                    HStack(spacing: 5) {
                        Image(systemName: available ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.caption)
                        Text(available ? l10n.authUsernameAvailable : l10n.authUsernameTaken)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(available ? .green : .red)
                    .padding(.leading, 4)
                }
            }

            // Quick Suggestion Chips
            if !usernameSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(l10n.authSuggestedUsernames)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(usernameSuggestions, id: \.self) { suggestion in
                                let isSelected = (sanitizedUsername == suggestion)
                                Button {
                                    HapticManager.selection()
                                    username = suggestion
                                    hasManuallyEditedUsername = true
                                } label: {
                                    Text("@\(suggestion)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(isSelected ? Color(uiColor: .systemBackground) : .primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(isSelected ? OmakaseTheme.chipActiveFill : Color.primary.opacity(0.07))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            messageBanner

            Button {
                completeSignUp()
            } label: {
                HStack(spacing: 10) {
                    if authService.isSigningIn {
                        ProgressView()
                            .controlSize(.small)
                            .tint(OmakaseTheme.chipActiveText)
                    }
                    Text(l10n.authCompleteSignUpButton)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(OmakaseTheme.chipActiveText)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(OmakaseTheme.chipActiveFill)
                )
                .opacity((authService.isSigningIn || isCheckingUsername || isUsernameAvailable == false) ? 0.45 : 1.0)
            }
            .buttonStyle(OmakaseChipButtonStyle())
            .disabled(authService.isSigningIn || isCheckingUsername || isUsernameAvailable == false)
            .padding(.top, 4)
            .accessibilityIdentifier("auth.signup.completeButton")
        }
    }

    // MARK: - Sign In Screen (Existing Account)

    private var signInContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text(l10n.authWelcomeBackTitle)
                    .font(.title.bold())
                    .accessibilityIdentifier("auth.signin.title")
                Text(l10n.authWelcomeBackSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)

                    TextField(l10n.authEmailLabel, text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: .email)
                        .onSubmit { focusedField = .password }
                        .accessibilityIdentifier("auth.signin.emailField")
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(fieldBackground(isFocused: focusedField == .email))

                HStack(spacing: 12) {
                    Image(systemName: "lock")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)

                    Group {
                        if isPasswordVisible {
                            TextField(l10n.authPasswordLabel, text: $password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .accessibilityIdentifier("auth.signin.passwordVisibleField")
                        } else {
                            SecureField(l10n.authPasswordLabel, text: $password)
                                .accessibilityIdentifier("auth.signin.passwordField")
                        }
                    }
                    .textContentType(.password)
                    .submitLabel(.go)
                    .focused($focusedField, equals: .password)
                    .onSubmit { submitSignIn() }

                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(fieldBackground(isFocused: focusedField == .password))

                HStack {
                    Spacer()
                    Button {
                        focusedField = nil
                        Task {
                            await authService.sendPasswordReset(email: email, l10n: l10n)
                        }
                    } label: {
                        Text(l10n.authForgotPassword)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("auth.signin.forgotPasswordButton")
                }
            }

            messageBanner

            VStack(spacing: 14) {
                Button {
                    submitSignIn()
                } label: {
                    HStack(spacing: 10) {
                        if authService.isSigningIn {
                            ProgressView()
                                .controlSize(.small)
                                .tint(OmakaseTheme.chipActiveText)
                        }
                        Text(l10n.authSignInWithEmailButton)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(OmakaseTheme.chipActiveText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(OmakaseTheme.chipActiveFill)
                    )
                    .opacity(authService.isSigningIn ? 0.45 : 1.0)
                }
                .buttonStyle(OmakaseChipButtonStyle())
                .disabled(authService.isSigningIn)
                .accessibilityIdentifier("auth.signin.submitButton")

                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(height: 1)
                    Text(l10n.authOrDivider)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(height: 1)
                }
                .padding(.vertical, 2)

                appleButton

                googleButton
            }
        }
    }

    // MARK: - Shared Components

    private var appleButton: some View {
        Button {
            focusedField = nil
            authService.signInWithApple(l10n: l10n)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 19, weight: .semibold))
                Text(l10n.signInWithApple)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Color(uiColor: .systemBackground))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary)
            )
        }
        .buttonStyle(.plain)
        .disabled(authService.isSigningIn)
        .accessibilityIdentifier("auth.welcome.appleButton")
    }

    private var googleButton: some View {
        Button {
            focusedField = nil
            Task {
                await authService.signInWithGoogle(l10n: l10n)
            }
        } label: {
            HStack(spacing: 10) {
                if authService.isSigningIn && step == .welcome {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.primary)
                } else {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                }
                Text(l10n.signInWithGoogle)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.14), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(authService.isSigningIn)
        .accessibilityIdentifier("auth.welcome.googleButton")
    }

    @ViewBuilder
    private var messageBanner: some View {
        if let error = authService.errorMessage {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(width: 28, height: 28)
                    .background(Color.red.opacity(0.12), in: Circle())
                Text(error)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("auth.messageBanner.error")
                Spacer(minLength: 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.red.opacity(0.32), lineWidth: 1)
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else if let info = authService.infoMessage {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(OmakaseTheme.ink)
                    .frame(width: 28, height: 28)
                    .background(OmakaseTheme.wash, in: Circle())
                Text(info)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("auth.messageBanner.info")
                Spacer(minLength: 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
    }

    private func fieldBackground(isFocused: Bool) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(uiColor: .secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isFocused ? Color.primary.opacity(0.5) : Color.primary.opacity(0.1),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
    }

    // MARK: - Navigation & Actions

    private func navigateBack() {
        HapticManager.light()
        focusedField = nil
        authService.clearMessages()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            switch step {
            case .signUpCredentials, .signIn:
                step = .welcome
            case .signUpDisplayName:
                step = .signUpCredentials
            case .signUpUsername:
                step = .signUpDisplayName
            case .welcome:
                break
            }
        }
    }

    private func advanceFromStep1() {
        authService.clearMessages()
        guard isEmailValid else {
            authService.setError(l10n.authErrorInvalidEmail)
            return
        }
        guard isPasswordValid else {
            authService.setError(l10n.authErrorWeakPassword)
            return
        }
        HapticManager.light()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            step = .signUpDisplayName
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            focusedField = .displayName
        }
    }

    private func advanceFromStep2() {
        authService.clearMessages()
        guard !trimmedDisplayName.isEmpty else {
            authService.setError(l10n.authErrorNameRequired)
            return
        }
        guard ContentModerationService.isAppropriate(trimmedDisplayName, maxLength: 40) else {
            authService.setError(l10n.moderationErrorInappropriateText)
            return
        }
        if !hasManuallyEditedUsername || sanitizedUsername.isEmpty {
            if let firstSuggestion = usernameSuggestions.first {
                username = firstSuggestion
            }
        }
        HapticManager.light()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            step = .signUpUsername
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            focusedField = .username
        }
    }

    private func completeSignUp() {
        focusedField = nil
        authService.clearMessages()
        guard sanitizedUsername.count >= 3 else {
            authService.setError(l10n.authUsernameTooShort)
            return
        }
        guard ContentModerationService.isAppropriate(sanitizedUsername, maxLength: 20) else {
            authService.setError(l10n.moderationErrorInappropriateText)
            return
        }
        Task {
            await authService.signUpWithEmail(
                displayName: trimmedDisplayName,
                username: sanitizedUsername,
                email: email,
                password: password,
                l10n: l10n
            )
        }
    }

    private func submitSignIn() {
        focusedField = nil
        Task {
            await authService.signInWithEmail(
                email: email,
                password: password,
                l10n: l10n
            )
        }
    }

    private func checkUsernameAvailabilityDebounced(_ candidate: String) {
        guard candidate.count >= 3 else {
            isUsernameAvailable = nil
            isCheckingUsername = false
            return
        }
        isCheckingUsername = true
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard sanitizedUsername == candidate else { return }
            let available = (try? await FirestoreService.shared.isUsernameAvailable(candidate)) ?? true
            if sanitizedUsername == candidate {
                isUsernameAvailable = available
                isCheckingUsername = false
            }
        }
    }

    private func initials(from name: String) -> String {
        let words = name.split(separator: " ").prefix(2)
        if words.isEmpty { return "@" }
        return words.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}
