//
//  ContentLoader.swift
//  markdowned
//
//  Created by Milos Novovic on 16/11/2025.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class ContentLoader {
    enum LoadError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case conversionFailed(Error)
        case emptyContent
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL format"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .conversionFailed(let error):
                return "Conversion failed: \(error.localizedDescription)"
            case .emptyContent:
                return "No content received from URL"
            }
        }
    }
    
    /// Load content from URL, convert HTML to Markdown, and return as Document
    func loadContent(from urlString: String, title: String? = nil) async throws -> Document {
        // Validate URL
        guard let url = URL(string: urlString) else {
            throw LoadError.invalidURL
        }
        
        // Fetch HTML content with proper headers
        let html: String
        do {
            var request = URLRequest(url: url)
            request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
            request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check if we got redirected and follow it
            if let httpResponse = response as? HTTPURLResponse,
               let location = httpResponse.allHeaderFields["Location"] as? String,
               let redirectURL = URL(string: location) {
                var redirectRequest = URLRequest(url: redirectURL)
                redirectRequest.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
                redirectRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
                
                let (redirectData, _) = try await URLSession.shared.data(for: redirectRequest)
                guard let htmlString = String(data: redirectData, encoding: .utf8) else {
                    throw LoadError.emptyContent
                }
                html = htmlString
            } else {
                guard let htmlString = String(data: data, encoding: .utf8) else {
                    throw LoadError.emptyContent
                }
                html = htmlString
            }
        } catch {
            throw LoadError.networkError(error)
        }
        
        // Preprocess HTML (promote heading classes) and convert to NSAttributedString using native iOS rendering
        let attributedString: NSAttributedString
        do {
            let promotedHTML = promoteHeadingClasses(in: html)
            guard let data = promotedHTML.data(using: .utf8) else {
                throw LoadError.conversionFailed(NSError(domain: "ContentLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode HTML as UTF-8"]))
            }
            
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
        } catch {
            throw LoadError.conversionFailed(error)
        }
        
        // Extract plain text and post-process to clean up list markers
        let plainText = attributedString.string
        let processedText = postProcessText(plainText)
        
        // Use provided title or extract from HTML (use host + path as fallback)
        let documentTitle = title ?? extractTitle(from: html) ?? url.host ?? urlString
        
        // Return as plain text with cleaned up formatting
        return Document.plain(processedText, title: documentTitle, sourceURL: url)
    }
    
    /// Post-process text to merge orphaned list markers with content
    private func postProcessText(_ text: String) -> String {
        // Define regex patterns for list markers and numbering
        let patterns = [
            "^\\d+\\.$",                    // 1. 2. 3.
            "^\\d+$",                       // 1 2 3
            "^\\(\\d+\\)$",                 // (1) (2) (3)
            "^\\([a-zA-Z]\\)$",             // (a) (b) (c)
            "^[ivxIVX]+\\.$",               // i. ii. iii.
            "^\\([ivxIVX]+\\)$",            // (i) (ii) (iii)
            "^[a-zA-Z]\\.?$",               // a / a. / b / b.
            "^\\([a-zA-Z]{1,2}\\)$",        // (a) (b) (aa)
            "^\\*$",                        // *
            "^•$",                          // •
            "^–$",                          // –
            "^—$",                          // —
            "^–\\s*\\w?$",                  // – or short dash markers with a stray character
            "^[:;.,!?\"'()]+$",             // Lines with only punctuation
            "^[:;.,!?\"'()\\d]+$",          // Punctuation and numbers
            "^\\d+-[a-zA-Z]$",              // 1-a, 2-b
            "^\\d+[a-zA-Z]+$",              // 1a, 2b
            "^\\d+\\)$",                    // 1), 2)
            "^[a-zA-Z]\\)$",                // a), b)
            "^\\d+-\\d+$",                  // 1-1, 2-3
            "^\\d+-[a-zA-Z]+$",             // 1-ab, 2-cd
            "^[a-zA-Z]+-\\d+$",             // ab-1, cd-2
            "^[a-zA-Z]+\\d+$",              // ab1, cd2
            "^[a-zA-Z]{1,2}\\d+\\)$",       // a1), ab2)
            "^\\d+[a-zA-Z]{1,2}\\)$",       // 1a), 2ab)
            "^[a-zA-Z]{1,2}\\d+$",          // ab12, cd34
            "^[a-zA-Z]\\d+-[a-zA-Z]\\d+$"   // a1-b2, c3-d4
        ]
        
        // Compile regex patterns
        let compiledPatterns = patterns.compactMap { try? NSRegularExpression(pattern: $0, options: []) }
        
        // Split into lines
        let lines = text.components(separatedBy: .newlines)
        var processedLines: [String] = []
        var i = 0
        
        while i < lines.count {
            let currentLine = lines[i].trimmingCharacters(in: .whitespaces)
            
            // Check if current line matches any pattern
            let isMatch = compiledPatterns.contains { regex in
                let range = NSRange(currentLine.startIndex..., in: currentLine)
                return regex.firstMatch(in: currentLine, options: [], range: range) != nil
            }
            
            if isMatch {
                // Find next non-empty line
                var nextNonEmptyIndex = i + 1
                while nextNonEmptyIndex < lines.count && lines[nextNonEmptyIndex].trimmingCharacters(in: .whitespaces).isEmpty {
                    nextNonEmptyIndex += 1
                }
                
                if nextNonEmptyIndex < lines.count {
                    // Merge current line with next non-empty line
                    let mergedLine = currentLine + " " + lines[nextNonEmptyIndex].trimmingCharacters(in: .whitespaces)
                    processedLines.append(mergedLine)
                    i = nextNonEmptyIndex + 1
                } else {
                    // No next line to merge with
                    processedLines.append(currentLine)
                    i += 1
                }
            } else {
                // Keep non-matching lines as-is
                processedLines.append(currentLine)
                i += 1
            }
        }
        
        // Standardize to have exactly two newlines between paragraphs
        let paragraphs = processedLines
            .joined(separator: "\n")
            .components(separatedBy: CharacterSet.newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        return paragraphs.joined(separator: "\n\n")
    }

    /// Promote known heading CSS classes to semantic <h2>/<h3>/<h4> tags before HTML parsing
    private func promoteHeadingClasses(in html: String) -> String {
        var updated = html

        // H2 classes: coj-title-grseq-1, C05Titre1, C75Debutdesmotifs, C04Titre1, C41DispositifIntroduction, conditional coj-sum-title-1
        if let re = try? NSRegularExpression(pattern: #"<([a-zA-Z][\w\-]*)([^>]*\bclass="[^"]*(?:coj-title-grseq-1|C05Titre1|C75Debutdesmotifs|C04Titre1|C41DispositifIntroduction)[^"]*"[^>]*)>([\s\S]*?)</\1>"#, options: [.caseInsensitive]) {
            updated = replaceMatches(in: updated, regex: re) { match, original in
                guard match.numberOfRanges == 4 else { return "" }
                let attrs = original.substring(with: match.range(at: 2))
                let inner = original.substring(with: match.range(at: 3))
                return "<h2\(attrs)>\(inner)</h2>"
            }
        }

        // H3 classes: coj-title-grseq-2, C05Titre2
        if let re = try? NSRegularExpression(pattern: #"<([a-zA-Z][\w\-]*)([^>]*\bclass="[^"]*(?:coj-title-grseq-2|C05Titre2)[^"]*"[^>]*)>([\s\S]*?)</\1>"#, options: [.caseInsensitive]) {
            updated = replaceMatches(in: updated, regex: re) { match, original in
                guard match.numberOfRanges == 4 else { return "" }
                let attrs = original.substring(with: match.range(at: 2))
                let inner = original.substring(with: match.range(at: 3))
                return "<h3\(attrs)>\(inner)</h3>"
            }
        }

        // H4 classes: C06Titre3, coj-title-grseq-3
        if let re = try? NSRegularExpression(pattern: #"<([a-zA-Z][\w\-]*)([^>]*\bclass="[^"]*(?:C06Titre3|coj-title-grseq-3)[^"]*"[^>]*)>([\s\S]*?)</\1>"#, options: [.caseInsensitive]) {
            updated = replaceMatches(in: updated, regex: re) { match, original in
                guard match.numberOfRanges == 4 else { return "" }
                let attrs = original.substring(with: match.range(at: 2))
                let inner = original.substring(with: match.range(at: 3))
                return "<h4\(attrs)>\(inner)</h4>"
            }
        }

        // Conditional promotion for coj-sum-title-1 -> h2 unless rubric/date
        if let re = try? NSRegularExpression(pattern: #"<([a-zA-Z][\w\-]*)([^>]*\bclass="[^"]*coj-sum-title-1[^"]*"[^>]*)>([\s\S]*?)</\1>"#, options: [.caseInsensitive]) {
            updated = replaceMatches(in: updated, regex: re) { match, original in
                guard match.numberOfRanges == 4 else { return "" }
                let attrs = original.substring(with: match.range(at: 2))
                let inner = original.substring(with: match.range(at: 3))

                // Strip tags and collapse whitespace to test text content
                let textOnly = inner.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // Skip rubric lines (ALL CAPS ... OF THE COURT) and standalone dates
                let rubric = textOnly.range(of: #"^[A-Z]+ OF THE COURT"#, options: [.regularExpression]) != nil
                let dateLike = textOnly.range(of: #"^\d{1,2}\s+\w+\s+\d{4}$"#, options: [.regularExpression]) != nil
                if rubric || dateLike {
                    return original.substring(with: match.range)
                }

                return "<h2\(attrs)>\(inner)</h2>"
            }
        }

        return updated
    }

    /// Replace regex matches with a custom transformer (processed from end to start to keep ranges valid)
    private func replaceMatches(in source: String,
                                regex: NSRegularExpression,
                                transform: (NSTextCheckingResult, NSString) -> String) -> String {
        let original = source as NSString
        let mutable = NSMutableString(string: source)
        let matches = regex.matches(in: source, options: [], range: NSRange(location: 0, length: original.length))
        for match in matches.reversed() {
            let replacement = transform(match, original)
            mutable.replaceCharacters(in: match.range, with: replacement)
        }
        return mutable as String
    }
    
    /// Simple title extraction from HTML <title> tag
    private func extractTitle(from html: String) -> String? {
        let pattern = "<title>(.*?)</title>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let nsString = html as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        guard let match = regex.firstMatch(in: html, options: [], range: range) else {
            return nil
        }
        
        let titleRange = match.range(at: 1)
        let title = nsString.substring(with: titleRange)
        
        // Clean up title (remove extra whitespace, decode HTML entities)
        return title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }
}
