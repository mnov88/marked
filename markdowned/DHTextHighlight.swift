//
//  DHTextHighlight.swift
//  markdowned
//
//  Created by Milos Novovic on 10/11/2025.
//

import SwiftUI
import Combine

// MARK: - Models

enum DHHighlightConstants {
    static let tagPrefix = "dh-highlight-"
}

struct DHTextHighlight: Identifiable, Equatable, Codable {
    let id: UUID
    let range: NSRange
    let color: PlatformColor

    init(id: UUID = UUID(), range: NSRange, color: PlatformColor) {
        self.id = id
        self.range = range
        self.color = color
    }

    // Equatable without relying on PlatformColor conformance
    static func == (lhs: DHTextHighlight, rhs: DHTextHighlight) -> Bool {
        lhs.id == rhs.id && lhs.range == rhs.range && lhs.color.rgba == rhs.color.rgba
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, location, length, colorHex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let location = try container.decode(Int.self, forKey: .location)
        let length = try container.decode(Int.self, forKey: .length)
        range = NSRange(location: location, length: length)
        let colorHex = try container.decode(String.self, forKey: .colorHex)
        color = PlatformColor(hex: colorHex) ?? .systemYellow
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(range.location, forKey: .location)
        try container.encode(range.length, forKey: .length)
        try container.encode(color.hexString, forKey: .colorHex)
    }

    /// Produce a copy with leading/trailing whitespace & newlines excluded from the range.
    func trimmed(in text: NSString? = nil) -> DHTextHighlight {
        guard let text else { return self }
        let charset = CharacterSet.whitespacesAndNewlines
        var start = range.location
        var end = range.location + range.length

        while start < end {
            let scalar = UnicodeScalar(text.character(at: start))
            if let scalar, charset.contains(scalar) { start += 1 } else { break }
        }
        while end > start {
            let scalar = UnicodeScalar(text.character(at: end - 1))
            if let scalar, charset.contains(scalar) { end -= 1 } else { break }
        }
        let newLength = end - start
        guard newLength > 0 else { return self }
        return DHTextHighlight(id: id, range: NSRange(location: start, length: newLength), color: color)
    }
}

struct DHLinkSpan: Identifiable, Equatable {
    let id: UUID
    let range: NSRange
    let url: URL // use .link with a custom scheme
}

struct DHIndentSpan: Identifiable, Equatable {
    let id: UUID
    let range: NSRange
    let headIndent: CGFloat
    let tailIndent: CGFloat
    let firstLineHeadIndent: CGFloat
}

struct DHHeadingSpan: Identifiable, Equatable {
    enum Level {
        case h2
        case h3
    }

    let id: UUID
    let range: NSRange
    let level: Level
}

// MARK: - Configuration

struct DHStyle {
    var font: PlatformFont = .preferredFont(forTextStyle: .body)
    var textColor: PlatformColor = .label
    var backgroundColor: PlatformColor = .systemBackground
    var lineHeightMultiple: CGFloat = 1.2
    var paragraphSpacing: CGFloat = 4
    var alignment: NSTextAlignment = .left
    var contentInsets: PlatformEdgeInsets = .init(top: 24, left: 16, bottom: 24, right: 16)
    var lineBreakStrategy: NSParagraphStyle.LineBreakStrategy = [.hangulWordPriority, .pushOut]

    // Page layout settings - horizontal insets calculated from available width
    var pageLayoutMaxWidth: CGFloat = 700  // Maximum content width in page layout mode
    var horizontalMargin: HorizontalMargin = .medium

    enum HorizontalMargin: String, Codable, CaseIterable {
        case extraNarrow = "Extra Narrow"
        case narrow = "Narrow"
        case medium = "Medium"
        case wide = "Wide"
        case extraWide = "Extra Wide"

        var baseInset: CGFloat {
            switch self {
            case .extraNarrow: return 12
            case .narrow: return 16
            case .medium: return 24
            case .wide: return 40
            case .extraWide: return 52
            }
        }

        var maxContentWidth: CGFloat {
            switch self {
            case .extraNarrow: return 840
            case .narrow: return 780
            case .medium: return 700
            case .wide: return 620
            case .extraWide: return 560
            }
        }
    }
}

struct DHConfig {
    var style = DHStyle()
    var enableLinks = true
    var enableIndentation = true
    var usePageLayout = false

    // Rule providers
    var linkDetector: ((NSString) -> [DHLinkSpan])? = DHConfig.defaultArticleLinks
    var indentationComputer: ((NSString) -> [DHIndentSpan])? = DHConfig.defaultIndentation
    var headingDetector: ((NSString) -> [DHHeadingSpan])? = DHConfig.defaultHeadings

    // Build "dh://article/<n>" links using .link attribute
    nonisolated static func defaultArticleLinks(_ s: NSString) -> [DHLinkSpan] {
        let pattern = #"Article\s+(\d+)"#
        guard let re = try? NSRegularExpression(pattern: pattern) else { return [] }
        let full = NSRange(location: 0, length: s.length)
        return re.matches(in: s as String, range: full).compactMap { m in
            let nStr = s.substring(with: m.range(at: 1))
            guard let url = URL(string: "dh://article/\(nStr)") else { return nil }
            return DHLinkSpan(id: UUID(), range: m.range, url: url)
        }
    }

    // Simple multilevel list indentation
    nonisolated static func defaultIndentation(_ s: NSString) -> [DHIndentSpan] {
        var spans: [DHIndentSpan] = []
        let base: CGFloat = 20
        let re1 = try? NSRegularExpression(pattern: #"^\s*\d+\."#, options: [.anchorsMatchLines])
        let re2 = try? NSRegularExpression(pattern: #"^\s*\([a-zA-Z]\)"#, options: [.anchorsMatchLines])
        let re3 = try? NSRegularExpression(pattern: #"^\s*\([ivxlcdmIVXLCDM]+\)"#, options: [.anchorsMatchLines])

        for pr in s.paragraphRanges() {
            let p = s.substring(with: pr) as NSString
            let level: Int
            if re1?.firstMatch(in: p as String, range: NSRange(location: 0, length: p.length)) != nil {
                level = 0
            } else if re2?.firstMatch(in: p as String, range: NSRange(location: 0, length: p.length)) != nil {
                level = 1
            } else if re3?.firstMatch(in: p as String, range: NSRange(location: 0, length: p.length)) != nil {
                level = 2
            } else if p.trimmingCharacters(in: .whitespaces).hasPrefix("–")
                        || p.trimmingCharacters(in: .whitespaces).hasPrefix("—")
                        || p.trimmingCharacters(in: .whitespaces).hasPrefix("•") {
                level = 3
            } else { level = 0 }

            let indent = CGFloat(level) * base + base
            spans.append(DHIndentSpan(
                id: UUID(),
                range: pr,
                headIndent: indent,
                tailIndent: -indent,      // symmetric margin
                firstLineHeadIndent: indent
            ))
        }
        return spans
    }

    // Heading detection inspired by future-features/regex-cleanup/legal-md-formatter.js
    nonisolated static func defaultHeadings(_ s: NSString) -> [DHHeadingSpan] {
        var spans: [DHHeadingSpan] = []
        let full = NSRange(location: 0, length: s.length)

        let specialSections: [String: DHHeadingSpan.Level] = [
            "JUDGMENT OF THE COURT": .h2,
            "ORDER OF THE COURT": .h2,
            "OPINION OF ADVOCATE GENERAL": .h2,
            "Costs": .h3,
            "Procedure": .h3,
            "Legal context": .h3,
            "Background to the dispute": .h3,
            "Forms of order sought": .h3,
            "The dispute": .h3,
            "Admissibility": .h3,
            "The main proceedings": .h3,
            "The questions referred": .h3,
            "Consideration of the questions referred": .h3
        ]

        let ordinal = "(?:first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth)"

        let generalHeadingPatterns: [NSRegularExpression] = [
            try? NSRegularExpression(pattern: #"^\[[^\]]+\]$"#, options: []), // [Text rectified ...]
            try? NSRegularExpression(pattern: #"^ORDER OF THE COURT(?: \([^)]+\))?$"#, options: [.caseInsensitive]),
            try? NSRegularExpression(pattern: #"^(Judgment|Order)$"#, options: [.caseInsensitive]),
            try? NSRegularExpression(pattern: #"^On those grounds,? the Court.*$"#, options: [.caseInsensitive])
        ].compactMap { $0 }

        let questionPatterns: [NSRegularExpression] = [
            try? NSRegularExpression(pattern: #"^Questions?\s+\d+(?:\s+to\s+\d+)?$"#, options: [.caseInsensitive]),
            try? NSRegularExpression(pattern: #"^The\s+\d+[a-z]{2}\s+question$"#, options: [.caseInsensitive]),
            try? NSRegularExpression(pattern: #"^The questions? referred(?: for a preliminary ruling)?$"#, options: [.caseInsensitive]),
            try? NSRegularExpression(pattern: #"^Question referred for a preliminary ruling$"#, options: [.caseInsensitive]),
            try? NSRegularExpression(pattern: #"^(?:On the\s+|The\s+)?(?:first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth)(?:\s+(?:and|to)\s+(?:first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth))*\s+questions?$"#, options: [.caseInsensitive]),
            try? NSRegularExpression(pattern: #"^The\s+(?:first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth)\s+part of the\s+(?:first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth)\s+question$"#, options: [.caseInsensitive])
        ].compactMap { $0 }

        s.enumerateSubstrings(in: full, options: [.byParagraphs]) { substring, subRange, _, _ in
            guard let substring else { return }
            let trimmed = substring.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            if let level = specialSections[trimmed] {
                if let r = trimmedRange(in: subRange, substring: substring) {
                    spans.append(DHHeadingSpan(id: UUID(), range: r, level: level))
                }
                return
            }

            if generalHeadingPatterns.contains(where: { regex in
                let range = NSRange(location: 0, length: (trimmed as NSString).length)
                return regex.firstMatch(in: trimmed, options: [], range: range) != nil
            }) {
                if let r = trimmedRange(in: subRange, substring: substring) {
                    spans.append(DHHeadingSpan(id: UUID(), range: r, level: .h2))
                }
                return
            }

            if questionPatterns.contains(where: { regex in
                let range = NSRange(location: 0, length: (trimmed as NSString).length)
                return regex.firstMatch(in: trimmed, options: [], range: range) != nil
            }) {
                if let r = trimmedRange(in: subRange, substring: substring) {
                    spans.append(DHHeadingSpan(id: UUID(), range: r, level: .h3))
                }
                return
            }

            if trimmed.lowercased().hasSuffix("hereby rules:") {
                if let r = trimmedRange(in: subRange, substring: substring) {
                    spans.append(DHHeadingSpan(id: UUID(), range: r, level: .h3))
                }
                return
            }

            if trimmed == trimmed.uppercased(), trimmed.count > 5 {
                if let r = trimmedRange(in: subRange, substring: substring) {
                    spans.append(DHHeadingSpan(id: UUID(), range: r, level: .h2))
                }
            }
        }

        return spans
    }

    /// Trim leading/trailing whitespace inside a paragraph range to align styling to visible text
    private nonisolated static func trimmedRange(in paragraphRange: NSRange, substring: String) -> NSRange? {
        let paragraphNSString = substring as NSString
        let charset = CharacterSet.whitespacesAndNewlines

        var start = 0
        var end = paragraphNSString.length

        while start < end {
            let scalar = UnicodeScalar(paragraphNSString.character(at: start))
            if let scalar, charset.contains(scalar) {
                start += 1
            } else {
                break
            }
        }

        while end > start {
            let scalar = UnicodeScalar(paragraphNSString.character(at: end - 1))
            if let scalar, charset.contains(scalar) {
                end -= 1
            } else {
                break
            }
        }

        let length = end - start
        guard length > 0 else { return nil }

        return NSRange(location: paragraphRange.location + start, length: length)
    }
}
