////
////  DocHighlighter.swift
////  Reusable in-memory document highlighter
////
//
//import SwiftUI
//import UIKit
//import Combine
//
//// MARK: - Utilities
//
//// MARK: - Models (namespaced to avoid collisions)
//
//struct DHTextHighlight: Identifiable, Equatable {
//    let id: UUID
//    let range: NSRange
//    let color: UIColor
//
//    init(id: UUID = UUID(), range: NSRange, color: UIColor) {
//        self.id = id
//        self.range = range
//        self.color = color
//    }
//}
//
//struct DHLinkSpan: Identifiable, Equatable {
//    let id: UUID
//    let range: NSRange
//    let tag: String
//}
//
//struct DHIndentSpan: Identifiable, Equatable {
//    let id: UUID
//    let range: NSRange
//    let headIndent: CGFloat
//    let tailIndent: CGFloat
//    let firstLineHeadIndent: CGFloat
//}
//
//// MARK: - Configuration
//
//struct DHStyle {
//    var font: UIFont = .preferredFont(forTextStyle: .body)
//    var textColor: UIColor = .label
//    var backgroundColor: UIColor = .systemBackground
//    var lineHeightMultiple: CGFloat = 1.2
//    var alignment: NSTextAlignment = .left
//    var contentInsets: UIEdgeInsets = .init(top: 24, left: 16, bottom: 24, right: 16)
//}
//
//struct DHConfig {
//    var style = DHStyle()
//    var enableLinks = true
//    var enableIndentation = true
//
//    /// Rule providers. Defaults are safe examples.
//    var linkDetector: ((NSString) -> [DHLinkSpan])? = DHConfig.defaultArticleLinks
//    var indentationComputer: ((NSString) -> [DHIndentSpan])? = DHConfig.defaultIndentation
//
//    static func defaultArticleLinks(_ s: NSString) -> [DHLinkSpan] {
//        let pattern = #"Article\s+(\d+)"#
//        guard let re = try? NSRegularExpression(pattern: pattern) else { return [] }
//        let full = NSRange(location: 0, length: s.length)
//        return re.matches(in: s as String, range: full).map { m in
//            let n = (s.substring(with: m.range(at: 1)) as NSString).integerValue
//            return DHLinkSpan(id: UUID(), range: m.range, tag: "link:article_\(n)")
//        }
//    }
//
//    static func defaultIndentation(_ s: NSString) -> [DHIndentSpan] {
//        var spans: [DHIndentSpan] = []
//        let base: CGFloat = 20
//        let re1 = try? NSRegularExpression(pattern: #"^\d+\."#, options: [.anchorsMatchLines])
//        let re2 = try? NSRegularExpression(pattern: #"^\([a-zA-Z]\)"#, options: [.anchorsMatchLines])
//        let re3 = try? NSRegularExpression(pattern: #"^\([ivxlcdmIVXLCDM]+\)"#, options: [.anchorsMatchLines])
//
//        for pr in s.paragraphRanges() {
//            let p = s.substring(with: pr) as NSString
//            let level: Int
//            if re1?.firstMatch(in: p as String, range: NSRange(location: 0, length: p.length)) != nil {
//                level = 0
//            } else if re2?.firstMatch(in: p as String, range: NSRange(location: 0, length: p.length)) != nil {
//                level = 1
//            } else if re3?.firstMatch(in: p as String, range: NSRange(location: 0, length: p.length)) != nil {
//                level = 2
//            } else if p.hasPrefix("–") || p.hasPrefix("—") || p.hasPrefix("•") {
//                level = 3
//            } else { level = 0 }
//
//            let indent = CGFloat(level) * base + base
//            spans.append(DHIndentSpan(id: UUID(),
//                                      range: pr,
//                                      headIndent: indent,
//                                      tailIndent: -indent,
//                                      firstLineHeadIndent: indent))
//        }
//        return spans
//    }
//}
//
//
//@MainActor
//final class DHViewModel: ObservableObject {
//    @Published var highlights: [DHTextHighlight] = []
//
//    func add(range: NSRange, color: UIColor, in text: NSAttributedString) {
//        guard range.clamped(toStringLength: text.length) != nil else { return }
//        highlights.append(DHTextHighlight(range: range, color: color))
//    }
//
//    func remove(intersecting range: NSRange) {
//        highlights.removeAll { NSIntersectionRange($0.range, range).length > 0 }
//    }
//
//    func remove(id: UUID) {
//        highlights.removeAll { $0.id == id }
//    }
//
//    func highlight(id: UUID) -> DHTextHighlight? {
//        highlights.first { $0.id == id }
//    }
//}
//
//// MARK: - Composer
//
//struct DHComposer {
//    static func compose(
//        base: NSAttributedString,
//        config: DHConfig,
//        links: [DHLinkSpan],
//        indents: [DHIndentSpan],
//        highlights: [DHTextHighlight]
//    ) -> NSAttributedString {
//        let out = NSMutableAttributedString(attributedString: base)
//        let full = NSRange(location: 0, length: out.length)
//
//        // Base style
//        let p = NSMutableParagraphStyle()
//        if config.style.lineHeightMultiple > 0 {
//            p.lineHeightMultiple = config.style.lineHeightMultiple
//        }
//        p.alignment = config.style.alignment
//        out.addAttributes([.font: config.style.font,
//                           .foregroundColor: config.style.textColor,
//                           .paragraphStyle: p], range: full)
//
//        // Indentation
//        for ind in indents {
//            guard ind.range.location + ind.range.length <= out.length else { continue }
//            let ps = (out.attribute(.paragraphStyle, at: ind.range.location, effectiveRange: nil) as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? p.mutableCopy() as! NSMutableParagraphStyle
//            ps.headIndent = ind.headIndent
//            ps.tailIndent = ind.tailIndent
//            ps.firstLineHeadIndent = ind.firstLineHeadIndent
//            out.addAttribute(.paragraphStyle, value: ps, range: ind.range)
//        }
//
//        // Links
//        for l in links {
//            guard l.range.location + l.range.length <= out.length else { continue }
//            out.addAttribute(.init("UITextItemTag"), value: l.tag, range: l.range)
//            out.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: l.range)
//            out.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: l.range)
//        }
//
//        // Highlights overlay
//        for h in highlights {
//            guard h.range.location + h.range.length <= out.length else { continue }
//            out.addAttributes([
//                .backgroundColor: h.color.withAlphaComponent(0.2),
//                .underlineColor: h.color.withAlphaComponent(0.7),
//                .underlineStyle: NSUnderlineStyle.thick.rawValue
//            ], range: h.range)
//        }
//
//        return out
//    }
//}
//
//// MARK: - UITextView bridge (namespaced)
//
//struct DHTextView: UIViewRepresentable {
//    let attributedText: NSAttributedString
//    let style: DHStyle
//    let highlightsSnapshot: [DHTextHighlight]
//    let addHighlight: (NSRange, UIColor) -> Void
//    let removeHighlightsInRange: (NSRange) -> Void
//    let onTapLink: (String) -> Void
//    @Binding var scrollTarget: NSRange?
//
//    func makeCoordinator() -> Coordinator { Coordinator(self) }
//
//    func makeUIView(context: Context) -> UITextView {
//        let tv = UITextView()
//        tv.delegate = context.coordinator
//        tv.isEditable = false
//        tv.isSelectable = true
//        tv.isScrollEnabled = true
//        tv.adjustsFontForContentSizeCategory = true
//        tv.textContainerInset = style.contentInsets
//        tv.textContainer.lineFragmentPadding = 8
//        tv.backgroundColor = style.backgroundColor
//        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        return tv
//    }
//
//    func updateUIView(_ uiView: UITextView, context: Context) {
//        uiView.attributedText = attributedText
//        if uiView.backgroundColor != style.backgroundColor {
//            uiView.backgroundColor = style.backgroundColor
//        }
//
//        // Scroll target
//        if var target = scrollTarget {
//            if target.clamped(toStringLength: uiView.attributedText?.length ?? 0) != nil {
//                uiView.scrollRangeToVisible(target)
//                uiView.selectedRange = target
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
//                    uiView.selectedRange = NSRange(location: 0, length: 0)
//                }
//            }
//            DispatchQueue.main.async { self.scrollTarget = nil }
//        }
//
//        context.coordinator.currentHighlights = highlightsSnapshot
//    }
//
//    final class Coordinator: NSObject, UITextViewDelegate {
//        var parent: DHTextView
//        var currentHighlights: [DHTextHighlight] = []
//
//        init(_ parent: DHTextView) { self.parent = parent }
//
//        // Add/Remove highlight menu
//        func textView(_ textView: UITextView,
//                      editMenuForTextIn range: NSRange,
//                      suggestedActions: [UIMenuElement]) -> UIMenu? {
//
//            let palette: [(String, UIColor)] = [
//                ("Yellow", UIColor(hex: "#FFEB3B")!),
//                ("Green",  UIColor(hex: "#4CAF50")!),
//                ("Blue",   UIColor(hex: "#2196F3")!),
//                ("Pink",   UIColor(hex: "#E91E63")!),
//                ("Purple", UIColor(hex: "#9C27B0")!)
//            ]
//
//            let add = palette.map { name, color in
//                UIAction(title: "Highlight \(name)") { [weak self] _ in
//                    self?.parent.addHighlight(range, color)
//                }
//            }
//
//            let intersects = currentHighlights.contains { NSIntersectionRange($0.range, range).length > 0 }
//            let remove = UIAction(title: "Remove Highlight", attributes: .destructive) { [weak self] _ in
//                self?.parent.removeHighlightsInRange(range)
//            }
//
//            var items: [UIMenuElement] = [UIMenu(title: "Add Highlight", children: add)]
//            if intersects { items.insert(remove, at: 0) }
//
//            // Placeholder for developer custom actions (append more menus here)
//
//            return UIMenu(children: items)
//        }
//
//        // Tagged link taps
//        func textView(_ textView: UITextView,
//                      menuConfigurationFor textItem: UITextItem,
//                      defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
//            if case .tag(let tagStr) = textItem.content {
//                parent.onTapLink(tagStr)
//                return nil
//            }
//            return .init(menu: defaultMenu)
//        }
//    }
//}
//
//// MARK: - Highlights list (namespaced)
//
//struct DHHighlightList: View {
//    let highlights: [DHTextHighlight]
//    let backingString: NSString
//    var onSelect: (UUID) -> Void
//    var onDelete: (UUID) -> Void
//
//    var body: some View {
//        NavigationView {
//            List {
//                if highlights.isEmpty {
//                    Text("No highlights").foregroundStyle(.secondary)
//                } else {
//                    ForEach(highlights) { h in
//                        Button {
//                            onSelect(h.id)
//                        } label: {
//                            HStack(alignment: .top, spacing: 12) {
//                                Color(uiColor: h.color)
//                                    .frame(width: 12, height: 12)
//                                    .clipShape(RoundedRectangle(cornerRadius: 3))
//                                    .padding(.top, 3)
//                                VStack(alignment: .leading, spacing: 4) {
//                                    Text(snippet(for: h.range))
//                                        .font(.body)
//                                        .lineLimit(3)
//                                    Text("loc \(h.range.location) • len \(h.range.length)")
//                                        .font(.caption)
//                                        .foregroundStyle(.secondary)
//                                }
//                            }
//                        }
//                        .swipeActions {
//                            Button(role: .destructive) { onDelete(h.id) } label: {
//                                Label("Delete", systemImage: "trash")
//                            }
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Highlights")
//            .navigationBarTitleDisplayMode(.inline)
//        }
//    }
//
//    private func snippet(for range: NSRange, context: Int = 40) -> String {
//        guard range.location >= 0, range.location + range.length <= backingString.length else { return "" }
//        let start = max(range.location - context, 0)
//        let end = min(range.location + range.length + context, backingString.length)
//        let window = NSRange(location: start, length: end - start)
//        var s = backingString.substring(with: window)
//        // Mark the highlighted segment
//        let relStart = range.location - start
//        let relEnd = relStart + range.length
//        if relStart >= 0, relEnd <= s.count {
//            let a = s.index(s.startIndex, offsetBy: relStart)
//            let b = s.index(s.startIndex, offsetBy: relEnd)
//            s.replaceSubrange(b..<b, with: "»")
//            s.replaceSubrange(a..<a, with: "«")
//        }
//        return s
//    }
//}
//
//// MARK: - Composite SwiftUI view (external surface)
//
//struct DocHighlightingView: View {
//    private let baseContent: NSAttributedString
//    private var config: DHConfig
//    private var onLinkTap: (String) -> Void
//
//    @StateObject private var vm = DHViewModel()
//    @State private var showList = false
//    @State private var scrollTarget: NSRange? = nil
//
//    init(string: String,
//         config: DHConfig = DHConfig(),
//         onLinkTap: @escaping (String) -> Void = { _ in }) {
//        self.baseContent = NSAttributedString(string: string)
//        self.config = config
//        self.onLinkTap = onLinkTap
//    }
//
//    init(attributedString: NSAttributedString,
//         config: DHConfig = DHConfig(),
//         onLinkTap: @escaping (String) -> Void = { _ in }) {
//        self.baseContent = attributedString
//        self.config = config
//        self.onLinkTap = onLinkTap
//    }
//
//    private var linkSpans: [DHLinkSpan] {
//        guard config.enableLinks, let f = config.linkDetector else { return [] }
//        return f(baseContent.string as NSString)
//    }
//
//    private var indentSpans: [DHIndentSpan] {
//        guard config.enableIndentation, let f = config.indentationComputer else { return [] }
//        return f(baseContent.string as NSString)
//    }
//
//    private var composed: NSAttributedString {
//        DHComposer.compose(base: baseContent,
//                           config: config,
//                           links: linkSpans,
//                           indents: indentSpans,
//                           highlights: vm.highlights)
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            DHTextView(
//                attributedText: composed,
//                style: config.style,
//                highlightsSnapshot: vm.highlights,
//                addHighlight: { range, color in
//                    vm.add(range: range, color: color, in: baseContent)
//                },
//                removeHighlightsInRange: { range in
//                    vm.remove(intersecting: range)
//                },
//                onTapLink: onLinkTap,
//                scrollTarget: $scrollTarget
//            )
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//
//            Divider()
//
//            HStack {
//                Button {
//                    showList.toggle()
//                } label: {
//                    Label("Highlights", systemImage: "highlighter")
//                }
//                .padding(.horizontal)
//                Spacer()
//            }
//            .padding(.vertical, 8)
//        }
//        .sheet(isPresented: $showList) {
//            DHHighlightList(
//                highlights: vm.highlights,
//                backingString: baseContent.string as NSString,
//                onSelect: { id in
//                    if let h = vm.highlight(id: id) { scrollTarget = h.range }
//                    showList = false
//                },
//                onDelete: { id in
//                    vm.remove(id: id)
//                }
//            )
//        }
//    }
//}
//
//// MARK: - Preview
//
//struct DocHighlighter_Previews: PreviewProvider {
// static var previews: some View {
//        
//        MockDocList()
//    }
//}
//
////
////  MockDocList.swift
////
//
//import SwiftUI
//import Foundation
//
//// Simple model
//struct MockDoc: Identifiable, Hashable {
//    enum Content: Hashable {
//        case plain(String)
//        case attributed(NSAttributedString)
//    }
//
//    let id: UUID
//    let title: String
//    let content: Content
//}
//
//// Sample data
//private let mockDocs: [MockDoc] = {
//    let s1 = LoremGen.plain(paragraphs: 70)
//    let s2 = LoremGen.plain(paragraphs: 30)
//    // Attributed example; base styling will be applied by the highlighter anyway
//    let attr = NSMutableAttributedString(string: "Article 4\n\n1. Mixed content for demo.")
//    return [
//        MockDoc(id: UUID(), title: "Regulation — Part I", content: .plain(s1)),
//        MockDoc(id: UUID(), title: "Regulation — Part II", content: .plain(s2)),
//        MockDoc(id: UUID(), title: "Regulation — Part III (Attributed)", content: .attributed(attr))
//    ]
//}()
//
//struct MockDocList: View {
//    @State private var docs = mockDocs
//
//    var body: some View {
//        NavigationStack {
//            List(docs) { doc in
//                NavigationLink(doc.title) {
//                    destination(for: doc)
//                        .navigationTitle(doc.title)
//                        .navigationBarTitleDisplayMode(.inline)
//                }
//            }
//            .navigationTitle("Documents")
//        }
//    }
//
//    @ViewBuilder
//    private func destination(for doc: MockDoc) -> some View {
//        switch doc.content {
//        case .plain(let s):
//            DocHighlightingView(string: s) { tag in
//                // Handle link taps if you later add routing
//                print("Tapped tag:", tag)
//            }
//        case .attributed(let a):
//            DocHighlightingView(attributedString: a) { tag in
//                print("Tapped tag:", tag)
//            }
//        }
//    }
//}
//
// 
//import Foundation
//
//// MARK: - Lorem generator
//
//enum LoremGen {
//    // Deterministic RNG for reproducibility
//    private struct LCG {
//        var state: UInt64
//        mutating func next() -> UInt64 { state = state &* 6364136223846793005 &+ 1; return state }
//        mutating func int(_ upper: Int) -> Int { Int(next() % UInt64(upper)) }
//        mutating func inRange(_ lower: Int, _ upper: Int) -> Int { lower + int(max(1, upper - lower)) }
//    }
//
//    private static let words: [String] = """
//    lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore
//    et dolore magna aliqua ut enim ad minim veniam quis nostrud exercitation ullamco laboris nisi ut
//    aliquip ex ea commodo consequat duis aute irure dolor in reprehenderit in voluptate velit esse
//    cillum dolore eu fugiat nulla pariatur excepteur sint occaecat cupidatat non proident sunt in culpa
//    qui officia deserunt mollit anim id est laborum regulation directive article recital provider service
//    market competition consumer protection transparency proportionality necessity subsidiarity paragraph
//    annex annexes competent authority procedure enforcement compliance interpretation judgement order
//    """.split(separator: " ").map(String.init)
//
//    // Plain lorem: paragraphs × ~avgWords, deterministic by seed
//    static func plain(paragraphs: Int, avgWords: Int = 120, seed: UInt64 = 1) -> String {
//        var rng = LCG(state: max(1, seed))
//        var out = String()
//        out.reserveCapacity(paragraphs * avgWords * 6)
//        for p in 0..<max(1, paragraphs) {
//            let wc = max(12, rng.inRange(Int(Double(avgWords) * 7/10), Int(Double(avgWords) * 13/10)))
//            for i in 0..<wc {
//                let w = words[rng.int(words.count)]
//                if i == 0 { out.append(w.capitalized) } else { out.append(w) }
//                out.append(i == wc - 1 ? "." : (i % 15 == 14 ? ", " : " "))
//            }
//            if p < paragraphs - 1 { out.append("\n\n") }
//        }
//        return out
//    }
//
//    // Legal-ish lorem with Article headings and list levels to exercise link/indent rules
//    static func legalish(articles: Int = 20, sectionsPerArticle: Int = 3, pointsPerSection: Int = 4, seed: UInt64 = 2) -> String {
//        var rng = LCG(state: max(1, seed))
//        var out = String()
//        out.reserveCapacity(articles * sectionsPerArticle * pointsPerSection * 100)
//        for a in 1...max(1, articles) {
//            out.append("Article \(a)\n\n")
//            for s in 1...max(1, sectionsPerArticle) {
//                out.append("\(s). "); out.append(sentence(words: &rng, min: 12, max: 22)); out.append("\n")
//                let letter = Character(UnicodeScalar(97 + (s - 1) % 26)!)
//                out.append("(\(letter)) "); out.append(sentence(words: &rng, min: 10, max: 18)); out.append("\n")
//                out.append("(i) "); out.append(sentence(words: &rng, min: 8, max: 16)); out.append("\n")
//                for _ in 0..<max(1, pointsPerSection) {
//                    out.append("• "); out.append(sentence(words: &rng, min: 8, max: 14)); out.append("\n")
//                }
//                if a > 1 && rng.int(3) == 0 {
//                    out.append("See Article \(rng.inRange(1, a)).\n")
//                }
//                out.append("\n")
//            }
//        }
//        return out
//    }
//
//    // Build a large string quickly by doubling a base block, then trimming to >= targetChars
//    static func approximateCharacters(_ targetChars: Int, baseParagraphs: Int = 12, seed: UInt64 = 3) -> String {
//        precondition(targetChars > 0)
//        var s = plain(paragraphs: max(1, baseParagraphs), avgWords: 120, seed: seed) + "\n\n" + legalish(articles: 4, seed: seed &* 97)
//        while s.count < targetChars { s += s }            // exponential growth (O(n))
//        if s.count == targetChars { return s }
//        let end = s.index(s.startIndex, offsetBy: targetChars)
//        return String(s[..<end])
//    }
//
//    // Helpers
//    private static func sentence(words rng: inout LCG, min: Int, max: Int) -> String {
//        let n = rng.inRange(min, max)
//        var s = ""
//        for i in 0..<n {
//            var w = words[rng.int(words.count)]
//            if i == 0 { w = w.capitalized }
//            s += w
//            s += i == n - 1 ? "." : (i % 10 == 9 ? ", " : " ")
//        }
//        return s
//    }
//}
//
//
//extension UIColor {
//    convenience init?(hex: String) {
//        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
//        if s.hasPrefix("#") { s.removeFirst() }
//        guard s.count == 6, let rgb = UInt32(s, radix: 16) else { return nil }
//        self.init(red: CGFloat((rgb >> 16) & 0xFF)/255.0,
//                  green: CGFloat((rgb >> 8) & 0xFF)/255.0,
//                  blue: CGFloat(rgb & 0xFF)/255.0,
//                  alpha: 1.0)
//    }
//}
//
//extension NSRange {
//    /// Returns self if it fits inside `stringLength`, else nil.
//    func clamped(toStringLength stringLength: Int) -> NSRange? {
//        guard location >= 0, length >= 0 else { return nil }
//        let end = location + length
//        guard end <= stringLength else { return nil }
//        return self
//    }
//}
//
//private extension NSString {
//    func paragraphRanges() -> [NSRange] {
//        var ranges: [NSRange] = []
//        var pos = 0
//        while pos < length {
//            let r = lineRange(for: NSRange(location: pos, length: 0))
//            ranges.append(r)
//            pos = r.location + r.length
//        }
//        return ranges
//    }
//}

//
//  DocHighlighter.swift
//  iOS 18+
//

import SwiftUI
import UIKit
import Combine


// MARK: - Highlights list

struct DHHighlightList: View {
    let highlights: [DHTextHighlight]
    let backingString: NSString
    var onSelect: (UUID) -> Void
    var onDelete: (UUID) -> Void

    var body: some View {
        NavigationStack {
            List {
                if highlights.isEmpty {
                    Text("No highlights").foregroundStyle(.secondary)
                } else {
                    ForEach(highlights) { h in
                        Button { onSelect(h.id) } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Color(uiColor: h.color)
                                    .frame(width: 12, height: 12)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                                    .padding(.top, 3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(snippet(for: h.range))
                                        .font(.body)
                                        .lineLimit(3)
                                    Text("loc \(h.range.location) • len \(h.range.length)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .swipeActions {
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

    // Convert NSRange to String.Range safely using UTF-16 mapping
    private func snippet(for range: NSRange, context: Int = 40) -> String {
        let full = backingString as String
        guard let textRange = Range(range, in: full) else { return "" }

        let startUTF16 = full.utf16.index(full.utf16.startIndex, offsetBy: max(range.location - context, 0), limitedBy: full.utf16.endIndex) ?? full.utf16.startIndex
        let endUTF16 = full.utf16.index(full.utf16.startIndex, offsetBy: min(range.location + range.length + context, full.utf16.count), limitedBy: full.utf16.endIndex) ?? full.utf16.endIndex

        let start = String.Index(startUTF16, within: full) ?? full.startIndex
        let end = String.Index(endUTF16, within: full) ?? full.endIndex
        var window = String(full[start..<end])

        // Mark the highlighted segment within the window
        if let local = window.range(of: String(full[textRange])) {
            window.replaceSubrange(local.upperBound..<local.upperBound, with: "»")
            window.replaceSubrange(local.lowerBound..<local.lowerBound, with: "«")
        }
        return window
    }
}




// MARK: - Demo / Preview

private let mockDocs: [Document] = {
    let s1 = LoremGen.plain(paragraphs: 30)
    let s2 = dsaText
    let attr = NSMutableAttributedString(string: "Article 4\n\n1. Mixed content for demo.")
    return [
        Document.plain(s1, title: "Regulation — Part I"),
        Document.plain(s2, title: "Regulation — Part II"),
        Document.attributed(attr, title: "Regulation — Part III (Attributed)")
    ]
}()

struct MockDocList: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject private var documentsManager = DocumentsManager.shared
    @State private var showingURLEntry = false
    @State private var searchText = ""
    @State private var cases: [Case] = []
    @State private var isLoadingCase = false
    @State private var hasLoadedCSV = false

    private let contentLoader = ContentLoader()
    
    // Load CSV data on appear
    var body: some View {
        NavigationStack {
            List {
                // Documents section
                Section("Documents") {
                    ForEach(documentsManager.documents) { doc in
                        NavigationLink(doc.title) { destination(for: doc) }
                    }
                }
                
                // Search results section
                if !searchText.isEmpty && !filteredCases.isEmpty {
                    Section("Case Search Results") {
                        ForEach(filteredCases.prefix(20)) { caseItem in
                            Button {
                                loadCase(caseItem)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(caseItem.caseNumber)
                                        .font(.headline)
                                    if !caseItem.caseTitle.isEmpty {
                                        Text(caseItem.caseTitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    Text("CELEX: \(caseItem.judgmentCELEX)")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .disabled(isLoadingCase)
                        }
                    }
                }
            }
            .navigationTitle("Documents")
            .searchable(text: $searchText, prompt: "Search by case number or title")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingURLEntry = true
                    } label: {
                        Label("Add URL", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingURLEntry) {
                URLEntryView { document in
                    do {
                        try documentsManager.addDocument(document)
                    } catch {
                        print("Failed to persist document from URL entry: \(error)")
                    }
                }
            }
            .overlay {
                if isLoadingCase {
                    ZStack {
                        Color.black.opacity(0.3)
                        ProgressView("Loading case...")
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(10)
                    }
                    .ignoresSafeArea()
                }
            }
            .onAppear {
                if !hasLoadedCSV {
                    loadCasesFromCSV()
                    hasLoadedCSV = true
                }
            }
        }
    }
    
    private var filteredCases: [Case] {
        guard !searchText.isEmpty else { return [] }
        return cases.filter { $0.matches(searchText: searchText) }
    }
    
    private func loadCasesFromCSV() {
        // Load CSV from file if it exists, or use empty array
        guard let csvPath = Bundle.main.path(forResource: "allcases", ofType: "csv"),
              let csvString = try? String(contentsOfFile: csvPath, encoding: .utf8) else {
            print("Could not load allcases.csv from bundle")
            cases = []
            return
        }
        
        cases = CaseDataParser.parse(csvString)
        print("Loaded \(cases.count) cases from CSV")
    }
    
    private func loadCase(_ caseItem: Case) {
        guard let url = caseItem.celexURL else {
            print("No valid URL for case")
            return
        }
        
        isLoadingCase = true
        
        Task {
            do {
                // Pass the case title from CSV instead of extracting from HTML
                let document = try await contentLoader.loadContent(from: url.absoluteString, title: caseItem.displayTitle)
                try documentsManager.addDocument(document)
                isLoadingCase = false
                searchText = "" // Clear search after loading
            } catch {
                print("Failed to load case: \(error)")
                isLoadingCase = false
            }
        }
    }

    @ViewBuilder
    private func destination(for doc: Document) -> some View {
        let config = makeConfig()

        switch doc.content {
        case .plain(let s):
            DocHighlightingView(documentId: doc.id, string: s, config: config) { url in
                // Handle "dh://article/<n>"
                print("Tapped link:", url.absoluteString)
            }
            .navigationTitle(doc.title)
            .navigationBarTitleDisplayMode(.inline)
        case .attributed(let a):
            DocHighlightingView(documentId: doc.id, attributedString: a, config: config) { url in
                print("Tapped link:", url.absoluteString)
            }
            .navigationTitle(doc.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func makeConfig() -> DHConfig {
        var config = DHConfig()
        config.style = themeManager.currentTheme.toDHStyle()
        config.usePageLayout = themeManager.currentTheme.usePageLayout
        return config
    }
}

#Preview {
    MockDocList()
}
