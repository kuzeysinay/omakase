//
//  Post.swift
//  omakase
//

import Foundation
import Observation

/// A single AI-generated post in the feed. `text` grows over time as SSE
/// tokens stream in, and `isComplete` flips to true when the `done` event
/// arrives.
///
/// Uses `@Observable` so SwiftUI can track per-property mutations without
/// needing to copy the entire `posts` array on every SSE token — the key fix
/// for scroll-stuttering during streaming.
@Observable
final class Post: Identifiable, @unchecked Sendable {
    let id: UUID
    /// Short headline from the model (`TITLE:` line); may be empty until the first SSE `title` event.
    var title: String
    var text: String
    var isComplete: Bool
    /// User interests this post relates to, parsed from the model's `TAGS:` line.
    var tags: [String]
    /// Canonical main category ID (`InterestCategory.id`, e.g. "food", "science", "film").
    var categoryId: String?
    /// The format template used to generate this post (e.g. "DEBATE", "TIMELINE").
    var postFormat: String?
    /// Deep dive expansion text, if requested.
    var deepDiveText: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        text: String = "",
        isComplete: Bool = false,
        tags: [String] = [],
        categoryId: String? = nil,
        postFormat: String? = nil,
        deepDiveText: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.isComplete = isComplete
        self.tags = tags
        self.categoryId = categoryId
        self.postFormat = postFormat
        self.deepDiveText = deepDiveText
        self.createdAt = createdAt
    }

    /// Formatted display text with any legacy robotic template labels (e.g. "SIDE A:", "SIDE B:")
    /// and accidental LaTeX math notation removed.
    var cleanDisplayBody: String {
        Self.sanitizeTemplateLabels(from: text).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func sanitizeTemplateLabels(from rawText: String) -> String {
        var clean = rawText
        let patterns = [
            #"(?i)\*?\*?SIDE\s*A\s*:\*?\*?\s*"#,
            #"(?i)\*?\*?SIDE\s*B\s*:\*?\*?\s*"#,
            #"(?i)\*?\*?TARAF\s*A\s*:\*?\*?\s*"#,
            #"(?i)\*?\*?TARAF\s*B\s*:\*?\*?\s*"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                clean = regex.stringByReplacingMatches(
                    in: clean,
                    options: [],
                    range: NSRange(location: 0, length: clean.utf16.count),
                    withTemplate: ""
                )
            }
        }
        return sanitizeLaTeX(from: clean)
    }

    /// Converts raw LaTeX/TeX fragments (e.g. `($^{13}\text{C}$)`, `($^{13}text{C}$)`, `CO$_2$`)
    /// into clean Unicode prose (`(¹³C)`, `CO₂`).
    static func sanitizeLaTeX(from input: String) -> String {
        var s = input

        // 1. Strip inline math `$...$` when it contains TeX markers (^, _, \, {, }) or is inside ($...$)
        if let mathDollarRegex = try? NSRegularExpression(pattern: #"\$([^$\n]*?[\^_\\{}][^$\n]*?)\$"#) {
            s = mathDollarRegex.stringByReplacingMatches(
                in: s,
                range: NSRange(location: 0, length: s.utf16.count),
                withTemplate: "$1"
            )
        }
        if let parenDollarRegex = try? NSRegularExpression(pattern: #"\(\$([^$\n]{1,40})\$\)"#) {
            s = parenDollarRegex.stringByReplacingMatches(
                in: s,
                range: NSRange(location: 0, length: s.utf16.count),
                withTemplate: "($1)"
            )
        }

        // 2. Replace \frac{a}{b} or frac{a}{b} with a/b
        if let fracRegex = try? NSRegularExpression(pattern: #"\\?frac\{([^}]+)\}\{([^}]+)\}"#) {
            s = fracRegex.stringByReplacingMatches(
                in: s,
                range: NSRange(location: 0, length: s.utf16.count),
                withTemplate: "$1/$2"
            )
        }

        // 3. Unwrap \text{...}, text{...}, \mathrm{...}, \mathbf{...}, \mathit{...}
        if let textCmdRegex = try? NSRegularExpression(pattern: #"\\?(?:text|mathrm|mathbf|mathit|mathsf)\{([^}]*)\}"#) {
            s = textCmdRegex.stringByReplacingMatches(
                in: s,
                range: NSRange(location: 0, length: s.utf16.count),
                withTemplate: "$1"
            )
        }

        // 4. Common LaTeX symbols
        let symbolReplacements: [(String, String)] = [
            (#"\\times\b"#, "×"),
            (#"\\approx\b"#, "≈"),
            (#"\\pm\b"#, "±"),
            (#"\\cdot\b"#, "·"),
            (#"\\(?:circ|degree)\b"#, "°"),
            (#"\\alpha\b"#, "α"),
            (#"\\beta\b"#, "β"),
            (#"\\gamma\b"#, "γ"),
            (#"\\delta\b"#, "δ"),
            (#"\\Delta\b"#, "Δ"),
            (#"\\mu\b"#, "μ"),
            (#"\\pi\b"#, "π"),
            (#"\\sigma\b"#, "σ"),
            (#"\\omega\b"#, "ω"),
            (#"\\Omega\b"#, "Ω")
        ]
        for (pattern, replacement) in symbolReplacements {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                s = regex.stringByReplacingMatches(
                    in: s,
                    range: NSRange(location: 0, length: s.utf16.count),
                    withTemplate: replacement
                )
            }
        }

        // 5. Convert superscripts: ^{...} or ^x
        s = replaceScript(in: s, pattern: #"\^\{([^}]+)\}|\^([0-9+\-=()]+)"#, mapping: superscriptMap)

        // 6. Convert subscripts: _{...} or _x
        s = replaceScript(in: s, pattern: #"_\{([^}]+)\}|_([0-9+\-=()]+)"#, mapping: subscriptMap)

        // 7. Clean up any stray `$` left adjacent to Unicode scripts or braces
        if let strayDollar = try? NSRegularExpression(pattern: #"\$(?=[⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻₀₁₂₃₄₅₆₇₈₉])|(?<=[⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻₀₁₂₃₄₅₆₇₈₉])\$"#) {
            s = strayDollar.stringByReplacingMatches(
                in: s,
                range: NSRange(location: 0, length: s.utf16.count),
                withTemplate: ""
            )
        }

        return s
    }

    private static let superscriptMap: [Character: Character] = [
        "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
        "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
        "+": "⁺", "-": "⁻", "=": "⁼", "(": "⁽", ")": "⁾",
        "n": "ⁿ", "i": "ⁱ"
    ]

    private static let subscriptMap: [Character: Character] = [
        "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄",
        "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉",
        "+": "₊", "-": "₋", "=": "₌", "(": "₍", ")": "₎"
    ]

    private static func replaceScript(in input: String, pattern: String, mapping: [Character: Character]) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return input }
        let nsString = input as NSString
        let matches = regex.matches(in: input, range: NSRange(location: 0, length: nsString.length))
        guard !matches.isEmpty else { return input }

        let mutable = NSMutableString(string: input)
        for match in matches.reversed() {
            let contentRange = match.range(at: 1).location != NSNotFound ? match.range(at: 1) : match.range(at: 2)
            guard contentRange.location != NSNotFound else { continue }
            let inner = nsString.substring(with: contentRange)
            var converted = ""
            var allMapped = true
            for ch in inner {
                if let mapped = mapping[ch] {
                    converted.append(mapped)
                } else {
                    allMapped = false
                    break
                }
            }
            let replacement = allMapped ? converted : inner
            mutable.replaceCharacters(in: match.range, with: replacement)
        }
        return mutable as String
    }
}

extension Post: Equatable {
    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }
}
