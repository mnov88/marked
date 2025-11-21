//
//  DocHighlightingView.swift
//  markdowned
//
//  Created by Milos Novovic on 10/11/2025.
//
import SwiftUI
import Foundation
// MARK: - Composite SwiftUI view

struct DocHighlightingView: View {
    private let documentId: UUID
    private let baseContent: NSAttributedString
    private var config: DHConfig
    private var onLinkTap: (URL) -> Void

    // Cache spans computed from baseContent
    private let cachedLinkSpans: [DHLinkSpan]
    private let cachedIndentSpans: [DHIndentSpan]

    @StateObject private var vm: DHViewModel
    @State private var showList = false
    @State private var showAppearance = false
    @State private var scrollTarget: NSRange? = nil

    // Plain string init
    init(documentId: UUID,
         string: String,
         config: DHConfig = DHConfig(),
         initialScrollTarget: NSRange? = nil,
         onLinkTap: @escaping (URL) -> Void = { _ in }) {
        let base = NSAttributedString(string: string)
        self.documentId = documentId
        self.baseContent = base
        self.config = config
        self.onLinkTap = onLinkTap
        self.cachedLinkSpans = (config.enableLinks ? (config.linkDetector?(base.string as NSString) ?? []) : [])
        self.cachedIndentSpans = (config.enableIndentation ? (config.indentationComputer?(base.string as NSString) ?? []) : [])
        self._vm = StateObject(wrappedValue: DHViewModel(documentId: documentId))
        self._scrollTarget = State(initialValue: initialScrollTarget)
    }

    // Attributed string init
    init(documentId: UUID,
         attributedString: NSAttributedString,
         config: DHConfig = DHConfig(),
         initialScrollTarget: NSRange? = nil,
         onLinkTap: @escaping (URL) -> Void = { _ in }) {
        self.documentId = documentId
        self.baseContent = attributedString
        self.config = config
        self.onLinkTap = onLinkTap
        self.cachedLinkSpans = (config.enableLinks ? (config.linkDetector?(attributedString.string as NSString) ?? []) : [])
        self.cachedIndentSpans = (config.enableIndentation ? (config.indentationComputer?(attributedString.string as NSString) ?? []) : [])
        self._vm = StateObject(wrappedValue: DHViewModel(documentId: documentId))
        self._scrollTarget = State(initialValue: initialScrollTarget)
    }

    private var composed: NSAttributedString {
        DHComposer.compose(
            base: baseContent,
            config: config,
            links: cachedLinkSpans,
            indents: cachedIndentSpans,
            highlights: vm.highlights
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                DHTextView(
                    attributedText: composed,
                    style: config.style,
                    highlightsSnapshot: vm.highlights,
                    addHighlight: { range, color in
                        vm.add(range: range, color: color, in: baseContent)
                    },
                    removeHighlightsInRange: { range in
                        vm.remove(intersecting: range)
                    },
                    onTapLink: onLinkTap,
                    scrollTarget: $scrollTarget,
                    availableWidth: geometry.size.width,
                    usePageLayout: config.usePageLayout
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            // Bottom toolbar with highlights and appearance buttons
            HStack {
                Button {
                    showList.toggle()
                } label: {
                    Label("Highlights", systemImage: "highlighter")
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    showAppearance.toggle()
                } label: {
                    Label("Appearance", systemImage: "textformat.size")
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: config.style.backgroundColor))
        .sheet(isPresented: $showList) {
            DHHighlightList(
                highlights: vm.highlights,
                backingString: baseContent.string as NSString,
                onSelect: { id in
                    if let h = vm.highlight(id: id) { scrollTarget = h.range }
                    showList = false
                },
                onDelete: { id in
                    vm.remove(id: id)
                }
            )
        }
        .sheet(isPresented: $showAppearance) {
            AppearancePanel()
        }
    }
}

