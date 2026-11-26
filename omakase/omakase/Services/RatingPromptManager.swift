//
//  RatingPromptManager.swift
//  omakase
//
//  Requests native App Store ratings strictly via StoreKit's AppStore.requestReview(in:)
//  at natural completed-reading milestones (App Review Guidelines 5.6.1 & 5.6.3).
//  Never displays a custom satisfaction gate and never triggers from a button tap.
//

import Foundation
import StoreKit
import UIKit

@MainActor
final class RatingPromptManager {

    static let shared = RatingPromptManager()

    private enum Keys {
        static let completedReads = "omakase.rating.completedReads"
        static let lastPromptedVersion = "omakase.rating.lastPromptedVersion"
        static let lastPromptDate = "omakase.rating.lastPromptDate"
    }

    private let defaults = UserDefaults.standard
    private let minimumDaysBetweenPrompts: TimeInterval = 60 * 24 * 60 * 60

    private init() {}

    func recordCompletedRead() {
        let next = defaults.integer(forKey: Keys.completedReads) + 1
        defaults.set(next, forKey: Keys.completedReads)
    }

    func considerPromptingIfEligible(minReads: Int = 3) {
        let args = ProcessInfo.processInfo.arguments
        guard !args.contains("-UITestRoute"),
              !args.contains("-ScreenshotScene") else {
            return
        }

        let completedReads = defaults.integer(forKey: Keys.completedReads)
        guard completedReads >= minReads else { return }

        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        if defaults.string(forKey: Keys.lastPromptedVersion) == currentVersion {
            return
        }

        if let lastDate = defaults.object(forKey: Keys.lastPromptDate) as? Date,
           Date().timeIntervalSince(lastDate) < minimumDaysBetweenPrompts {
            return
        }

        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }

        defaults.set(currentVersion, forKey: Keys.lastPromptedVersion)
        defaults.set(Date(), forKey: Keys.lastPromptDate)
        TelemetryService.shared.track("review_prompt_requested")

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            guard scene.activationState == .foregroundActive else { return }
            StoreKit.AppStore.requestReview(in: scene)
        }
    }
}
