//
//  DHTextHighlight.swift
//  markdowned
//
//  Created by Milos Novovic on 10/11/2025.
//

import SwiftUI
import UIKit
import Combine

// MARK: - Models

struct DHTextHighlight: Identifiable, Equatable, Codable {
    let id: UUID
    let range: NSRange
    let color: UIColor

    init(id: UUID = UUID(), range: NSRange, color: UIColor) {
        self.id = id
        self.range = range
        self.color = color
    }

    // Equatable without relying on UIColor conformance
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
        color = UIColor(hex: colorHex) ?? .systemYellow
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(range.location, forKey: .location)
        try container.encode(range.length, forKey: .length)
        try container.encode(color.hexString, forKey: .colorHex)
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

// MARK: - Configuration

struct DHStyle {
    var font: UIFont = .preferredFont(forTextStyle: .body)
    var textColor: UIColor = .label
    var backgroundColor: UIColor = .systemBackground
    var lineHeightMultiple: CGFloat = 1.2
    var paragraphSpacing: CGFloat = 4
    var alignment: NSTextAlignment = .left
    var contentInsets: UIEdgeInsets = .init(top: 24, left: 16, bottom: 24, right: 16)
    var lineBreakStrategy: NSParagraphStyle.LineBreakStrategy = [.hangulWordPriority, .pushOut]
}

struct DHConfig {
    var style = DHStyle()
    var enableLinks = true
    var enableIndentation = true
    var usePageLayout = false

    // Rule providers
    var linkDetector: ((NSString) -> [DHLinkSpan])? = DHConfig.defaultArticleLinks
    var indentationComputer: ((NSString) -> [DHIndentSpan])? = DHConfig.defaultIndentation

    // Build "dh://article/<n>" links using .link attribute
    static func defaultArticleLinks(_ s: NSString) -> [DHLinkSpan] {
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
    static func defaultIndentation(_ s: NSString) -> [DHIndentSpan] {
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
}
