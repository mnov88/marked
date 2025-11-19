import Foundation

extension String {
    /// Ensure string has markdown extension (.md or .markdown)
    /// Maps to web app's ensureMarkdownExtension() in lib/documents.ts
    func ensureMarkdownExtension() -> String {
        if hasSuffix(".md") || hasSuffix(".markdown") {
            return self
        }
        return "\(self).md"
    }

    /// Remove markdown extension
    func removeMarkdownExtension() -> String {
        if hasSuffix(".md") {
            return String(dropLast(3))
        } else if hasSuffix(".markdown") {
            return String(dropLast(9))
        }
        return self
    }

    /// Sanitize filename by removing invalid characters
    func sanitizedFilename() -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return components(separatedBy: invalidCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Truncate string to specified length with ellipsis
    func truncated(toLength length: Int, addEllipsis: Bool = true) -> String {
        guard count > length else { return self }
        let endIndex = index(startIndex, offsetBy: length)
        let truncated = String(self[..<endIndex])
        return addEllipsis ? truncated + "..." : truncated
    }

    /// Extract title from markdown content (first heading or first line)
    func extractMarkdownTitle() -> String? {
        let lines = components(separatedBy: .newlines)

        // Look for first # heading
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.starts(with: "#") {
                return trimmed.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
            }
        }

        // Fall back to first non-empty line
        return lines.first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }?
            .truncated(toLength: 50)
    }

    /// Count words in string
    var wordCount: Int {
        let words = components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    /// Estimated reading time in minutes (assuming 200 words per minute)
    var estimatedReadingTime: Int {
        max(1, wordCount / 200)
    }

    /// Check if string is valid URL
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil && url.host != nil
    }
}

// MARK: - Range Conversions
extension String {
    /// Convert NSRange to Swift Range
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
        else {
            return nil
        }
        return from..<to
    }

    /// Convert Swift Range to NSRange
    func nsRange(from range: Range<String.Index>) -> NSRange {
        let from = range.lowerBound
        let to = range.upperBound
        let location = utf16.distance(from: utf16.startIndex, to: from.samePosition(in: utf16)!)
        let length = utf16.distance(from: from.samePosition(in: utf16)!, to: to.samePosition(in: utf16)!)
        return NSRange(location: location, length: length)
    }

    /// Extract substring using NSRange
    func substring(with nsRange: NSRange) -> String? {
        guard let range = Range(nsRange, in: self) else {
            return nil
        }
        return String(self[range])
    }
}

// MARK: - Validation
extension String {
    /// Check if string contains only whitespace
    var isWhitespace: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Check if string is valid email
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }
}
