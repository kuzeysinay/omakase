//
//  ExportPostSheet.swift
//  omakase
//
//  Immersive Export Studio for customizing and sharing Omakase post cards.
//

import SwiftUI

struct ExportPostSheet: View {
    let post: Post
    var onShareCompleted: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appLanguage) private var appLanguage

    @State private var config = ShareCardConfig(theme: .paper)
    @State private var hasInitializedTheme = false
    @State private var dragTilt: CGSize = .zero
    @State private var feedbackToast: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var linkCopied = false
    @State private var imageCopied = false
    @State private var imageSaved = false
    @State private var isSavingPhoto = false

    private var l10n: L10n { L10n(lang: appLanguage) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                previewStage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                customizationStrip

                linkBar

                actionDock
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 12)
            .background(Color(.systemBackground))
            .overlay(alignment: .top) {
                if let toast = feedbackToast {
                    Text(toast)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(OmakaseTheme.chipActiveText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(OmakaseTheme.chipActiveFill, in: Capsule())
                        .shadow(color: Color.black.opacity(0.18), radius: 10, y: 4)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.85), value: feedbackToast)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 7) {
                        Image("AppLogo")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(OmakaseTheme.ink)
                        Text(l10n.exportStudioTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(OmakaseTheme.ink)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(l10n.closeLabel)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if !hasInitializedTheme {
                config.theme = ShareCardTheme.defaultTheme(for: colorScheme)
                hasInitializedTheme = true
            }
        }
    }

    // MARK: - Interactive 3D Preview Stage

    private var previewStage: some View {
        GeometryReader { geo in
            let cardSize = config.aspectRatio.size
            let availableW = max(120, geo.size.width - 28)
            let availableH = max(120, geo.size.height - 20)
            let scale = min(availableW / cardSize.width, availableH / cardSize.height)
            let previewW = cardSize.width * scale
            let previewH = cardSize.height * scale

            let tiltX = Double(-dragTilt.height / 14).clamped(to: -8...8)
            let tiltY = Double(dragTilt.width / 14).clamped(to: -8...8)

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(OmakaseTheme.wash)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(OmakaseTheme.stroke.opacity(0.75), lineWidth: 0.8)
                    )

                ShareCardView(post: post, config: config, language: appLanguage)
                    .scaleEffect(scale)
                    .frame(width: previewW, height: previewH)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(OmakaseTheme.stroke, lineWidth: 1)
                    )
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.52 : 0.14),
                        radius: 22,
                        x: 0,
                        y: 10
                    )
                    .rotation3DEffect(.degrees(tiltX), axis: (x: 1, y: 0, z: 0), perspective: 0.55)
                    .rotation3DEffect(.degrees(tiltY), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
                    .animation(.spring(response: 0.36, dampingFraction: 0.80), value: config)
                    .gesture(
                        DragGesture(minimumDistance: 2)
                            .onChanged { value in
                                dragTilt = value.translation
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                                    dragTilt = .zero
                                }
                            }
                    )
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Customization Strip

    private var customizationStrip: some View {
        VStack(spacing: 10) {
            // Row 1: Full-width monochrome segmented control for aspect ratios
            HStack(spacing: 4) {
                ForEach(ShareCardAspectRatio.allCases) { ratio in
                    let isSelected = config.aspectRatio == ratio
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                            config.aspectRatio = ratio
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: ratio.iconName)
                                .font(.system(size: 12, weight: .semibold))
                            Text(ratio.localizedTitle(l10n: l10n))
                                .font(.system(size: 12.5, weight: .semibold))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(isSelected ? OmakaseTheme.chipActiveText : OmakaseTheme.ink.opacity(0.75))
                        .background(
                            isSelected ? OmakaseTheme.chipActiveFill : Color.clear,
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(OmakaseChipButtonStyle())
                }
            }
            .padding(3)
            .background(OmakaseTheme.wash, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(OmakaseTheme.stroke, lineWidth: 0.8)
            )

            // Row 2: Optional element toggles (left) + Theme swatches (right) — fits on one row without scrolling
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    if post.sourceCitation != nil {
                        toggleChip(
                            title: l10n.exportToggleSource,
                            systemImage: "book.closed",
                            isOn: $config.showSource
                        )
                    }

                    if !post.tags.isEmpty {
                        toggleChip(
                            title: l10n.exportToggleTags,
                            systemImage: "tag",
                            isOn: $config.showTags
                        )
                    }

                    toggleChip(
                        title: l10n.exportToggleMotif,
                        systemImage: "sparkles",
                        isOn: $config.showMotif
                    )
                }

                Spacer(minLength: 4)

                // Theme swatches
                HStack(spacing: 5) {
                    ForEach(ShareCardTheme.allCases) { theme in
                        let isSelected = config.theme == theme
                        Button {
                            UISelectionFeedbackGenerator().selectionChanged()
                            withAnimation(.easeOut(duration: 0.2)) {
                                config.theme = theme
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(theme.swatchPrimary)
                                    .frame(width: 22, height: 22)
                                    .overlay {
                                        if theme.isFramed {
                                            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                                .fill(theme.swatchAccent)
                                                .frame(width: 11, height: 13)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                                        .strokeBorder(theme.swatchBorder, lineWidth: 0.8)
                                                )
                                        }
                                    }
                                    .overlay(
                                        Circle()
                                            .strokeBorder(theme.swatchBorder, lineWidth: 1)
                                    )

                                if isSelected {
                                    Circle()
                                        .strokeBorder(OmakaseTheme.ink, lineWidth: 1.8)
                                        .frame(width: 27, height: 27)
                                }
                            }
                            .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(theme.localizedTitle(l10n: l10n))
                    }
                }
            }
        }
    }

    private func toggleChip(title: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.easeOut(duration: 0.18)) {
                isOn.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isOn.wrappedValue ? "checkmark" : systemImage)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 11.5, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .foregroundStyle(isOn.wrappedValue ? OmakaseTheme.chipActiveText : .secondary)
            .background(
                isOn.wrappedValue ? OmakaseTheme.chipActiveFill : OmakaseTheme.wash,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .strokeBorder(isOn.wrappedValue ? Color.clear : OmakaseTheme.stroke, lineWidth: 0.8)
            )
        }
        .buttonStyle(OmakaseChipButtonStyle())
    }

    // MARK: - getomakase.app Link Bar

    private var linkBar: some View {
        HStack(spacing: 10) {
            Image("AppLogo")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 17, height: 17)
                .foregroundStyle(OmakaseTheme.ink)

            Text(ShareService.omakaseDisplayURL)
                .font(.system(size: 13.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(OmakaseTheme.ink)

            Spacer(minLength: 8)

            Button {
                UIPasteboard.general.string = ShareService.omakaseURL.absoluteString
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                showToast(l10n.exportToastLinkCopied)
                withAnimation(.easeOut(duration: 0.18)) {
                    linkCopied = true
                }
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.2)) {
                            linkCopied = false
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: linkCopied ? "checkmark" : "link")
                        .font(.system(size: 11, weight: .bold))
                    Text(linkCopied ? l10n.exportCopied : l10n.exportCopyLink)
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .foregroundStyle(OmakaseTheme.chipActiveText)
                .background(OmakaseTheme.chipActiveFill, in: Capsule())
            }
            .buttonStyle(OmakaseChipButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(OmakaseTheme.wash, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(OmakaseTheme.stroke, lineWidth: 0.9)
        )
    }

    // MARK: - Social & Export Action Dock

    private var actionDock: some View {
        HStack(spacing: 6) {
            dockButton(title: l10n.exportActionInstagram) {
                InstagramGlyph()
                    .frame(width: 21, height: 21)
            } action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                let result = ShareService.shareToInstagramStories(
                    post: post,
                    config: config,
                    language: appLanguage,
                    onShareCompleted: onShareCompleted
                )
                if result == .failed {
                    showToast(l10n.errorSomethingWrong)
                }
            }

            dockButton(title: l10n.exportActionWhatsApp) {
                WhatsAppGlyph()
                    .frame(width: 21, height: 21)
            } action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                let result = ShareService.shareToWhatsApp(
                    post: post,
                    config: config,
                    language: appLanguage,
                    onShareCompleted: onShareCompleted
                )
                if result == .failed {
                    showToast(l10n.errorSomethingWrong)
                }
            }

            dockButton(title: l10n.exportActionX) {
                XBrandGlyph()
                    .frame(width: 19, height: 19)
            } action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                let result = ShareService.shareToX(
                    post: post,
                    config: config,
                    language: appLanguage,
                    onShareCompleted: onShareCompleted
                )
                if result == .failed {
                    showToast(l10n.errorSomethingWrong)
                }
            }

            dockButton(
                title: l10n.exportActionSave,
                isHighlighted: imageSaved
            ) {
                if isSavingPhoto {
                    ProgressView()
                        .controlSize(.small)
                        .tint(OmakaseTheme.ink)
                } else {
                    Image(systemName: imageSaved ? "checkmark" : "arrow.down.to.line")
                        .font(.system(size: 18, weight: .semibold))
                }
            } action: {
                guard !isSavingPhoto else { return }
                isSavingPhoto = true
                Task {
                    let saved = await ShareService.saveToPhotos(
                        post: post,
                        config: config,
                        language: appLanguage,
                        onShareCompleted: onShareCompleted
                    )
                    isSavingPhoto = false
                    if saved {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        showToast(l10n.exportToastSavedToPhotos)
                        withAnimation(.easeOut(duration: 0.18)) {
                            imageSaved = true
                        }
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation(.easeOut(duration: 0.2)) {
                            imageSaved = false
                        }
                    } else {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        showToast(l10n.exportToastPhotoPermissionDenied)
                    }
                }
            }

            dockButton(
                title: l10n.exportActionCopy,
                isHighlighted: imageCopied
            ) {
                Image(systemName: imageCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 18, weight: .semibold))
            } action: {
                if ShareService.copyImageToClipboard(post: post, config: config, language: appLanguage) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    showToast(l10n.exportToastImageCopied)
                    withAnimation(.easeOut(duration: 0.18)) {
                        imageCopied = true
                    }
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        await MainActor.run {
                            withAnimation(.easeOut(duration: 0.2)) {
                                imageCopied = false
                            }
                        }
                    }
                }
            }

            dockButton(title: l10n.exportActionMore) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
            } action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                ShareService.presentShareSheet(
                    post: post,
                    config: config,
                    language: appLanguage,
                    onShareCompleted: onShareCompleted
                )
            }
        }
        .padding(.top, 2)
    }

    private func dockButton<Icon: View>(
        title: String,
        isHighlighted: Bool = false,
        @ViewBuilder icon: () -> Icon,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(isHighlighted ? OmakaseTheme.chipActiveFill : OmakaseTheme.wash)
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .strokeBorder(
                                    isHighlighted ? Color.clear : OmakaseTheme.stroke,
                                    lineWidth: 0.9
                                )
                        )

                    icon()
                        .foregroundStyle(isHighlighted ? OmakaseTheme.chipActiveText : OmakaseTheme.ink)
                }

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(OmakaseTheme.ink.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(OmakaseChipButtonStyle())
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        feedbackToast = message
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                feedbackToast = nil
            }
        }
    }
}

// MARK: - Monochrome Social Vector Glyphs

private struct InstagramGlyph: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                .strokeBorder(lineWidth: 1.8)
            Circle()
                .strokeBorder(lineWidth: 1.8)
                .padding(5.2)
            Circle()
                .fill(.primary)
                .frame(width: 2.5, height: 2.5)
                .offset(x: 5.2, y: -5.2)
        }
    }
}

private struct WhatsAppGlyph: View {
    var body: some View {
        ZStack {
            WhatsAppBubbleShape()
                .stroke(style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
            Image(systemName: "phone.fill")
                .font(.system(size: 9.5, weight: .bold))
                .rotationEffect(.degrees(12))
                .offset(x: 0.3, y: -0.3)
        }
    }
}

private struct WhatsAppBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let r = min(w, h) * 0.44
        let center = CGPoint(x: rect.midX + w * 0.03, y: rect.midY - h * 0.03)
        var path = Path()
        // Outer circle gap at bottom-left (~135° to ~115°) for the speech tail
        path.addArc(
            center: center,
            radius: r,
            startAngle: .degrees(142),
            endAngle: .degrees(115),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX + w * 0.12, y: rect.maxY - h * 0.08))
        path.closeSubpath()
        return path
    }
}

private struct XBrandGlyph: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let stroke = StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round)

            var slash1 = Path()
            slash1.move(to: CGPoint(x: w * 0.14, y: h * 0.12))
            slash1.addLine(to: CGPoint(x: w * 0.86, y: h * 0.88))
            context.stroke(slash1, with: .foreground, style: stroke)

            var slash2 = Path()
            slash2.move(to: CGPoint(x: w * 0.84, y: h * 0.12))
            slash2.addLine(to: CGPoint(x: w * 0.16, y: h * 0.88))
            context.stroke(slash2, with: .foreground, style: stroke)
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
