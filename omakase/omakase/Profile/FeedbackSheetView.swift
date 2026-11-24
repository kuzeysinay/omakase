//
//  FeedbackSheetView.swift
//  omakase
//
//  Monochrome in-app feedback & bug report sheet for Omakase Settings.
//

import SwiftUI

struct FeedbackSheetView: View {

    var screenContext: String = "settings"
    var onSubmitted: (() -> Void)? = nil

    @Environment(\.appLanguage) private var appLanguage
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: FeedbackCategory = .idea
    @State private var rating: Int? = nil
    @State private var message: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil

    @FocusState private var isEditorFocused: Bool

    private var l10n: L10n { L10n(lang: appLanguage) }
    private var trimmedMessage: String { message.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSubmit: Bool { !isSubmitting && trimmedMessage.count >= 3 && trimmedMessage.count <= 2000 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(l10n.feedbackSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Category picker (2x2 monochrome grid)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(l10n.feedbackCategoryLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(FeedbackCategory.allCases) { category in
                                let isSelected = selectedCategory == category
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedCategory = category
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: category.iconName)
                                            .font(.system(size: 13, weight: .semibold))
                                        Text(category.title(l10n: l10n))
                                            .font(.subheadline.weight(.semibold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.85)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 11)
                                    .foregroundStyle(isSelected ? OmakaseTheme.chipActiveText : .primary)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(isSelected ? OmakaseTheme.chipActiveFill : OmakaseTheme.wash)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(isSelected ? OmakaseTheme.ink : OmakaseTheme.stroke, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Optional 1-5 satisfaction rating
                    VStack(alignment: .leading, spacing: 8) {
                        Text(l10n.feedbackRatingLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { star in
                                let filled = (rating ?? 0) >= star
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    rating = (rating == star) ? nil : star
                                } label: {
                                    Image(systemName: filled ? "star.fill" : "star")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(filled ? OmakaseTheme.ink : Color.secondary.opacity(0.45))
                                        .frame(width: 38, height: 38)
                                        .background(
                                            Circle()
                                                .fill(filled ? OmakaseTheme.wash : Color.clear)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(star)")
                            }
                            Spacer()
                        }
                    }

                    // Message editor
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(l10n.feedbackMessageLabel)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(message.count)/2000")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(message.count > 2000 ? .red : .secondary)
                        }

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $message)
                                .focused($isEditorFocused)
                                .scrollContentBackground(.hidden)
                                .font(.body)
                                .frame(minHeight: 136)
                                .padding(10)

                            if message.isEmpty {
                                Text(l10n.feedbackMessagePlaceholder)
                                    .font(.body)
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 18)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(OmakaseTheme.wash)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(isEditorFocused ? OmakaseTheme.ink : OmakaseTheme.stroke, lineWidth: 1)
                        )
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red)
                    }

                    Text(l10n.feedbackMetaFootnote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        Task { await submit() }
                    } label: {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView()
                                    .tint(OmakaseTheme.chipActiveText)
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 13.5, weight: .bold))
                            }
                            Text(isSubmitting ? l10n.feedbackSending : l10n.feedbackSubmitButton)
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(canSubmit ? OmakaseTheme.chipActiveFill : OmakaseTheme.ink.opacity(0.22))
                        )
                        .foregroundStyle(OmakaseTheme.chipActiveText)
                    }
                    .buttonStyle(OmakaseChipButtonStyle())
                    .disabled(!canSubmit)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(uiColor: .systemBackground).ignoresSafeArea())
            .navigationTitle(l10n.feedbackTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l10n.cancel) { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(l10n.hideKeyboard) { isEditorFocused = false }
                }
            }
        }
    }

    private func submit() async {
        guard canSubmit else { return }
        isEditorFocused = false
        isSubmitting = true
        errorMessage = nil
        do {
            try await TelemetryService.shared.submitFeedback(
                category: selectedCategory,
                message: trimmedMessage,
                rating: rating,
                language: appLanguage,
                screen: screenContext
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            isSubmitting = false
            onSubmitted?()
            dismiss()
        } catch {
            isSubmitting = false
            errorMessage = OmakaseError.from(error).message(l10n: l10n)
        }
    }
}
