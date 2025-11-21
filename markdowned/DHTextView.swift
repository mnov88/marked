//
//  DHTextView.swift
//  markdowned
//
//  Created by Milos Novovic on 10/11/2025.
//

import SwiftUI
import Foundation
import UIKit

// MARK: - UITextView bridge

struct DHTextView: UIViewRepresentable {
    // Inputs
    let attributedText: NSAttributedString
    let style: DHStyle
    let highlightsSnapshot: [DHTextHighlight]
    let addHighlight: (NSRange, UIColor) -> Void
    let removeHighlightsInRange: (NSRange) -> Void
    let onTapLink: (URL) -> Void
    @Binding var scrollTarget: NSRange?

    // Page layout support - available width for dynamic inset calculation
    var availableWidth: CGFloat?
    var usePageLayout: Bool = false

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = true
        tv.adjustsFontForContentSizeCategory = true
        tv.textContainerInset = calculateInsets()
        tv.textContainer.lineFragmentPadding = 8
        tv.backgroundColor = style.backgroundColor
        tv.linkTextAttributes = [
            .foregroundColor: UIColor.link,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Position scrollbar at window edge, not content edge
        if usePageLayout, let width = availableWidth {
            let insets = calculateInsets()
            // Keep vertical scroll indicator insets minimal, push horizontal scrollbar to edge
            tv.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -insets.right + style.horizontalMargin.baseInset)
        }

        return tv
    }

    /// Calculate content insets - for page layout, center content within available width
    private func calculateInsets() -> UIEdgeInsets {
        guard usePageLayout, let width = availableWidth else {
            return style.contentInsets
        }

        let maxContentWidth = style.horizontalMargin.maxContentWidth
        let baseInset = style.horizontalMargin.baseInset

        // If available width exceeds max content width, add extra horizontal padding
        if width > maxContentWidth + (baseInset * 2) {
            let extraHorizontalInset = (width - maxContentWidth) / 2
            return UIEdgeInsets(
                top: style.contentInsets.top,
                left: extraHorizontalInset,
                bottom: style.contentInsets.bottom,
                right: extraHorizontalInset
            )
        } else {
            // Use base margin insets
            return UIEdgeInsets(
                top: style.contentInsets.top,
                left: baseInset,
                bottom: style.contentInsets.bottom,
                right: baseInset
            )
        }
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Update insets if changed (use calculated insets for page layout)
        let calculatedInsets = calculateInsets()
        if uiView.textContainerInset != calculatedInsets {
            uiView.textContainerInset = calculatedInsets
        }

        // Update scroll indicator insets for page layout
        if usePageLayout {
            let rightInset = max(0, -calculatedInsets.right + style.horizontalMargin.baseInset)
            let newScrollInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: rightInset)
            if uiView.verticalScrollIndicatorInsets != newScrollInsets {
                uiView.verticalScrollIndicatorInsets = newScrollInsets
            }
        }
        
        // Avoid resetting if identical
        if uiView.attributedText?.isEqual(to: attributedText) != true {
            uiView.attributedText = attributedText
        }
        // Always clear any lingering selection to avoid extended line-fragment highlights
        if uiView.selectedTextRange != nil {
            DispatchQueue.main.async {
                uiView.selectedTextRange = nil
            }
        }
        if uiView.backgroundColor != style.backgroundColor {
            uiView.backgroundColor = style.backgroundColor
        }

        // Scroll target with smooth animation
        if let target = scrollTarget, target.clamped(toStringLength: uiView.attributedText?.length ?? 0) != nil {
            DispatchQueue.main.async {
                uiView.layoutIfNeeded()
                
                // Calculate rect for the target range
                if let textRange = uiView.textRange(from: uiView.beginningOfDocument, to: uiView.beginningOfDocument),
                   let start = uiView.position(from: textRange.start, offset: target.location),
                   let end = uiView.position(from: start, offset: target.length),
                   let range = uiView.textRange(from: start, to: end) {
                    let rect = uiView.firstRect(for: range)
                    
                    // Animate scroll
                    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                        uiView.scrollRectToVisible(rect, animated: false)
                    }
                } else {
                    // Fallback to non-animated scroll
                    uiView.scrollRangeToVisible(target)
                }
            }
            DispatchQueue.main.async { self.scrollTarget = nil }
        }

        context.coordinator.currentHighlights = highlightsSnapshot
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: DHTextView
        var currentHighlights: [DHTextHighlight] = []
        private let highlightTagPrefix = DHHighlightConstants.tagPrefix

        init(_ parent: DHTextView) { self.parent = parent }

        // Add/Remove highlight menu
        func textView(_ textView: UITextView,
                      editMenuForTextIn range: NSRange,
                      suggestedActions: [UIMenuElement]) -> UIMenu? {
            guard range.length > 0 else { return nil }

            let clearSelection: () -> Void = { [weak textView] in
                DispatchQueue.main.async {
                    textView?.selectedTextRange = nil
                    textView?.resignFirstResponder()
                }
            }

            // Soft, warm highlighter colors inspired by physical highlighters and e-readers
            let palette: [(String, UIColor)] = [
                ("Yellow", UIColor(hex: "#FEF3B5") ?? .systemYellow),   // Soft butter yellow
                ("Green",  UIColor(hex: "#C8E6C9") ?? .systemGreen),    // Soft mint green
                ("Blue",   UIColor(hex: "#BBDEFB") ?? .systemBlue),     // Soft sky blue
                ("Pink",   UIColor(hex: "#F8BBD9") ?? .systemPink),     // Soft rose pink
                ("Orange", UIColor(hex: "#FFE0B2") ?? .systemOrange)    // Soft peach orange
            ]

            let add = palette.map { name, color in
                UIAction(title: "Highlight \(name)") { [weak self] _ in
                    guard let self else { return }
                    let trimmedRange = self.trimmedRange(range, in: self.parent.attributedText)
                    guard let trimmedRange, trimmedRange.length > 0 else { return }
                    self.parent.addHighlight(trimmedRange, color)
                    clearSelection()
                }
            }

            let intersects = currentHighlights.contains { NSIntersectionRange($0.range, range).length > 0 }
            var items: [UIMenuElement] = [UIMenu(title: "Add Highlight", children: add)]

            if intersects {
                items.insert(UIAction(title: "Remove Highlight", attributes: .destructive) { [weak self] _ in
                    self?.parent.removeHighlightsInRange(range)
                    clearSelection()
                }, at: 0)
            }

            items.append(contentsOf: suggestedActions)
            return UIMenu(children: items)
        }

        // Handle single-tap on .link with custom scheme
        @available(macCatalyst, deprecated: 17.0, message: "Use textView(_:shouldInteractWith:in:for:) on Catalyst 17+")
        func textView(_ textView: UITextView,
                      shouldInteractWith URL: URL,
                      in characterRange: NSRange,
                      interaction: UITextItemInteraction) -> Bool {
            parent.onTapLink(URL)
            return false // prevent default navigation
        }

        @available(iOS 17.0, *)
        func textView(_ textView: UITextView,
                      primaryActionFor textItem: UITextItem,
                      defaultAction: UIAction) -> UIAction? {
            // Link taps: forward to callback and avoid system navigation
            if let link = link(at: textItem.range, in: textView) {
                return UIAction(title: defaultAction.title, image: defaultAction.image, attributes: defaultAction.attributes) { [weak self] _ in
                    self?.parent.onTapLink(link)
                    DispatchQueue.main.async {
                        textView.selectedTextRange = nil
                    }
                }
            }

            // Highlight taps: remove intersecting highlight
            if let highlight = highlight(for: textItem, in: textView) {
                // Return nil to allow menuConfigurationForTextItem to present a menu on tap
                return nil
            }

            return defaultAction
        }

        @available(iOS 17.0, *)
        func textView(_ textView: UITextView,
                      menuConfigurationFor textItem: UITextItem,
                      defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
            guard let highlight = highlight(for: textItem, in: textView) else {
                return nil // fall back to system menu
            }

            let copy = UIAction(title: "Copy Text", image: UIImage(systemName: "doc.on.doc")) { _ in
                if let text = self.text(from: highlight.range, in: textView) {
                    UIPasteboard.general.string = text
                }
                DispatchQueue.main.async {
                    textView.selectedTextRange = nil
                }
            }

            let remove = UIAction(title: "Remove Highlight", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.parent.removeHighlightsInRange(highlight.range)
                DispatchQueue.main.async {
                    textView.selectedTextRange = nil
                }
            }

            let menu = UIMenu(children: [remove, copy])
            return UITextItem.MenuConfiguration(menu: menu)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !textView.isFirstResponder, textView.selectedTextRange != nil else { return }
            textView.selectedTextRange = nil
        }

        private func trimmedRange(_ range: NSRange, in text: NSAttributedString) -> NSRange? {
            guard let clamped = range.clamped(toStringLength: text.length) else { return nil }
            return DHTextHighlight(id: UUID(), range: clamped, color: .clear).trimmed(in: text.string as NSString).range
        }

        @available(iOS 17.0, *)
        private func highlight(for textItem: UITextItem, in textView: UITextView) -> DHTextHighlight? {
            if let tag = textView.attributedText?.attribute(.textItemTag, at: textItem.range.location, effectiveRange: nil) as? String,
               tag.hasPrefix(highlightTagPrefix) {
                let idString = String(tag.dropFirst(highlightTagPrefix.count))
                if let id = UUID(uuidString: idString),
                   let match = currentHighlights.first(where: { $0.id == id }) {
                    return match
                }
            }
            return currentHighlights.first { NSIntersectionRange($0.range, textItem.range).length > 0 }
        }

        @available(iOS 17.0, *)
        private func link(at range: NSRange, in textView: UITextView) -> URL? {
            guard range.location != NSNotFound,
                  let attributed = textView.attributedText,
                  range.location < attributed.length else { return nil }
            return attributed.attribute(.link, at: range.location, effectiveRange: nil) as? URL
        }

        @available(iOS 17.0, *)
        private func text(from range: NSRange, in textView: UITextView) -> String? {
            guard let attributed = textView.attributedText,
                  range.location != NSNotFound,
                  NSMaxRange(range) <= attributed.length else { return nil }
            return attributed.attributedSubstring(from: range).string
        }
    }
}
