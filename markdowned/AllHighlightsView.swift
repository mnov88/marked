//
//  AllHighlightsView.swift
//  markdowned
//
//  View showing all highlights from all documents
//

import SwiftUI

struct AllHighlightsView: View {
    @ObservedObject private var highlightsManager = HighlightsManager.shared
    @ObservedObject private var documentsManager = DocumentsManager.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var navigationTarget: NavigationTarget?

    var body: some View {
        NavigationStack {
            Group {
                if groupedHighlights.isEmpty {
                    emptyState
                } else {
                    highlightsList
                }
            }
            .navigationTitle("All Highlights")
            .navigationDestination(item: $navigationTarget) { target in
                if let document = documentsManager.document(withId: target.documentId) {
                    destinationView(for: document, scrollTo: target.highlightRange)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "highlighter")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No Highlights")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Highlights you create will appear here")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var highlightsList: some View {
        List {
            ForEach(groupedHighlights, id: \.documentId) { group in
                Section {
                    ForEach(group.highlights) { highlight in
                        highlightRow(
                            highlight: highlight,
                            documentId: group.documentId,
                            documentTitle: group.documentTitle
                        )
                    }
                } header: {
                    Text(group.documentTitle)
                        .font(.headline)
                }
            }
        }
    }

    private func highlightRow(
        highlight: DHTextHighlight,
        documentId: UUID,
        documentTitle: String
    ) -> some View {
        Button {
            navigationTarget = NavigationTarget(documentId: documentId, highlightRange: highlight.range)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Color(uiColor: highlight.color)
                    .frame(width: 12, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .padding(.top, 3)

                VStack(alignment: .leading, spacing: 4) {
                    if let document = documentsManager.document(withId: documentId) {
                        Text(snippet(for: highlight, in: document))
                            .font(.body)
                            .lineLimit(3)
                            .foregroundStyle(.primary)
                    }
                    Text("Location: \(highlight.range.location) • Length: \(highlight.range.length)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .swipeActions {
            Button(role: .destructive) {
                highlightsManager.removeHighlight(id: highlight.id, from: documentId)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

    private var groupedHighlights: [HighlightGroup] {
        let allHighlights = highlightsManager.allHighlights()
        let grouped = Dictionary(grouping: allHighlights) { $0.documentId }

        return grouped.compactMap { documentId, items in
            guard let document = documentsManager.document(withId: documentId) else { return nil }
            return HighlightGroup(
                documentId: documentId,
                documentTitle: document.title,
                highlights: items.map { $0.highlight }
            )
        }
        .sorted { $0.documentTitle < $1.documentTitle }
    }

    private func snippet(for highlight: DHTextHighlight, in document: Document, context: Int = 40) -> String {
        let text: String
        switch document.content {
        case .plain(let s):
            text = s
        case .attributed(let a):
            text = a.string
        }

        let backingString = text as NSString
        guard highlight.range.location >= 0,
              highlight.range.location + highlight.range.length <= backingString.length else {
            return ""
        }

        let full = text
        guard let textRange = Range(highlight.range, in: full) else { return "" }

        let startUTF16 = full.utf16.index(
            full.utf16.startIndex,
            offsetBy: max(highlight.range.location - context, 0),
            limitedBy: full.utf16.endIndex
        ) ?? full.utf16.startIndex

        let endUTF16 = full.utf16.index(
            full.utf16.startIndex,
            offsetBy: min(highlight.range.location + highlight.range.length + context, full.utf16.count),
            limitedBy: full.utf16.endIndex
        ) ?? full.utf16.endIndex

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

    @ViewBuilder
    private func destinationView(for document: Document, scrollTo range: NSRange?) -> some View {
        let config = makeConfig()

        switch document.content {
        case .plain(let s):
            DocHighlightingView(
                documentId: document.id,
                string: s,
                config: config,
                initialScrollTarget: range
            ) { url in
                print("Tapped link:", url.absoluteString)
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
        case .attributed(let a):
            DocHighlightingView(
                documentId: document.id,
                attributedString: a,
                config: config,
                initialScrollTarget: range
            ) { url in
                print("Tapped link:", url.absoluteString)
            }
            .navigationTitle(document.title)
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

// MARK: - Supporting Types

private struct NavigationTarget: Identifiable, Hashable {
    let id = UUID()
    let documentId: UUID
    let highlightRange: NSRange

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: NavigationTarget, rhs: NavigationTarget) -> Bool {
        lhs.id == rhs.id
    }
}

private struct HighlightGroup {
    let documentId: UUID
    let documentTitle: String
    let highlights: [DHTextHighlight]
}

extension UUID: Identifiable {
    public var id: UUID { self }
}

#Preview {
    AllHighlightsView()
        .environmentObject(ThemeManager())
}
