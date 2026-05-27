//
//  ShareService.swift
//  omakase
//

import SwiftUI
import UIKit
import LinkPresentation

final class ShareItemSource: NSObject, UIActivityItemSource {
    let post: Post
    let image: UIImage

    init(post: Post, image: UIImage) {
        self.post = post
        self.image = image
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = post.title
        metadata.imageProvider = NSItemProvider(object: image)
        // Optionally provide an icon for the app
        if let appIcon = UIImage(named: "AppIcon") {
            metadata.iconProvider = NSItemProvider(object: appIcon)
        }
        return metadata
    }
}

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
        
        let itemSource = ShareItemSource(post: post, image: image)
        let activityVC = UIActivityViewController(
            activityItems: [itemSource],
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
