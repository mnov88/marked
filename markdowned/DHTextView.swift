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

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = true
        tv.adjustsFontForContentSizeCategory = true
        tv.textContainerInset = style.contentInsets
        tv.textContainer.lineFragmentPadding = 8
        tv.backgroundColor = style.backgroundColor
        tv.linkTextAttributes = [
            .foregroundColor: UIColor.link,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Add tap gesture recognizer for highlight removal
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.delegate = context.coordinator
        tv.addGestureRecognizer(tapGesture)
        context.coordinator.tapGesture = tapGesture

        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Update insets if changed
        if uiView.textContainerInset != style.contentInsets {
            uiView.textContainerInset = style.contentInsets
        }
        
        // Avoid resetting if identical
        if uiView.attributedText?.isEqual(to: attributedText) != true {
            uiView.attributedText = attributedText
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

    final class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        var parent: DHTextView
        var currentHighlights: [DHTextHighlight] = []
        var tapGesture: UITapGestureRecognizer?

        init(_ parent: DHTextView) { self.parent = parent }

        // MARK: - Tap Gesture Handling

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView = gesture.view as? UITextView else { return }

            let location = gesture.location(in: textView)

            // Get the character index at tap location
            let layoutManager = textView.layoutManager
            let textContainer = textView.textContainer
            var point = location
            point.x -= textView.textContainerInset.left
            point.y -= textView.textContainerInset.top

            let characterIndex = layoutManager.characterIndex(
                for: point,
                in: textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil
            )

            // Check if tap is on a highlight
            if let tappedHighlight = currentHighlights.first(where: { highlight in
                NSLocationInRange(characterIndex, highlight.range)
            }) {
                // Consume the gesture to prevent UITextView from handling it
                gesture.state = .cancelled

                // Clear any text selection to prevent rendering issues
                textView.selectedRange = NSRange(location: 0, length: 0)
                textView.resignFirstResponder()

                showRemovalMenu(for: tappedHighlight, in: textView, at: location)
            }
        }

        private func showRemovalMenu(for highlight: DHTextHighlight, in textView: UITextView, at location: CGPoint) {
            // Clear selection before showing menu
            textView.selectedRange = NSRange(location: 0, length: 0)

            let alert = UIAlertController(
                title: "Highlight",
                message: "Do you want to remove this highlight?",
                preferredStyle: .actionSheet
            )

            alert.addAction(UIAlertAction(title: "Remove Highlight", style: .destructive) { [weak self] _ in
                self?.parent.removeHighlightsInRange(highlight.range)
                // Ensure selection stays cleared after removal
                DispatchQueue.main.async {
                    textView.selectedRange = NSRange(location: 0, length: 0)
                }
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                // Ensure selection stays cleared on cancel
                textView.selectedRange = NSRange(location: 0, length: 0)
            })

            // For iPad popover presentation
            if let popover = alert.popoverPresentationController {
                popover.sourceView = textView
                popover.sourceRect = CGRect(origin: location, size: .zero)
            }

            // Present from the view controller
            if let viewController = textView.window?.rootViewController {
                viewController.present(alert, animated: true)
            }
        }

        // Check if touch is on a highlight before allowing gesture to begin
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard gestureRecognizer == tapGesture,
                  let textView = gestureRecognizer.view as? UITextView else {
                return true
            }

            let location = touch.location(in: textView)
            let layoutManager = textView.layoutManager
            let textContainer = textView.textContainer
            var point = location
            point.x -= textView.textContainerInset.left
            point.y -= textView.textContainerInset.top

            let characterIndex = layoutManager.characterIndex(
                for: point,
                in: textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil
            )

            // Only receive touch if it's on a highlight
            let isOnHighlight = currentHighlights.contains { highlight in
                NSLocationInRange(characterIndex, highlight.range)
            }

            return isOnHighlight
        }

        // Block other gestures when our tap gesture is on a highlight
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            // If this is our tap gesture, don't allow simultaneous recognition
            // This prevents UITextView's gestures from interfering
            if gestureRecognizer == tapGesture {
                return false
            }
            return true
        }

        // Block UITextView's gestures when our tap is on a highlight
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            // If the other gesture is our tap, UITextView gestures should wait
            if otherGestureRecognizer == tapGesture {
                return true
            }
            return false
        }

        // Add/Remove highlight menu
        func textView(_ textView: UITextView,
                      editMenuForTextIn range: NSRange,
                      suggestedActions: [UIMenuElement]) -> UIMenu? {

            let palette: [(String, UIColor)] = [
                ("Yellow", UIColor(hex: "#FFEB3B") ?? .systemYellow),
                ("Green",  UIColor(hex: "#4CAF50") ?? .systemGreen),
                ("Blue",   UIColor(hex: "#2196F3") ?? .systemBlue),
                ("Pink",   UIColor(hex: "#E91E63") ?? .systemPink),
                ("Purple", UIColor(hex: "#9C27B0") ?? .systemPurple)
            ]

            let add = palette.map { name, color in
                UIAction(title: "Highlight \(name)") { [weak self] _ in
                    self?.parent.addHighlight(range, color)
                }
            }

            let intersects = currentHighlights.contains { NSIntersectionRange($0.range, range).length > 0 }
            var items: [UIMenuElement] = [UIMenu(title: "Add Highlight", children: add)]

            if intersects {
                items.insert(UIAction(title: "Remove Highlight", attributes: .destructive) { [weak self] _ in
                    self?.parent.removeHighlightsInRange(range)
                }, at: 0)
            }

            return UIMenu(children: items)
        }

        // Handle single-tap on .link with custom scheme
        func textView(_ textView: UITextView,
                      shouldInteractWith URL: URL,
                      in characterRange: NSRange,
                      interaction: UITextItemInteraction) -> Bool {
            parent.onTapLink(URL)
            return false // prevent default navigation
        }
    }
}
