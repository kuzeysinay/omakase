//
//  ContentModerationService.swift
//  omakase
//
//  Client-side content moderation to prevent inappropriate, adult, abusive, or harmful
//  user-generated content (interests, display names, @usernames, and comments) from being posted.
//

import Foundation

enum ContentModerationService {

    /// Comprehensive pattern covering inappropriate, adult, violent, abusive, hate speech, and illegal content (EN & TR).
    private static let pattern: String = #"(?i)\b("#
        // Adult / NSFW / Sexual (EN & TR stems)
        + #"porn\w*|porno\w*|hentai|xxx|nsfw|nude\w*|naked|sext\w*|erotik\w*|erotic\w*|"#
        + #"seks\w*|sex\w*|cinsel\w*|masturbat\w*|mastürbat\w*|orgasm\w*|vajina|penis|"#
        // Profanity / Harassment / Abuse / Hate Speech (EN & TR)
        + #"fuck\w*|shit\w*|bitch\w*|asshole\w*|bastard\w*|whore\w*|slut\w*|cunt\w*|dickhead\w*|"#
        + #"nigger\w*|nigga\w*|faggot\w*|retard\w*|kys|"#
        + #"amk|aq|sikik\w*|sikeyim\w*|sikerim\w*|siktir\w*|orospu\w*|piç\w*|piclik\w*|"#
        + #"yavşak\w*|yavsak\w*|götveren\w*|gotveren\w*|kahpe\w*|pezevenk\w*|ibne\w*|"#
        // Violence / Abuse / Illegal (EN & TR)
        + #"child\s*abuse|cocuk\s*istismar\w*|çocuk\s*istismar\w*|pedofil\w*|pedophil\w*|"#
        + #"rape|tecavuz\w*|tecavüz\w*|snuff|murder\s*tutorial|cinayet\s*egitim\w*|"#
        + #"kill\s*(?:my|your)?self|intihar\w*|suicide\w*|"#
        + #"bomb\s*making|bomba\s*yap\w*|terrorist|terör\w*|teror\w*|"#
        + #"drug\s*deal|uyusturucu\w*|uyuşturucu\w*|kokain\w*|eroin\w*|meth\w*|"#
        + #"buy\s*(?:guns?|weapons?)|silah\s*sat\w*|"#
        + #"hack\s*(?:into|account|password)|hesap\s*cal\w*|hesap\s*çal\w*|"#
        + #"kumar|bahis|betting|casino"#
        + #")\b"#

    private static let regex: NSRegularExpression? = try? NSRegularExpression(pattern: pattern)

    /// Returns `true` if the candidate string is safe and clean to use.
    static func isAppropriate(_ text: String, maxLength: Int = 100) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard trimmed.count <= maxLength else { return false }
        guard let regex = regex else { return true }
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        return regex.firstMatch(in: trimmed, range: range) == nil
    }

    /// Filters out any inappropriate items from a list of strings.
    static func filterAppropriate(_ list: [String]) -> [String] {
        list.filter { isAppropriate($0) }
    }
}
