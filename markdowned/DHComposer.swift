//
//  DHComposer.swift
//  markdowned
//
//  Created by Milos Novovic on 10/11/2025.
//



import SwiftUI
import Combine

// MARK: - Composer

struct DHComposer {
    // Compose once per render. Callers should cache link/indent spans.
    /// - Parameters:
    ///   - skipHighlights: When true, highlights are not applied to the attributed string.
    ///                    Use this when TextKit 2 is handling highlight rendering via
    ///                    NSTextLayoutManager rendering attributes.
    static func compose(
        base: NSAttributedString,
        config: DHConfig,
        links: [DHLinkSpan],
        indents: [DHIndentSpan],
        headings: [DHHeadingSpan] = [],
        highlights: [DHTextHighlight],
        skipHighlights: Bool = false
    ) -> NSAttributedString {
        let out = NSMutableAttributedString(attributedString: base)
        let full = NSRange(location: 0, length: out.length)

        // Base style
        let p = NSMutableParagraphStyle()
        if config.style.lineHeightMultiple > 0 { p.lineHeightMultiple = config.style.lineHeightMultiple }
        p.paragraphSpacing = config.style.paragraphSpacing
        p.alignment = config.style.alignment
        p.lineBreakStrategy = config.style.lineBreakStrategy

        out.addAttributes([
            .font: config.style.font,
            .foregroundColor: config.style.textColor,
            .paragraphStyle: p
        ], range: full)

        // Indentation
        for ind in indents {
            guard ind.range.location >= 0,
                  NSMaxRange(ind.range) <= out.length else { continue }
            // Safe mutable copy - avoid force cast
            let existingStyle = out.attribute(.paragraphStyle, at: ind.range.location, effectiveRange: nil) as? NSParagraphStyle
            let ps: NSMutableParagraphStyle
            if let existing = existingStyle?.mutableCopy() as? NSMutableParagraphStyle {
                ps = existing
            } else if let baseCopy = p.mutableCopy() as? NSMutableParagraphStyle {
                ps = baseCopy
            } else {
                ps = NSMutableParagraphStyle()
            }
            ps.headIndent = ind.headIndent
            ps.tailIndent = ind.tailIndent
            ps.firstLineHeadIndent = ind.firstLineHeadIndent
            out.addAttribute(.paragraphStyle, value: ps, range: ind.range)
        }

        // Headings (font + spacing) layered atop existing paragraph styles
        for h in headings {
            guard h.range.location >= 0,
                  NSMaxRange(h.range) <= out.length else { continue }

            let existingStyle = out.attribute(.paragraphStyle, at: h.range.location, effectiveRange: nil) as? NSParagraphStyle
            let ps: NSMutableParagraphStyle
            if let existing = existingStyle?.mutableCopy() as? NSMutableParagraphStyle {
                ps = existing
            } else if let baseCopy = p.mutableCopy() as? NSMutableParagraphStyle {
                ps = baseCopy
            } else {
                ps = NSMutableParagraphStyle()
            }

            let spacing: (before: CGFloat, after: CGFloat)
            switch h.level {
            case .h2:
                spacing = (before: 8, after: 6)
            case .h3:
                spacing = (before: 6, after: 4)
            }

            ps.paragraphSpacingBefore = max(ps.paragraphSpacingBefore, config.style.paragraphSpacing + spacing.before)
            ps.paragraphSpacing = max(ps.paragraphSpacing, config.style.paragraphSpacing + spacing.after)

            out.addAttributes([
                .font: headingFont(base: config.style.font, level: h.level),
                .paragraphStyle: ps
            ], range: h.range)
        }

        // Links via .link attribute
        for l in links {
            guard l.range.location >= 0,
                  NSMaxRange(l.range) <= out.length else { continue }
            out.addAttribute(.link, value: l.url, range: l.range)
            out.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: l.range)
            #if canImport(UIKit)
            out.addAttribute(.foregroundColor, value: PlatformColor.link, range: l.range)
            #elseif canImport(AppKit)
            out.addAttribute(.foregroundColor, value: PlatformColor.systemBlue, range: l.range)
            #endif
        }

        // Highlights: background only to avoid clobbering link underline
        // Using higher opacity since we now use softer, pastel highlight colors
        // Skip when TextKit 2 is handling highlight rendering via NSTextLayoutManager
        if !skipHighlights {
            for h in highlights {
                guard let trimmed = trimWhitespaceAndNewlines(h.range, in: out) else { continue }
                out.addAttributes([
                    .backgroundColor: h.color.withAlphaComponent(0.85),
                    .textItemTag: "\(DHHighlightConstants.tagPrefix)\(h.id.uuidString)"
                ], range: trimmed)
            }
        }

        return out
    }

    private static func trimWhitespaceAndNewlines(_ range: NSRange, in text: NSAttributedString) -> NSRange? {
        guard let clamped = range.clamped(toStringLength: text.length) else { return nil }
        let ns = text.string as NSString
        let charset = CharacterSet.whitespacesAndNewlines
        var start = clamped.location
        var end = clamped.location + clamped.length

        while start < end {
            let scalar = UnicodeScalar(ns.character(at: start))
            if let scalar, charset.contains(scalar) { start += 1 } else { break }
        }
        while end > start {
            let scalar = UnicodeScalar(ns.character(at: end - 1))
            if let scalar, charset.contains(scalar) { end -= 1 } else { break }
        }

        let length = end - start
        return length > 0 ? NSRange(location: start, length: length) : nil
    }

    private static func headingFont(base: PlatformFont, level: DHHeadingSpan.Level) -> PlatformFont {
        let delta: CGFloat
        switch level {
        case .h2: delta = 4
        case .h3: delta = 2
        }

        #if canImport(UIKit)
        let desiredSize = base.pointSize + delta
        if let descriptor = base.fontDescriptor.withSymbolicTraits(.traitBold) {
            return PlatformFont(descriptor: descriptor, size: desiredSize)
        }
        return PlatformFont.systemFont(ofSize: desiredSize, weight: .semibold)
        #elseif canImport(AppKit)
        let desiredSize = base.pointSize + delta
        let descriptor = base.fontDescriptor.withSymbolicTraits(.bold)
        if let descriptor {
            return PlatformFont(descriptor: descriptor, size: desiredSize)
        }
        return PlatformFont.systemFont(ofSize: desiredSize, weight: .semibold)
        #endif
    }
}
