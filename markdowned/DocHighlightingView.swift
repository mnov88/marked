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
    private var baseConfig: DHConfig  // Base config without theme
    private var onLinkTap: (URL) -> Void

    // Cache spans computed from baseContent
    private let cachedLinkSpans: [DHLinkSpan]
    private let cachedIndentSpans: [DHIndentSpan]

    @StateObject private var vm: DHViewModel
    @State private var showList = false
    @State private var scrollTarget: NSRange? = nil
    @EnvironmentObject private var themeManager: ThemeManager

    // Computed config that reacts to theme changes
    private var config: DHConfig {
        var cfg = baseConfig
        cfg.style = themeManager.currentTheme.toDHStyle()
        cfg.usePageLayout = themeManager.currentTheme.usePageLayout
        return cfg
    }

    // Plain string init
    init(documentId: UUID,
         string: String,
         config: DHConfig = DHConfig(),
         initialScrollTarget: NSRange? = nil,
         onLinkTap: @escaping (URL) -> Void = { _ in }) {
        let base = NSAttributedString(string: string)
        self.documentId = documentId
        self.baseContent = base
        self.baseConfig = config  // Store base config without theme
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
        self.baseConfig = config  // Store base config without theme
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
            if config.usePageLayout {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
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
                        scrollTarget: $scrollTarget
                    )
                    .frame(maxWidth: 800, maxHeight: .infinity)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
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
                    scrollTarget: $scrollTarget
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            HStack {
                Button {
                    showList.toggle()
                } label: {
                    Label("Highlights", systemImage: "highlighter")
                }
                .padding(.horizontal)
                Spacer()
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
    }
}

