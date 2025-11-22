//
//  Utilities.swift
//  markdowned
//
//  Created by Milos Novovic on 10/11/2025.
//
import Foundation

// MARK: - Snippet Extraction (shared utility for DRY)

/// Shared utility for extracting text snippets from documents
/// Used by CompositionsManager and AllHighlightsView
enum SnippetExtractor {
    /// Extract a snippet of text for a highlight from a document
    /// - Parameters:
    ///   - highlight: The highlight to extract text for
    ///   - document: The document containing the highlighted text
    ///   - maxLength: Maximum length of the snippet (default 200)
    /// - Returns: The extracted text snippet, truncated if necessary
    static func extract(for highlight: DHTextHighlight, in document: Document, maxLength: Int = 200) -> String {
        let text = document.textContent
        let nsString = text as NSString

        guard highlight.range.location >= 0,
              highlight.range.location + highlight.range.length <= nsString.length else {
            return ""
        }

        let snippet = nsString.substring(with: highlight.range)
        if snippet.count > maxLength {
            return String(snippet.prefix(maxLength)) + "…"
        }
        return snippet
    }

    /// Extract a snippet with surrounding context and markers
    /// - Parameters:
    ///   - highlight: The highlight to extract text for
    ///   - document: The document containing the highlighted text
    ///   - context: Number of characters of context on each side
    /// - Returns: The snippet with «» markers around the highlighted portion
    static func extractWithContext(for highlight: DHTextHighlight, in document: Document, context: Int = 40) -> String {
        let text = document.textContent
        let nsString = text as NSString

        guard highlight.range.location >= 0,
              highlight.range.location + highlight.range.length <= nsString.length else {
            return ""
        }

        guard let textRange = Range(highlight.range, in: text) else { return "" }

        let startUTF16 = text.utf16.index(
            text.utf16.startIndex,
            offsetBy: max(highlight.range.location - context, 0),
            limitedBy: text.utf16.endIndex
        ) ?? text.utf16.startIndex

        let endUTF16 = text.utf16.index(
            text.utf16.startIndex,
            offsetBy: min(highlight.range.location + highlight.range.length + context, text.utf16.count),
            limitedBy: text.utf16.endIndex
        ) ?? text.utf16.endIndex

        let start = String.Index(startUTF16, within: text) ?? text.startIndex
        let end = String.Index(endUTF16, within: text) ?? text.endIndex
        var window = String(text[start..<end])

        // Mark the highlighted segment within the window
        if let local = window.range(of: String(text[textRange])) {
            window.replaceSubrange(local.upperBound..<local.upperBound, with: "»")
            window.replaceSubrange(local.lowerBound..<local.lowerBound, with: "«")
        }
        return window
    }
}

// MARK: - Document Extension for Text Content

extension Document {
    /// Get the plain text content of the document
    var textContent: String {
        switch content {
        case .plain(let s):
            return s
        case .attributed(let a):
            return a.string
        }
    }
}

// MARK: - Shared Configuration Builder (DRY)

/// Extension on ThemeManager to create DHConfig
/// Used by DocumentsListView, AllHighlightsView, and other document viewing contexts
extension ThemeManager {
    /// Build a DHConfig from the current theme settings
    func makeDocumentConfig() -> DHConfig {
        var config = DHConfig()
        config.style = currentTheme.toDHStyle()
        config.usePageLayout = currentTheme.usePageLayout
        return config
    }
}

// MARK: - Safe UUID Parsing (DRY - avoiding force unwraps)

extension String {
    /// Safely parse as UUID, returning nil if invalid
    var uuid: UUID? {
        UUID(uuidString: self)
    }
}

/// Custom error for database operations
struct DatabaseError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// MARK: - App Error Types (consolidated error handling)

/// Unified error type for app operations
enum AppError: LocalizedError {
    case database(String)
    case network(String)
    case invalidData(String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .database(let message):
            return "Database Error: \(message)"
        case .network(let message):
            return "Network Error: \(message)"
        case .invalidData(let message):
            return "Invalid Data: \(message)"
        case .unknown(let error):
            return "Error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .database:
            return "Try restarting the app. If the problem persists, contact support."
        case .network:
            return "Check your internet connection and try again."
        case .invalidData:
            return "The data may be corrupted. Try removing and re-adding the item."
        case .unknown:
            return "Please try again."
        }
    }
}

// MARK: - Helpers (consolidated)

// Lorem generator for demos
enum LoremGen {
    // Deterministic RNG for reproducibility
    private struct LCG {
        var state: UInt64
        mutating func next() -> UInt64 { state = state &* 6364136223846793005 &+ 1; return state }
        mutating func int(_ upper: Int) -> Int { Int(next() % UInt64(upper)) }
        mutating func inRange(_ lower: Int, _ upper: Int) -> Int { lower + int(max(1, upper - lower)) }
    }

    private static let words: [String] = """
    lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore
    et dolore magna aliqua ut enim ad minim veniam quis nostrud exercitation ullamco laboris nisi ut
    aliquip ex ea commodo consequat duis aute irure dolor in reprehenderit in voluptate velit esse
    cillum dolore eu fugiat nulla pariatur excepteur sint occaecat cupidatat non proident sunt in culpa
    qui officia deserunt mollit anim id est laborum regulation directive article recital provider service
    market competition consumer protection transparency proportionality necessity subsidiarity paragraph
    annex annexes competent authority procedure enforcement compliance interpretation judgement order
    """.split(separator: " ").map(String.init)

    // Plain lorem: paragraphs × ~avgWords, deterministic by seed
    static func plain(paragraphs: Int, avgWords: Int = 120, seed: UInt64 = 1) -> String {
        var rng = LCG(state: max(1, seed))
        var out = String()
        out.reserveCapacity(paragraphs * avgWords * 6)
        for p in 0..<max(1, paragraphs) {
            let wc = max(12, rng.inRange(Int(Double(avgWords) * 7/10), Int(Double(avgWords) * 13/10)))
            for i in 0..<wc {
                let w = words[rng.int(words.count)]
                if i == 0 { out.append(w.capitalized) } else { out.append(w) }
                out.append(i == wc - 1 ? "." : (i % 15 == 14 ? ", " : " "))
            }
            if p < paragraphs - 1 { out.append("\n\n") }
        }
        return out
    }

    // Legal-ish lorem with headings and lists to exercise link/indent
    static func legalish(articles: Int = 20, sectionsPerArticle: Int = 3, pointsPerSection: Int = 4, seed: UInt64 = 2) -> String {
        var rng = LCG(state: max(1, seed))
        var out = String()
        out.reserveCapacity(articles * sectionsPerArticle * pointsPerSection * 100)
        for a in 1...max(1, articles) {
            out.append("Article \(a)\n\n")
            for s in 1...max(1, sectionsPerArticle) {
                out.append("\(s). "); out.append(sentence(words: &rng, min: 12, max: 22)); out.append("\n")
                let letter = Character(UnicodeScalar(97 + (s - 1) % 26)!)
                out.append("(\(letter)) "); out.append(sentence(words: &rng, min: 10, max: 18)); out.append("\n")
                out.append("(i) "); out.append(sentence(words: &rng, min: 8, max: 16)); out.append("\n")
                for _ in 0..<max(1, pointsPerSection) {
                    out.append("• "); out.append(sentence(words: &rng, min: 8, max: 14)); out.append("\n")
                }
                if a > 1 && rng.int(3) == 0 {
                    out.append("See Article \(rng.inRange(1, a)).\n")
                }
                out.append("\n")
            }
        }
        return out
    }

    // Build a large string quickly by doubling then trimming
    static func approximateCharacters(_ targetChars: Int, baseParagraphs: Int = 12, seed: UInt64 = 3) -> String {
        precondition(targetChars > 0)
        var s = plain(paragraphs: max(1, baseParagraphs), avgWords: 120, seed: seed) + "\n\n" + legalish(articles: 4, seed: seed &* 97)
        while s.count < targetChars { s += s }
        if s.count == targetChars { return s }
        let end = s.index(s.startIndex, offsetBy: targetChars)
        return String(s[..<end])
    }

    private static func sentence(words rng: inout LCG, min: Int, max: Int) -> String {
        let n = rng.inRange(min, max)
        var s = ""
        for i in 0..<n {
            var w = words[rng.int(words.count)]
            if i == 0 { w = w.capitalized }
            s += w
            s += i == n - 1 ? "." : (i % 10 == 9 ? ", " : " ")
        }
        return s
    }
}

// Note: UIColor/NSColor extensions moved to CrossPlatform.swift for cross-platform compatibility

extension NSRange {
    /// Returns self if it fits inside `stringLength`, else nil.
    func clamped(toStringLength stringLength: Int) -> NSRange? {
        guard location >= 0, length >= 0 else { return nil }
        let end = location + length
        guard end <= stringLength else { return nil }
        return self
    }
}

extension NSString {
    nonisolated func paragraphRanges() -> [NSRange] {
        var ranges: [NSRange] = []
        var pos = 0
        while pos < length {
            let r = lineRange(for: NSRange(location: pos, length: 0))
            ranges.append(r)
            pos = r.location + r.length
        }
        return ranges
    }
}

// Note: UIColor.toHex() is defined in CrossPlatform.swift to avoid duplication
