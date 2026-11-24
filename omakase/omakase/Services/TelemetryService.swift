//
//  TelemetryService.swift
//  omakase
//
//  Lightweight non-tracking product event batcher & in-app user feedback client.
//

import FirebaseAuth
import Foundation
import UIKit

enum FeedbackCategory: String, CaseIterable, Identifiable, Sendable {
    case bug
    case idea
    case content
    case other

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .bug: return "ladybug"
        case .idea: return "lightbulb"
        case .content: return "text.quote"
        case .other: return "ellipsis.bubble"
        }
    }

    func title(l10n: L10n) -> String {
        switch self {
        case .bug: return l10n.feedbackCategoryBug
        case .idea: return l10n.feedbackCategoryIdea
        case .content: return l10n.feedbackCategoryContent
        case .other: return l10n.feedbackCategoryOther
        }
    }
}

private struct QueuedTelemetryEvent: Encodable, Sendable {
    let name: String
    let properties: [String: String]
    let timestamp: String
}

private struct TelemetryBatchPayload: Encodable, Sendable {
    let events: [QueuedTelemetryEvent]
    let appVersion: String
    let osVersion: String
    let language: String

    enum CodingKeys: String, CodingKey {
        case events
        case appVersion = "app_version"
        case osVersion = "os_version"
        case language
    }
}

private struct FeedbackSubmitPayload: Encodable, Sendable {
    let category: String
    let message: String
    let rating: Int?
    let appVersion: String
    let osVersion: String
    let deviceModel: String
    let language: String
    let screen: String

    enum CodingKeys: String, CodingKey {
        case category
        case message
        case rating
        case appVersion = "app_version"
        case osVersion = "os_version"
        case deviceModel = "device_model"
        case language
        case screen
    }
}

@MainActor
final class TelemetryService {

    static let shared = TelemetryService()

    private var buffer: [QueuedTelemetryEvent] = []
    private var scheduledFlushTask: Task<Void, Never>?
    private var isFlushing = false

    private let maxBatchSize = 8
    private let flushDelaySeconds: Double = 15.0

    private static let isoFormatter: ISO8601DateFormatter = {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt
    }()

    private nonisolated static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 20
        return URLSession(configuration: config)
    }()

    private init() {}

    static var appVersionString: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    static var osVersionString: String {
        "iOS \(UIDevice.current.systemVersion)"
    }

    static var deviceModelString: String {
        UIDevice.current.model
    }

    /// Record a non-tracking product interaction event. Safe to call anywhere on `@MainActor`.
    func track(_ name: String, properties: [String: String] = [:]) {
        guard Auth.auth().currentUser != nil else { return }
        let timestamp = Self.isoFormatter.string(from: Date())
        buffer.append(QueuedTelemetryEvent(name: name, properties: properties, timestamp: timestamp))

        if buffer.count >= maxBatchSize {
            scheduledFlushTask?.cancel()
            scheduledFlushTask = nil
            Task { [weak self] in
                await self?.flush()
            }
        } else if scheduledFlushTask == nil {
            scheduledFlushTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(self?.flushDelaySeconds ?? 15.0))
                guard !Task.isCancelled else { return }
                await self?.flush()
            }
        }
    }

    /// Immediately send buffered telemetry events to `POST /telemetry/events`.
    func flush() async {
        scheduledFlushTask?.cancel()
        scheduledFlushTask = nil

        guard !isFlushing, !buffer.isEmpty, Auth.auth().currentUser != nil else { return }

        let batch = Array(buffer.prefix(25))
        buffer.removeFirst(batch.count)
        isFlushing = true
        defer { isFlushing = false }

        let payload = TelemetryBatchPayload(
            events: batch,
            appVersion: Self.appVersionString,
            osVersion: Self.osVersionString,
            language: AppLanguage.resolved().rawValue
        )

        do {
            let bodyData = try JSONEncoder().encode(payload)
            let url = APITokenProvider.baseURL
                .appendingPathComponent("telemetry")
                .appendingPathComponent("events")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(Self.appVersionString, forHTTPHeaderField: "X-Omakase-App-Version")
            request.setValue(Self.osVersionString, forHTTPHeaderField: "X-Omakase-OS-Version")
            request.httpBody = bodyData

            let authed = await APITokenProvider.shared.authorizedRequest(request)
            let (_, response) = try await Self.session.data(for: authed)
            if let http = response as? HTTPURLResponse, http.statusCode >= 500 {
                // Re-queue transient server failure up to cap
                if buffer.count + batch.count <= 40 {
                    buffer.insert(contentsOf: batch, at: 0)
                }
            }
        } catch {
            // Re-queue on offline/network errors without blocking UI
            if buffer.count + batch.count <= 40 {
                buffer.insert(contentsOf: batch, at: 0)
            }
        }
    }

    /// Submit direct user feedback to `POST /feedback`.
    func submitFeedback(
        category: FeedbackCategory,
        message: String,
        rating: Int?,
        language: AppLanguage,
        screen: String
    ) async throws {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload = FeedbackSubmitPayload(
            category: category.rawValue,
            message: trimmed,
            rating: rating,
            appVersion: Self.appVersionString,
            osVersion: Self.osVersionString,
            deviceModel: Self.deviceModelString,
            language: language.rawValue,
            screen: screen
        )

        let bodyData = try JSONEncoder().encode(payload)
        let url = APITokenProvider.baseURL.appendingPathComponent("feedback")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        var authed = await APITokenProvider.shared.authorizedRequest(request)
        var (data, response) = try await Self.session.data(for: authed)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            authed = await APITokenProvider.shared.authorizedRequest(request, forceRefresh: true)
            (data, response) = try await Self.session.data(for: authed)
        }

        guard let http = response as? HTTPURLResponse else {
            throw OmakaseError.serverUnreachable
        }

        if !(200...299).contains(http.statusCode) {
            throw OmakaseError.fromHTTP(
                status: http.statusCode,
                data: data,
                retryAfterHeader: http.value(forHTTPHeaderField: "Retry-After")
            )
        }
    }
}
