//
//  ShareCardView.swift
//  omakase
//

import SwiftUI

/// A SwiftUI view rendered as an image for sharing (Instagram story aspect ratio).
struct ShareCardView: View {
    let post: Post

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0a0f1e), Color(hex: 0x1a0a2e)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                // MARK: - Branding
                Text("omakase")
                    .font(.system(size: 32, weight: .light))
                    .textCase(.uppercase)
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.40))
                    .padding(.top, 80)

                Spacer()

                // MARK: - Content
                VStack(alignment: .leading, spacing: 32) {
                    Text(post.title)
                        .font(.system(size: 64, weight: .bold))
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(.white)
                        .lineLimit(4)

                    Text(post.text)
                        .font(.system(size: 40, weight: .regular))
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(30)
                }
                .padding(.horizontal, 48)

                Spacer()

                // MARK: - Footer
                VStack(spacing: 24) {
                    if !post.tags.isEmpty {
                        tagChips
                    }

                    Text(post.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 80)
            }
        }
        .frame(width: 1080, height: 1350)
    }

    private var tagChips: some View {
        HStack(spacing: 12) {
            ForEach(post.tags.prefix(5), id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.70))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.20), lineWidth: 1.5)
                    )
            }
        }
    }
}

// MARK: - Hex color helper

private extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
