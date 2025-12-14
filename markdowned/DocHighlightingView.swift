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
    @EnvironmentObject private var themeManager: ThemeManager
    private let documentId: UUID
    private let baseContent: NSAttributedString
    private var config: DHConfig
    private var onLinkTap: (URL) -> Void

    // Cache spans computed from baseContent
    private let cachedLinkSpans: [DHLinkSpan]
    private let cachedIndentSpans: [DHIndentSpan]
    private let cachedHeadingSpans: [DHHeadingSpan]

    @StateObject private var vm: DHViewModel
    @State private var showList = false
    @State private var showAppearance = false
    @State private var showTOC = false
    @State private var scrollTarget: NSRange? = nil
    @State private var showCompositionPicker = false
    @State private var selectedHighlightIdForComposition: UUID?

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
        self.cachedHeadingSpans = config.headingDetector?(base.string as NSString) ?? []
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
        self.cachedHeadingSpans = config.headingDetector?(attributedString.string as NSString) ?? []
        self._vm = StateObject(wrappedValue: DHViewModel(documentId: documentId))
        self._scrollTarget = State(initialValue: initialScrollTarget)
    }

    private var composed: NSAttributedString {
        DHComposer.compose(
            base: baseContent,
            config: config,
            links: cachedLinkSpans,
            indents: cachedIndentSpans,
            headings: cachedHeadingSpans,
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
                    onAddToComposition: { highlightId in
                        selectedHighlightIdForComposition = highlightId
                        showCompositionPicker = true
                    },
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
                        .labelStyle(.iconOnly)
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    showTOC.toggle()
                } label: {
                    Label("Headings", systemImage: "list.bullet.indent")
                        .labelStyle(.iconOnly)
                }
                .disabled(cachedHeadingSpans.isEmpty)
                .padding(.horizontal)

                Spacer()

                Button {
                    showAppearance.toggle()
                } label: {
                    Label("Appearance", systemImage: "textformat.size")
                        .labelStyle(.iconOnly)
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
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showCompositionPicker) {
            if let highlightId = selectedHighlightIdForComposition {
                CompositionPickerSheet(highlightId: highlightId)
            }
        }
        .sheet(isPresented: $showTOC) {
            HeadingListSheet(
                headings: cachedHeadingSpans,
                backingString: baseContent.string as NSString
            ) { span in
                scrollTarget = span.range
                showTOC = false
            }
        }
    }
}

private struct HeadingListSheet: View {
    let headings: [DHHeadingSpan]
    let backingString: NSString
    var onSelect: (DHHeadingSpan) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(headings) { heading in
                    Button {
                        onSelect(heading)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(text(for: heading))
                                    .font(heading.level == .h2 ? .headline : .subheadline)
                                    .lineLimit(2)
                                if heading.level == .h2 {
                                    Text("Section")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Subsection")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.leading, heading.level == .h3 ? 12 : 0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Headings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func text(for heading: DHHeadingSpan) -> String {
        guard NSMaxRange(heading.range) <= backingString.length else { return "" }
        return backingString.substring(with: heading.range)
    }
}
