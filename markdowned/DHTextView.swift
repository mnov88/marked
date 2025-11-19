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
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Avoid resetting if identical
        if uiView.attributedText?.isEqual(to: attributedText) != true {
            uiView.attributedText = attributedText
        }
        if uiView.backgroundColor != style.backgroundColor {
            uiView.backgroundColor = style.backgroundColor
        }

        // Scroll target without flashing selection
        if let target = scrollTarget, target.clamped(toStringLength: uiView.attributedText?.length ?? 0) != nil {
            DispatchQueue.main.async {
                uiView.layoutIfNeeded()
                uiView.scrollRangeToVisible(target)
            }
            DispatchQueue.main.async { self.scrollTarget = nil }
        }

        context.coordinator.currentHighlights = highlightsSnapshot
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: DHTextView
        var currentHighlights: [DHTextHighlight] = []

        init(_ parent: DHTextView) { self.parent = parent }

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
