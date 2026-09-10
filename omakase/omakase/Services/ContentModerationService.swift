//
//  ContentModerationService.swift
//  omakase
//
//  Client-side content moderation to prevent inappropriate, adult, or harmful
//  interests from being added locally.
//

import Foundation

enum ContentModerationService {

    /// Comprehensive pattern covering inappropriate, adult, violent, illegal and dangerous content (EN & TR).
    private static let pattern: String = #"(?i)\b("#
        // Adult / NSFW / Sexual (EN & TR stems)
        + #"porn\w*|porno\w*|hentai|xxx|nsfw|nude\w*|naked|sext\w*|erotik\w*|erotic\w*|"#
        + #"seks\w*|sex\w*|cinsel\w*|masturbat\w*|mastürbat\w*|orgasm\w*|vajina|penis|"#
        // Violence / Abuse / Illegal (EN & TR)
        + #"child\s*abuse|cocuk\s*istismar\w*|çocuk\s*istismar\w*|pedofil\w*|pedophil\w*|"#
        + #"rape|tecavuz\w*|tecavüz\w*|snuff|murder\s*tutorial|cinayet\s*egitim\w*|"#
        + #"kill\s*(?:my)?self|intihar\w*|suicide\w*|"#
        + #"bomb\s*making|bomba\s*yap\w*|terrorist|terör\w*|teror\w*|"#
        + #"drug\s*deal|uyusturucu\w*|uyuşturucu\w*|kokain\w*|eroin\w*|meth\w*|"#
        + #"buy\s*(?:guns?|weapons?)|silah\s*sat\w*|"#
        + #"hack\s*(?:into|account|password)|hesap\s*cal\w*|hesap\s*çal\w*|"#
        + #"kumar|bahis|betting|casino"#
        + #")\b"#

    private static let regex: NSRegularExpression? = try? NSRegularExpression(pattern: pattern)

    /// Returns `true` if the candidate interest string is safe and clean to use.
    static func isAppropriate(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard trimmed.count <= 100 else { return false }
        guard let regex = regex else { return true }
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        return regex.firstMatch(in: trimmed, range: range) == nil
    }

    /// Filters out any inappropriate items from a list of interests.
    static func filterAppropriate(_ list: [String]) -> [String] {
        list.filter { isAppropriate($0) }
    }
}
