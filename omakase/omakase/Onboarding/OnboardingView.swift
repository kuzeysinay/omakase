//
//  OnboardingView.swift
//  omakase
//
//  Zero-friction 3-slide introduction over swaying ASCII sushi.
//  Completing or skipping seeds sensible default categories and drops
//  the user straight into the main feed (HIG Rule 2 & Rule 6 + MPTV).
//

import SwiftUI

struct OnboardingView: View {

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("omakase.interests") private var storedInterests: String = ""
    @AppStorage("omakase.hasOnboarded") private var hasOnboarded: Bool = false

    var authService: AuthService? = nil
    var onSignInDirectly: (() -> Void)? = nil

    @State private var introPage: Int = 0
    @State private var welcomeVisible: Bool = false
    @State private var slideProgress: CGFloat = 0

    private var l10n: L10n { L10n(lang: appLanguage) }

    private func autoAdvanceDuration(for page: Int) -> Double? {
        switch page {
        case 0: return 3.8
        case 1: return 6.5
        case 2: return 6.0
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            OmakaseASCIIBackdrop(
                reduceMotion: reduceMotion,
                opacityMultiplier: 0.95
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top brand & skip bar
                HStack {
                    HStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                        Text(l10n.appTitle)
                            .font(.system(size: 19, weight: .bold))
                            .tracking(-0.3)
                    }

                    Spacer()

                    LanguagePicker()

                    if let onSignInDirectly {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onSignInDirectly()
                        } label: {
                            Text(l10n.guestTasteSignIn)
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        TelemetryService.shared.track("onboarding_skipped")
                        completeOnboarding()
                    } label: {
                        Text(l10n.introSkip)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("onboarding.skipButton")
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)

                // Paged intro slides
                TabView(selection: $introPage) {
                    introWelcomeSlide.tag(0)
                    introSlide1.tag(1)
                    introSlide2.tag(2)
                    introSlide3.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: introPage)

                // Page indicators + primary CTA
                VStack(spacing: 18) {
                    HStack(spacing: 7) {
                        ForEach(0..<4, id: \.self) { index in
                            let isActive = index == introPage
                            let showsAutoProgress = isActive && autoAdvanceDuration(for: index) != nil && !reduceMotion
                            if showsAutoProgress {
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.18))
                                    Capsule()
                                        .fill(OmakaseTheme.ink)
                                        .frame(width: max(6, 28 * slideProgress))
                                }
                                .frame(width: 28, height: 6)
                            } else {
                                Capsule()
                                    .fill(isActive ? OmakaseTheme.ink : Color.primary.opacity(0.18))
                                    .frame(width: isActive ? 26 : 8, height: 6)
                            }
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: introPage)

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if introPage < 3 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                introPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(introPage < 3 ? l10n.introNext : l10n.onboardingStartFeed)
                                .font(.system(size: 16.5, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(OmakaseTheme.chipActiveFill)
                        )
                        .foregroundStyle(OmakaseTheme.chipActiveText)
                    }
                    .buttonStyle(OmakaseChipButtonStyle())
                    .accessibilityIdentifier("onboarding.primaryButton")
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
            }
        }
        .onAppear {
            TelemetryService.shared.track("onboarding_started")
        }
        .onChange(of: introPage) { _, _ in
            HapticManager.selection()
        }
        .task(id: introPage) {
            slideProgress = 0
            guard let duration = autoAdvanceDuration(for: introPage) else { return }
            if !reduceMotion {
                withAnimation(.linear(duration: duration)) {
                    slideProgress = 1.0
                }
            }
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                introPage = min(3, introPage + 1)
            }
        }
    }

    // MARK: - Slides

    private var introWelcomeSlide: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 104, height: 104)
                Circle()
                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
                    .frame(width: 104, height: 104)
                Image("AppLogo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 62, height: 62)
                    .foregroundStyle(OmakaseTheme.ink)
            }
            .scaleEffect(welcomeVisible || reduceMotion ? 1.0 : 0.92)
            .opacity(welcomeVisible || reduceMotion ? 1.0 : 0.0)

            VStack(spacing: 12) {
                Text("OMAKASE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2.4)
                    .foregroundStyle(.secondary)

                Text(l10n.introWelcomeTitle)
                    .font(.system(size: 34, weight: .heavy))
                    .tracking(-0.6)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("onboarding.slide.0.title")

                Text(l10n.introWelcomeSubtitle)
                    .font(.system(size: 16, weight: .regular))
                    .lineSpacing(4)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(welcomeVisible || reduceMotion ? 1.0 : 0.0)
            .offset(y: welcomeVisible || reduceMotion ? 0 : 8)

            Spacer()
        }
        .padding(.horizontal, 26)
        .onAppear {
            guard !welcomeVisible else { return }
            if reduceMotion {
                welcomeVisible = true
            } else {
                withAnimation(.easeOut(duration: 0.45)) {
                    welcomeVisible = true
                }
            }
        }
    }

    private var introSlide1: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(OmakaseTheme.ink)
                        .frame(width: 6, height: 6)
                    Text(l10n.introSlide1SampleTag)
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .tracking(0.9)
                        .foregroundStyle(.secondary)
                }

                Text(l10n.introSlide1SampleText)
                    .font(.system(size: 15.5, weight: .medium))
                    .lineSpacing(4)
                    .foregroundStyle(.primary)

                Divider()
                    .overlay(OmakaseTheme.stroke)

                HStack(spacing: 6) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 11, weight: .semibold))
                    Text(l10n.introSlide1SampleSource)
                        .font(.system(size: 11.5, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
            )

            slideCopy(
                eyebrow: l10n.introSlide1Eyebrow,
                title: l10n.introSlide1Title,
                body: l10n.introSlide1Body,
                titleIdentifier: "onboarding.slide.1.title"
            )

            Spacer()
        }
        .padding(.horizontal, 22)
    }

    private var introSlide2: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(OmakaseTheme.wash, in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(l10n.introSlide2Metric1)
                            .font(.system(size: 14, weight: .bold))
                        GeometryReader { barGeo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.primary.opacity(0.12))
                                Capsule()
                                    .fill(OmakaseTheme.ink)
                                    .frame(width: barGeo.size.width * 0.68)
                            }
                        }
                        .frame(height: 5)
                    }
                }

                Divider()
                    .overlay(OmakaseTheme.stroke)

                HStack(spacing: 10) {
                    Image(systemName: "fish.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(OmakaseTheme.chipActiveFill, in: Circle())
                        .foregroundStyle(OmakaseTheme.chipActiveText)
                    Text(l10n.introSlide2Metric2)
                        .font(.system(size: 14, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
            )

            slideCopy(
                eyebrow: l10n.introSlide2Eyebrow,
                title: l10n.introSlide2Title,
                body: l10n.introSlide2Body,
                titleIdentifier: "onboarding.slide.2.title"
            )

            Spacer()
        }
        .padding(.horizontal, 22)
    }

    private var introSlide3: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    featurePill(icon: "paperplane.fill", text: l10n.introSlide3Pill1)
                    featurePill(icon: "bookmark.fill", text: l10n.introSlide3Pill2)
                }

                HStack(spacing: 10) {
                    Image(systemName: "film")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(OmakaseTheme.chipActiveFill, in: Circle())
                        .foregroundStyle(OmakaseTheme.chipActiveText)
                    Text(l10n.introSlide3Pill3)
                        .font(.system(size: 14.5, weight: .bold))
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(Color.primary.opacity(0.35)).frame(width: 8, height: 8)
                        Circle().fill(Color.primary.opacity(0.65)).frame(width: 8, height: 8)
                        Circle().fill(OmakaseTheme.ink).frame(width: 8, height: 8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(OmakaseTheme.wash, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
            )

            slideCopy(
                eyebrow: l10n.introSlide3Eyebrow,
                title: l10n.introSlide3Title,
                body: l10n.introSlide3Body,
                titleIdentifier: "onboarding.slide.3.title"
            )

            Spacer()
        }
        .padding(.horizontal, 22)
    }

    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 12.5, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(OmakaseTheme.wash, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func slideCopy(eyebrow: String, title: String, body: String, titleIdentifier: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.1)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.system(size: 30, weight: .heavy))
                .tracking(-0.5)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(titleIdentifier ?? "")

            Text(body)
                .font(.system(size: 15.5))
                .lineSpacing(3.5)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        HapticManager.success()
        TelemetryService.shared.track("onboarding_completed")
        hasOnboarded = true
    }
}

#Preview {
    OnboardingView()
}

// MARK: - Mandatory Profile Setup (Display Name & Unique @username)

/// Shown right after Apple/Google first sign-up (or if a profile has no unique `@username` yet)
/// so every user chooses their own public display name (surname optional) and unique handle.
struct ProfileSetupView: View {

    let authService: AuthService

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var isCheckingUsername = false
    @State private var isUsernameAvailable: Bool? = nil
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var debounceTask: Task<Void, Never>?

    private var l10n: L10n { L10n(lang: appLanguage) }
    private var trimmedName: String { displayName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var cleanUsername: String { UserProfile.sanitizeUsername(username) }

    private var canSubmit: Bool {
        !isSaving && !trimmedName.isEmpty && cleanUsername.count >= 3 && !isCheckingUsername && isUsernameAvailable == true
    }

    private var suggestions: [String] {
        var result: [String] = []
        let base = UserProfile.sanitizeUsername(trimmedName.isEmpty ? (authService.displayName ?? "omakase") : trimmedName)
        if base.count >= 3 {
            result.append(base)
            result.append(String("\(base)_01".prefix(20)))
            result.append(String("\(base)\(Int.random(in: 10...99))".prefix(20)))
        }
        return Array(NSOrderedSet(array: result)).compactMap { $0 as? String }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            OmakaseASCIIBackdrop(reduceMotion: reduceMotion, opacityMultiplier: 0.72)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    // Top logo
                    HStack {
                        HStack(spacing: 8) {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                            Text(l10n.appTitle)
                                .font(.system(size: 19, weight: .bold))
                                .tracking(-0.3)
                        }
                        Spacer()
                    }
                    .padding(.top, 8)

                    // Live Monogram Avatar preview
                    MonogramAvatarView(
                        name: trimmedName.isEmpty ? (cleanUsername.isEmpty ? "O" : cleanUsername) : trimmedName,
                        size: 86
                    )
                    .padding(.top, 4)

                    VStack(spacing: 6) {
                        Text(l10n.profileSetupTitle)
                            .font(.system(size: 28, weight: .heavy))
                            .tracking(-0.5)
                            .multilineTextAlignment(.center)

                        Text(l10n.profileSetupSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Display name field
                    VStack(alignment: .leading, spacing: 7) {
                        Text(l10n.profileDisplayNameLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        TextField(l10n.authDisplayNamePlaceholder, text: $displayName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(OmakaseTheme.ink.opacity(0.25), lineWidth: 1)
                            )

                        Text(l10n.profileDisplayNameHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Unique @username field
                    VStack(alignment: .leading, spacing: 7) {
                        Text(l10n.profileUsernameLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 6) {
                            Text("@")
                                .font(.body.weight(.bold))
                                .foregroundStyle(.secondary)

                            TextField(l10n.authUsernamePlaceholder, text: $username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            if isCheckingUsername {
                                ProgressView().controlSize(.small)
                            } else if isUsernameAvailable == true {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.primary)
                            } else if isUsernameAvailable == false {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    isUsernameAvailable == false
                                        ? Color.red.opacity(0.5)
                                        : OmakaseTheme.ink.opacity(0.25),
                                    lineWidth: 1
                                )
                        )

                        if isUsernameAvailable == false {
                            Text(l10n.authUsernameTaken)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.red)
                        } else {
                            Text(l10n.profileUsernameCooldownNote)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(errorMessage)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.red.opacity(0.35), lineWidth: 1)
                        )
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        ZStack {
                            if isSaving {
                                ProgressView().tint(OmakaseTheme.chipActiveText)
                            } else {
                                HStack(spacing: 8) {
                                    Text(l10n.profileSetupContinue)
                                        .font(.system(size: 16.5, weight: .bold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(OmakaseTheme.chipActiveFill)
                        )
                        .foregroundStyle(OmakaseTheme.chipActiveText)
                        .opacity(canSubmit ? 1.0 : 0.4)
                    }
                    .buttonStyle(OmakaseChipButtonStyle())
                    .disabled(!canSubmit)
                    .accessibilityIdentifier("profileSetup.continueButton")
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            // Pre-fill display name with provider's first name only (surname stays optional).
            if displayName.isEmpty, let full = authService.displayName?.trimmingCharacters(in: .whitespacesAndNewlines), !full.isEmpty {
                displayName = String(full.split(whereSeparator: \.isWhitespace).first ?? Substring(full))
            }
            if username.isEmpty, let suggested = suggestions.first {
                username = suggested
                checkAvailabilityDebounced(suggested)
            }
        }
        .onChange(of: username) { _, newValue in
            let sanitized = UserProfile.sanitizeUsername(newValue)
            if sanitized != newValue {
                username = sanitized
            }
            checkAvailabilityDebounced(sanitized)
        }
    }

    private func checkAvailabilityDebounced(_ candidate: String) {
        debounceTask?.cancel()
        errorMessage = nil
        guard candidate.count >= 3 else {
            isCheckingUsername = false
            isUsernameAvailable = nil
            return
        }
        isCheckingUsername = true
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(320))
            guard !Task.isCancelled else { return }
            let available = (try? await FirestoreService.shared.isUsernameAvailable(
                candidate,
                excludingUid: authService.uid
            )) ?? false
            await MainActor.run {
                if UserProfile.sanitizeUsername(username) == candidate {
                    isUsernameAvailable = available
                    isCheckingUsername = false
                }
            }
        }
    }

    private func submit() async {
        guard let uid = authService.uid else { return }
        isSaving = true
        errorMessage = nil
        do {
            let updated = try await FirestoreService.shared.updateUserProfile(
                uid: uid,
                displayName: trimmedName,
                newUsername: cleanUsername,
                markSetupCompleted: true
            )
            await authService.markProfileSetupCompleted(displayName: updated.displayName)
            isSaving = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch let err as ProfileUpdateError {
            isSaving = false
            switch err {
            case .usernameTaken:
                errorMessage = l10n.authUsernameTaken
                isUsernameAvailable = false
            case .cooldownActive(let days):
                errorMessage = l10n.profileUsernameLockedDays(days)
            case .invalidUsername:
                errorMessage = l10n.authUsernameInvalid
            case .invalidDisplayName:
                errorMessage = l10n.errorContentBlockedMessage
            }
        } catch {
            isSaving = false
            errorMessage = OmakaseError.from(error).message(l10n: l10n)
        }
    }
}
