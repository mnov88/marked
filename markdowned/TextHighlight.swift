//
//  DocHighlightingView.swift
//
//  Reusable in-memory document highlighter for SwiftUI + UITextView.
//

import SwiftUI
import UIKit

// MARK: - Utilities

extension UIColor {
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let rgb = UInt32(s, radix: 16) else { return nil }
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension NSRange {
    func clamped(to length: Int) -> NSRange? {
        guard location >= 0, length >= 0 else { return nil }
        let end = location + self.length
        guard end <= length, self.length >= 0 else { return nil }
        return self
    }
}

// MARK: - Models

struct TextHighlight: Identifiable, Equatable {
    let id: UUID
    let range: NSRange
    let color: UIColor

    init(id: UUID = UUID(), range: NSRange, color: UIColor) {
        self.id = id
        self.range = range
        self.color = color
    }
}

struct LinkSpan: Identifiable, Equatable {
    let id: UUID
    let range: NSRange
    let tag: String
}

struct IndentSpan: Identifiable, Equatable {
    let id: UUID
    let range: NSRange
    let headIndent: CGFloat
    let tailIndent: CGFloat
    let firstLineHeadIndent: CGFloat
}

// MARK: - Configuration

struct DocHighlightStyle {
    var font: UIFont = UIFont.preferredFont(forTextStyle: .body)
    var textColor: UIColor = .label
    var backgroundColor: UIColor = .systemBackground
    /// If you want exact line height, use lineHeightMultiple ~1.15–1.4; otherwise set to 0 to keep default.
    var lineHeightMultiple: CGFloat = 1.2
    var alignment: NSTextAlignment = .left
    var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
}

struct DocHighlightConfig {
    var style = DocHighlightStyle()
    var enableLinks: Bool = true
    var enableIndentation: Bool = true

    /// Optional custom rule providers. Defaults are safe no-ops except links example below.
    var linkDetector: ((NSString) -> [LinkSpan])? = DocHighlightConfig.defaultArticleLinkDetector
    var indentationComputer: ((NSString) -> [IndentSpan])? = DocHighlightConfig.defaultIndentationComputer

    /// Example link rule: matches "Article 123" and tags it as "link:article_123".
    static func defaultArticleLinkDetector(_ s: NSString) -> [LinkSpan] {
        let pattern = #"Article\s+(\d+)"#
        guard let re = try? NSRegularExpression(pattern: pattern) else { return [] }
        let full = NSRange(location: 0, length: s.length)
        return re.matches(in: s as String, range: full).compactMap { m in
            guard m.numberOfRanges >= 2 else { return nil }
            let number = (s.substring(with: m.range(at: 1)) as NSString).integerValue
            return LinkSpan(id: UUID(), range: m.range, tag: "link:article_\(number)")
        }
    }

    /// Example indentation rule for legal enumerations: "1.", "(a)", "(i)", bullets.
    static func defaultIndentationComputer(_ s: NSString) -> [IndentSpan] {
        var spans: [IndentSpan] = []
        let paragraphRanges: [NSRange] = s.enumerateParagraphs()
        let base: CGFloat = 20

        let re1 = try? NSRegularExpression(pattern: #"^\d+\."#, options: [.anchorsMatchLines])
        let re2 = try? NSRegularExpression(pattern: #"^\([a-zA-Z]\)"#, options: [.anchorsMatchLines])
        let re3 = try? NSRegularExpression(pattern: #"^\([ivxlcdmIVXLCDM]+\)"#, options: [.anchorsMatchLines])
        for pr in paragraphRanges {
            let p = s.substring(with: pr) as NSString
            let level: Int
            if re1?.firstMatch(in: p as String, range: NSRange(location: 0, length: p.length)) != nil {
                level = 0
            } else if re2?.firstMatch(in: p as String, range: NSRange(location: 0, length: p.length)) != nil {
                level = 1
            } else if re3?.firstMatch(in: p as String, range: NSRange(location: 0, length: p.length)) != nil {
                level = 2
            } else if p.hasPrefix("–") || p.hasPrefix("—") || p.hasPrefix("•") {
                level = 3
            } else {
                level = 0
            }
            let indent = CGFloat(level) * base + base // add base to move body in a bit
            spans.append(
                IndentSpan(
                    id: UUID(),
                    range: pr,
                    headIndent: indent,
                    tailIndent: -indent,
                    firstLineHeadIndent: indent
                )
            )
        }
        return spans
    }
}

private extension NSString {
    func enumerateParagraphs() -> [NSRange] {
        var ranges: [NSRange] = []
        var pos = 0
        let len = length
        while pos < len {
            var range = NSRange(location: 0, length: 0)
            let paraRange = lineRange(for: NSRange(location: pos, length: 0))
            range.location = paraRange.location
            range.length = paraRange.length
            ranges.append(range)
            pos = paraRange.location + paraRange.length
        }
        return ranges
    }
}

// MARK: - ViewModel (in-memory)

@MainActor
final class DocHighlightViewModel: ObservableObject {
    @Published var highlights: [TextHighlight] = []

    func addHighlight(range: NSRange, color: UIColor, in text: NSAttributedString) {
        guard range.clamped(to: text.length) != nil else { return }
        highlights.append(TextHighlight(range: range, color: color))
    }

    func removeHighlights(intersecting range: NSRange) {
        highlights.removeAll { NSIntersectionRange($0.range, range).length > 0 }
    }

    func removeHighlight(id: UUID) {
        highlights.removeAll { $0.id == id }
    }

    func highlight(with id: UUID) -> TextHighlight? { highlights.first { $0.id == id } }
}

// MARK: - AttributedText Composer

struct AttributedComposer {
    static func compose(
        content base: NSAttributedString,
        config: DocHighlightConfig,
        links: [LinkSpan],
        indents: [IndentSpan],
        highlights: [TextHighlight]
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: base)

        // Base styling over entire range
        let full = NSRange(location: 0, length: result.length)
        let paragraph = NSMutableParagraphStyle()
        if config.style.lineHeightMultiple > 0 {
            paragraph.lineHeightMultiple = config.style.lineHeightMultiple
        }
        paragraph.alignment = config.style.alignment
        result.addAttributes([
            .font: config.style.font,
            .foregroundColor: config.style.textColor,
            .paragraphStyle: paragraph
        ], range: full)

        // Indentation spans
        for ind in indents {
            let ps = (result.attribute(.paragraphStyle, at: ind.range.location, effectiveRange: nil) as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? paragraph.mutableCopy() as! NSMutableParagraphStyle
            ps.headIndent = ind.headIndent
            ps.tailIndent = ind.tailIndent
            ps.firstLineHeadIndent = ind.firstLineHeadIndent
            result.addAttribute(.paragraphStyle, value: ps, range: ind.range)
        }

        // Links
        for link in links {
            guard link.range.location + link.range.length <= result.length else { continue }
            result.addAttribute(.init("UITextItemTag"), value: link.tag, range: link.range)
            result.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: link.range)
            result.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: link.range)
        }

        // Highlights overlay
        for h in highlights {
            guard h.range.location + h.range.length <= result.length else { continue }
            result.addAttributes([
                .backgroundColor: h.color.withAlphaComponent(0.2),
                .underlineColor: h.color.withAlphaComponent(0.7),
                .underlineStyle: NSUnderlineStyle.thick.rawValue
            ], range: h.range)
        }

        return result
    }
}

// MARK: - Representable

struct HighlightTextView: UIViewRepresentable {

    let attributedText: NSAttributedString
    let style: DocHighlightStyle
    let existingHighlights: [TextHighlight]
    let addHighlight: (NSRange, UIColor) -> Void
    let removeHighlightsInRange: (NSRange) -> Void
    let onTapLink: (String) -> Void

    /// Set to a range to scroll to it. Set to nil when consumed.
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
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Assign composed text
        if uiView.attributedText != attributedText {
            uiView.attributedText = attributedText
        }

        // Apply background color from style (do not use full-range .backgroundColor attribute)
        if uiView.backgroundColor != style.backgroundColor {
            uiView.backgroundColor = style.backgroundColor
        }

        // Scroll to requested range
        if var target = scrollTarget {
            let maxLen = uiView.attributedText?.length ?? 0
            if target.clamped(to: maxLen) != nil {
                uiView.scrollRangeToVisible(target)
                // Optionally flash selection for orientation
                uiView.selectedRange = target
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    uiView.selectedRange = NSRange(location: 0, length: 0)
                }
            }
            // Consume binding
            DispatchQueue.main.async { self.scrollTarget = nil }
        }

        // Keep a snapshot of existing highlights for menu logic
        context.coordinator.currentHighlights = existingHighlights
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: HighlightTextView
        var currentHighlights: [TextHighlight] = []

        init(_ parent: HighlightTextView) {
            self.parent = parent
        }

        // Context menu for add/remove highlight
        func textView(_ textView: UITextView,
                      editMenuForTextIn range: NSRange,
                      suggestedActions: [UIMenuElement]) -> UIMenu? {

            let palette: [(String, UIColor)] = [
                ("Yellow", UIColor(hex: "#FFEB3B")!),
                ("Green",  UIColor(hex: "#4CAF50")!),
                ("Blue",   UIColor(hex: "#2196F3")!),
                ("Pink",   UIColor(hex: "#E91E63")!),
                ("Purple", UIColor(hex: "#9C27B0")!)
            ]

            let addActions = palette.map { (name, color) in
                UIAction(title: "Highlight \(name)") { [weak self] _ in
                    guard let self else { return }
                    self.parent.addHighlight(range, color)
                }
            }

            let intersects = currentHighlights.contains { NSIntersectionRange($0.range, range).length > 0 }
            let removeAction = UIAction(title: "Remove Highlight", attributes: .destructive) { [weak self] _ in
                self?.parent.removeHighlightsInRange(range)
            }

            var children: [UIMenuElement] = [UIMenu(title: "Add Highlight", children: addActions)]
            if intersects { children.insert(removeAction, at: 0) }

            // You can append extra developer actions here:
            // children.append(UIMenu(title: "Custom", children: [ ... ]))
            return UIMenu(children: children)
        }

        // Handle tagged link taps (uses UITextItemTag)
        func textView(_ textView: UITextView,
                      menuConfigurationFor textItem: UITextItem,
                      defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
            if case .tag(let tagStr) = textItem.content {
                parent.onTapLink(tagStr)
                return nil
            }
            return .init(menu: defaultMenu)
        }
    }
}

// MARK: - Composite SwiftUI View

public struct DocHighlightingView: View {
    // Inputs
    private let baseContent: NSAttributedString
    private var config: DocHighlightConfig

    // External callbacks
    private var onLinkTap: (String) -> Void

    // State
    @StateObject private var viewModel = DocHighlightViewModel()
    @State private var showHighlights = false
    @State private var scrollTarget: NSRange? = nil

    public init(
        string: String,
        config: DocHighlightConfig = DocHighlightConfig(),
        onLinkTap: @escaping (String) -> Void = { _ in }
    ) {
        self.baseContent = NSAttributedString(string: string)
        self.config = config
        self.onLinkTap = onLinkTap
    }

    public init(
        attributedString: NSAttributedString,
        config: DocHighlightConfig = DocHighlightConfig(),
        onLinkTap: @escaping (String) -> Void = { _ in }
    ) {
        self.baseContent = attributedString
        self.config = config
        self.onLinkTap = onLinkTap
    }

    // Precompute rule spans only when content changes
    private var linkSpans: [LinkSpan] {
        guard config.enableLinks, let f = config.linkDetector else { return [] }
        return f(baseContent.string as NSString)
    }

    private var indentSpans: [IndentSpan] {
        guard config.enableIndentation, let f = config.indentationComputer else { return [] }
        return f(baseContent.string as NSString)
    }

    // Composed attributed string for current state
    private var composed: NSAttributedString {
        AttributedComposer.compose(
            content: baseContent,
            config: config,
            links: linkSpans,
            indents: indentSpans,
            highlights: viewModel.highlights
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            HighlightTextView(
                attributedText: composed,
                style: config.style,
                existingHighlights: viewModel.highlights,
                addHighlight: { range, color in
                    viewModel.addHighlight(range: range, color: color, in: baseContent)
                },
                removeHighlightsInRange: { range in
                    viewModel.removeHighlights(intersecting: range)
                },
                onTapLink: onLinkTap,
                scrollTarget: $scrollTarget
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            HStack {
                Button {
                    showHighlights.toggle()
                } label: {
                    Label("Highlights", systemImage: "highlighter")
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showHighlights) {
            HighlightListView(
                highlights: viewModel.highlights,
                content: baseContent.string as NSString,
                onSelect: { id in
                    if let h = viewModel.highlight(with: id) {
                        scrollTarget = h.range
                    }
                    showHighlights = false
                },
                onDelete: { id in
                    viewModel.removeHighlight(id: id)
                }
            )
        }
    }
}

// MARK: - Highlights List UI

struct HighlightListView: View {
    let highlights: [TextHighlight]
    let content: NSString
    var onSelect: (UUID) -> Void
    var onDelete: (UUID) -> Void

    var body: some View {
        NavigationView {
            List {
                if highlights.isEmpty {
                    Text("No highlights")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(highlights) { h in
                        Button {
                            onSelect(h.id)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Color(safe: h.color)
                                    .frame(width: 12, height: 12)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                                    .padding(.top, 3)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(snippet(for: h.range))
                                        .lineLimit(3)
                                        .font(.body)
                                    Text("location \(h.range.location) • length \(h.range.length)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { onDelete(h.id) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Highlights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func snippet(for range: NSRange, context: Int = 40) -> String {
        guard range.location >= 0, range.location + range.length <= content.length else { return "" }
        let start = max(range.location - context, 0)
        let end = min(range.location + range.length + context, content.length)
        let nsr = NSRange(location: start, length: end - start)
        var s = content.substring(with: nsr)
        // Emphasize selected portion with simple markers
        let relStart = range.location - start
        let relEnd = relStart + range.length
        if relStart >= 0, relEnd <= s.count {
            let idxStart = s.index(s.startIndex, offsetBy: relStart)
            let idxEnd = s.index(s.startIndex, offsetBy: relEnd)
            s.replaceSubrange(idxEnd..<idxEnd, with: "»")
            s.replaceSubrange(idxStart..<idxStart, with: "«")
        }
        return s
    }
}

private extension Color {
    init(safe ui: UIColor) {
        self.init(UIColor(red: ui.cgColor.components?[0] ?? 0,
                          green: ui.cgColor.components?[1] ?? 0,
                          blue: ui.cgColor.components?[2] ?? 0,
                          alpha: ui.cgColor.alpha))
    }
}

// MARK: - Preview

struct DocHighlightingView_Previews: PreviewProvider {
    static let sample = """
    Article 1

    1. This Regulation lays down rules.
    (a) It applies to providers.
    (i) Sub-point with details.
    • Bullet one.

    Article 2

    1. Scope and definitions apply here.
    """

    static var previews: some View {
        DocHighlightingView(string: sample) { tag in
            print("Tapped tag:", tag) // e.g., "link:article_1"
        }
        .previewDisplayName("DocHighlightingView")
    }
}
