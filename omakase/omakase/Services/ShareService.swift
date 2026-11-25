//
//  ShareService.swift
//  omakase
//

import SwiftUI
import UIKit
import LinkPresentation
import Photos

enum ShareActionResult {
    case openedApp
    case openedAppWithCopiedImage
    case fallbackSheet
    case failed
}

final class ShareItemSource: NSObject, UIActivityItemSource {
    let post: Post
    let image: UIImage
    let shareURL: URL

    init(post: Post, image: UIImage, shareURL: URL = ShareService.omakaseURL) {
        self.post = post
        self.image = image
        self.shareURL = shareURL
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
        metadata.originalURL = shareURL
        metadata.url = shareURL
        metadata.imageProvider = NSItemProvider(object: image)
        if let appIcon = UIImage(named: "AppIcon") {
            metadata.iconProvider = NSItemProvider(object: appIcon)
        }
        return metadata
    }
}

@MainActor
enum ShareService {
    nonisolated static let omakaseURL = URL(string: "https://getomakase.app")!
    nonisolated static let omakaseDisplayURL = "getomakase.app"

    static func renderCardImage(
        for post: Post,
        config: ShareCardConfig = ShareCardConfig(theme: .paper),
        language: AppLanguage = .english
    ) -> UIImage? {
        let view = ShareCardView(post: post, config: config, language: language)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.5
        return renderer.uiImage
    }

    static func shareCaption(for post: Post, language: AppLanguage) -> String {
        let title = post.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty {
            return omakaseURL.absoluteString
        }
        return "\(title)\n\(omakaseURL.absoluteString)"
    }

    static func shareToInstagramStories(
        post: Post,
        config: ShareCardConfig,
        language: AppLanguage,
        onShareCompleted: (() -> Void)? = nil
    ) -> ShareActionResult {
        guard let image = renderCardImage(for: post, config: config, language: language),
              let pngData = image.pngData() else {
            return .failed
        }

        guard let storyURL = URL(string: "instagram-stories://share?source_application=kuzeysinay.omakase"),
              UIApplication.shared.canOpenURL(storyURL) else {
            presentShareSheet(post: post, config: config, language: language, onShareCompleted: onShareCompleted)
            return .fallbackSheet
        }

        let pasteboardItems: [[String: Any]] = [[
            "com.instagram.sharedSticker.backgroundImage": pngData,
            "com.instagram.sharedSticker.contentURL": omakaseURL.absoluteString
        ]]
        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(300)
        ]
        UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)
        UIApplication.shared.open(storyURL, options: [:], completionHandler: nil)
        onShareCompleted?()
        return .openedApp
    }

    static func shareToWhatsApp(
        post: Post,
        config: ShareCardConfig,
        language: AppLanguage,
        onShareCompleted: (() -> Void)? = nil
    ) -> ShareActionResult {
        guard renderCardImage(for: post, config: config, language: language) != nil else {
            return .failed
        }
        presentShareSheet(post: post, config: config, language: language, onShareCompleted: onShareCompleted)
        return .fallbackSheet
    }

    static func shareToX(
        post: Post,
        config: ShareCardConfig,
        language: AppLanguage,
        onShareCompleted: (() -> Void)? = nil
    ) -> ShareActionResult {
        guard renderCardImage(for: post, config: config, language: language) != nil else {
            return .failed
        }
        presentShareSheet(post: post, config: config, language: language, onShareCompleted: onShareCompleted)
        return .fallbackSheet
    }

    static func saveToPhotos(
        post: Post,
        config: ShareCardConfig,
        language: AppLanguage,
        onShareCompleted: (() -> Void)? = nil
    ) async -> Bool {
        guard let image = renderCardImage(for: post, config: config, language: language) else {
            return false
        }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            return false
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            onShareCompleted?()
            return true
        } catch {
            return false
        }
    }

    static func copyImageToClipboard(
        post: Post,
        config: ShareCardConfig,
        language: AppLanguage
    ) -> Bool {
        guard let image = renderCardImage(for: post, config: config, language: language) else {
            return false
        }
        UIPasteboard.general.image = image
        return true
    }

    static func presentShareSheet(
        post: Post,
        config: ShareCardConfig = ShareCardConfig(theme: .paper),
        language: AppLanguage = .english,
        onShareCompleted: (() -> Void)? = nil
    ) {
        guard let image = renderCardImage(for: post, config: config, language: language) else { return }

        let itemSource = ShareItemSource(post: post, image: image)
        let caption = shareCaption(for: post, language: language)
        let activityVC = UIActivityViewController(
            activityItems: [itemSource, caption],
            applicationActivities: nil
        )
        activityVC.completionWithItemsHandler = { _, completed, _, _ in
            guard completed else { return }
            Task { @MainActor in
                onShareCompleted?()
            }
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                ?? windowScene.windows.first?.rootViewController
        else { return }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        topVC.present(activityVC, animated: true)
    }
}
