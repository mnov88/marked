//
//  DHTextViewMac.swift
//  markdowned
//
//  NSTextView wrapper for macOS
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import SwiftUI
import AppKit

// MARK: - NSTextView bridge for macOS

struct DHTextViewMac: NSViewRepresentable {
    // Inputs
    let attributedText: NSAttributedString
    let style: DHStyle
    let highlightsSnapshot: [DHTextHighlight]
    let addHighlight: (NSRange, PlatformColor) -> Void
    let removeHighlightsInRange: (NSRange) -> Void
    let onTapLink: (URL) -> Void
    @Binding var scrollTarget: NSRange?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.backgroundColor = style.backgroundColor
        textView.textContainerInset = NSSize(
            width: style.contentInsets.left,
            height: style.contentInsets.top
        )
        textView.textContainer?.lineFragmentPadding = 8
        textView.textContainer?.widthTracksTextView = true
        textView.isAutomaticLinkDetectionEnabled = false
        textView.linkTextAttributes = [
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        // Set up text container and layout manager
        if let textContainer = textView.textContainer,
           let layoutManager = textView.layoutManager {
            textContainer.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
            layoutManager.allowsNonContiguousLayout = false
        }

        // Add click gesture recognizer for highlight removal
        let clickGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        textView.addGestureRecognizer(clickGesture)
        context.coordinator.clickGesture = clickGesture

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }

        // Update text container insets
        let targetInsets = NSSize(
            width: style.contentInsets.left,
            height: style.contentInsets.top
        )
        if textView.textContainerInset != targetInsets {
            textView.textContainerInset = targetInsets
        }

        // Avoid resetting if identical
        if textView.attributedString() != attributedText {
            textView.textStorage?.setAttributedString(attributedText)
        }

        if textView.backgroundColor != style.backgroundColor {
            textView.backgroundColor = style.backgroundColor
        }

        // Scroll target with animation
        if let target = scrollTarget, target.clamped(toStringLength: textView.string.count) != nil {
            DispatchQueue.main.async {
                textView.scrollRangeToVisible(target)
            }
            DispatchQueue.main.async { self.scrollTarget = nil }
        }

        context.coordinator.currentHighlights = highlightsSnapshot
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: DHTextViewMac
        var currentHighlights: [DHTextHighlight] = []
        var clickGesture: NSClickGestureRecognizer?

        init(_ parent: DHTextViewMac) { self.parent = parent }

        // MARK: - Click Gesture Handling

        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let textView = gesture.view as? NSTextView else { return }

            let location = gesture.location(in: textView)

            // Adjust for text container insets
            var point = location
            point.x -= textView.textContainerInset.width
            point.y -= textView.textContainerInset.height

            // Get character index at click location
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return }

            let characterIndex = layoutManager.characterIndex(
                for: point,
                in: textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil
            )

            // Check if click is on a highlight
            if let tappedHighlight = currentHighlights.first(where: { highlight in
                NSLocationInRange(characterIndex, highlight.range)
            }) {
                // Clear selection
                textView.setSelectedRange(NSRange(location: 0, length: 0))

                showRemovalMenu(for: tappedHighlight, in: textView, at: location)
            }
        }

        private func showRemovalMenu(for highlight: DHTextHighlight, in textView: NSTextView, at location: NSPoint) {
            // Clear selection before showing menu
            textView.setSelectedRange(NSRange(location: 0, length: 0))

            let alert = NSAlert()
            alert.messageText = "Highlight"
            alert.informativeText = "Do you want to remove this highlight?"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Remove Highlight")
            alert.addButton(withTitle: "Cancel")

            if alert.runModal() == .alertFirstButtonReturn {
                parent.removeHighlightsInRange(highlight.range)
                // Clear selection after removal
                DispatchQueue.main.async {
                    textView.setSelectedRange(NSRange(location: 0, length: 0))
                }
            }
        }

        // MARK: - Context Menu for Adding Highlights

        func textView(_ textView: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
            let selectedRange = textView.selectedRange()
            guard selectedRange.length > 0 else { return menu }

            let palette: [(String, PlatformColor)] = [
                ("Yellow", PlatformColor(hex: "#FFEB3B") ?? .systemYellow),
                ("Green",  PlatformColor(hex: "#4CAF50") ?? .systemGreen),
                ("Blue",   PlatformColor(hex: "#2196F3") ?? .systemBlue),
                ("Pink",   PlatformColor(hex: "#E91E63") ?? .systemPink),
                ("Purple", PlatformColor(hex: "#9C27B0") ?? .systemPurple)
            ]

            let newMenu = NSMenu(title: "Text Actions")

            // Add highlight submenu
            let highlightMenu = NSMenu(title: "Add Highlight")
            for (name, color) in palette {
                let item = NSMenuItem(title: name, action: #selector(addHighlightAction(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = (selectedRange, color)
                highlightMenu.addItem(item)
            }

            let highlightMenuItem = NSMenuItem(title: "Add Highlight", action: nil, keyEquivalent: "")
            highlightMenuItem.submenu = highlightMenu
            newMenu.addItem(highlightMenuItem)

            // Check if there are any highlights in the selected range
            let intersects = currentHighlights.contains { NSIntersectionRange($0.range, selectedRange).length > 0 }
            if intersects {
                let removeItem = NSMenuItem(
                    title: "Remove Highlight",
                    action: #selector(removeHighlightAction(_:)),
                    keyEquivalent: ""
                )
                removeItem.target = self
                removeItem.representedObject = selectedRange
                newMenu.addItem(removeItem)
            }

            // Add separator and original menu items
            if menu.items.count > 0 {
                newMenu.addItem(NSMenuItem.separator())
                for item in menu.items {
                    newMenu.addItem(item.copy() as! NSMenuItem)
                }
            }

            return newMenu
        }

        @objc func addHighlightAction(_ sender: NSMenuItem) {
            guard let (range, color) = sender.representedObject as? (NSRange, PlatformColor) else { return }
            parent.addHighlight(range, color)
        }

        @objc func removeHighlightAction(_ sender: NSMenuItem) {
            guard let range = sender.representedObject as? NSRange else { return }
            parent.removeHighlightsInRange(range)
        }

        // MARK: - Link Handling

        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            if let url = link as? URL {
                parent.onTapLink(url)
                return false // Don't open in browser
            } else if let urlString = link as? String, let url = URL(string: urlString) {
                parent.onTapLink(url)
                return false
            }
            return true
        }
    }
}

#endif
