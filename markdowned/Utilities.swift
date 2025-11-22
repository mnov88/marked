//
//  Utilities.swift
//  markdowned
//
//  Created by Milos Novovic on 10/11/2025.
//
import Foundation

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

extension UIColor {
    /// Convert this Color to a hexadecimal string (#RRGGBB)
    func toHex() -> String? {
        let uiColor = UIColor()
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

}
