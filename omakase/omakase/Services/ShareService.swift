//
//  ShareService.swift
//  omakase
//

import SwiftUI
import UIKit

@MainActor
enum ShareService {
    static func renderCardImage(for post: Post) -> UIImage? {
        let view = ShareCardView(post: post)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        return renderer.uiImage
    }

    static func presentShareSheet(post: Post) {
        guard let image = renderCardImage(for: post) else { return }
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController
        else { return }

        // Find topmost presented controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        activityVC.popoverPresentationController?.sourceView = topVC.view
        topVC.present(activityVC, animated: true)
    }
}
