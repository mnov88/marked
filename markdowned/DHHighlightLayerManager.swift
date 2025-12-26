//
//  DHHighlightLayerManager.swift
//  markdowned
//
//  TextKit 2 highlight rendering using NSTextLayoutManager
//  Renders highlights as decorations without modifying NSTextStorage
//

import UIKit

/// Manages highlight rendering using TextKit 2's NSTextLayoutManager.
/// Highlights are applied as rendering attributes, not stored in the text storage.
@MainActor
final class DHHighlightLayerManager: NSObject {

    private weak var textView: UITextView?
    private var highlights: [DHTextHighlight] = []

    /// Whether TextKit 2 is available and enabled
    private(set) var isTextKit2Enabled: Bool = false

    init(textView: UITextView) {
        self.textView = textView
        super.init()

        // Check if TextKit 2 is available (iOS 16+)
        if #available(iOS 16.0, *) {
            isTextKit2Enabled = textView.textLayoutManager != nil
        }
    }

    /// Update the highlights to render. This does NOT modify the text storage.
    func setHighlights(_ newHighlights: [DHTextHighlight]) {
        guard isTextKit2Enabled else { return }

        let oldHighlights = highlights
        highlights = newHighlights

        guard #available(iOS 16.0, *),
              let textLayoutManager = textView?.textLayoutManager,
              let contentManager = textLayoutManager.textContentManager else {
            return
        }

        // Remove old rendering attributes
        for highlight in oldHighlights {
            if let textRange = textRange(for: highlight.range, in: contentManager) {
                textLayoutManager.removeRenderingAttribute(.backgroundColor, for: textRange)
                textLayoutManager.removeRenderingAttribute(.textItemTag, for: textRange)
            }
        }

        // Apply new rendering attributes
        for highlight in newHighlights {
            let trimmedRange = trimWhitespaceAndNewlines(highlight.range)
            guard let trimmedRange,
                  let textRange = textRange(for: trimmedRange, in: contentManager) else {
                continue
            }

            textLayoutManager.addRenderingAttribute(
                .backgroundColor,
                value: highlight.color.withAlphaComponent(0.85),
                for: textRange
            )
            textLayoutManager.addRenderingAttribute(
                .textItemTag,
                value: "\(DHHighlightConstants.tagPrefix)\(highlight.id.uuidString)",
                for: textRange
            )
        }

        // Invalidate layout for affected ranges to trigger redraw
        invalidateLayout(for: oldHighlights + newHighlights, in: textLayoutManager, contentManager: contentManager)
    }

    /// Convert NSRange to NSTextRange for TextKit 2
    @available(iOS 16.0, *)
    private func textRange(for nsRange: NSRange, in contentManager: NSTextContentManager) -> NSTextRange? {
        guard let start = contentManager.location(contentManager.documentRange.location, offsetBy: nsRange.location),
              let end = contentManager.location(start, offsetBy: nsRange.length) else {
            return nil
        }
        return NSTextRange(location: start, end: end)
    }

    /// Invalidate layout for highlight ranges to trigger redraw
    @available(iOS 16.0, *)
    private func invalidateLayout(for highlights: [DHTextHighlight],
                                   in layoutManager: NSTextLayoutManager,
                                   contentManager: NSTextContentManager) {
        for highlight in highlights {
            if let textRange = textRange(for: highlight.range, in: contentManager) {
                layoutManager.invalidateLayout(for: textRange)
            }
        }
    }

    /// Trim whitespace/newlines from range boundaries (mirrors DHComposer logic)
    private func trimWhitespaceAndNewlines(_ range: NSRange) -> NSRange? {
        guard let textView = textView,
              let text = textView.text as NSString?,
              range.location >= 0,
              NSMaxRange(range) <= text.length else {
            return nil
        }

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

        let length = end - start
        return length > 0 ? NSRange(location: start, length: length) : nil
    }

    /// Get the current highlights (for hit-testing in context menus)
    func currentHighlights() -> [DHTextHighlight] {
        return highlights
    }

    /// Find highlight at a given location (for tap handling)
    func highlight(at location: Int) -> DHTextHighlight? {
        return highlights.first { NSLocationInRange(location, $0.range) }
    }

    /// Find highlights intersecting a range
    func highlights(intersecting range: NSRange) -> [DHTextHighlight] {
        return highlights.filter { NSIntersectionRange($0.range, range).length > 0 }
    }
}

// MARK: - UITextView Extension for TextKit 2 Detection

extension UITextView {
    /// Check if this text view is using TextKit 2
    var isUsingTextKit2: Bool {
        if #available(iOS 16.0, *) {
            return textLayoutManager != nil
        }
        return false
    }
}
