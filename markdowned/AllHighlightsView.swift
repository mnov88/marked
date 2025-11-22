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
    @State private var showCompositionPicker = false
    @State private var selectedHighlightIdForComposition: UUID?

    // Pagination state for performance with large datasets
    @State private var displayedHighlightsPerGroup: Int = 20
    private let pageSize: Int = 20

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
            .sheet(isPresented: $showCompositionPicker) {
                if let highlightId = selectedHighlightIdForComposition {
                    CompositionPickerSheet(highlightId: highlightId)
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
                    // Show only paginated highlights for performance
                    let displayedHighlights = Array(group.highlights.prefix(displayedHighlightsPerGroup))
                    ForEach(displayedHighlights) { highlight in
                        highlightRow(
                            highlight: highlight,
                            documentId: group.documentId,
                            documentTitle: group.documentTitle
                        )
                    }

                    // "Load More" button when there are more highlights in this group
                    if group.highlights.count > displayedHighlightsPerGroup {
                        Button {
                            withAnimation {
                                displayedHighlightsPerGroup += pageSize
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Load More (\(group.highlights.count - displayedHighlightsPerGroup) remaining)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    HStack {
                        Text(group.documentTitle)
                            .font(.headline)
                        Spacer()
                        Text("\(group.highlights.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
                        Text(SnippetExtractor.extractWithContext(for: highlight, in: document))
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
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                highlightsManager.removeHighlight(id: highlight.id, from: documentId)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                selectedHighlightIdForComposition = highlight.id
                showCompositionPicker = true
            } label: {
                Label("Add to Composition", systemImage: "doc.on.doc")
            }
            .tint(.blue)
        }
        .contextMenu {
            Button {
                navigationTarget = NavigationTarget(documentId: documentId, highlightRange: highlight.range)
            } label: {
                Label("Go to Source", systemImage: "arrow.right.doc.on.clipboard")
            }

            Button {
                selectedHighlightIdForComposition = highlight.id
                showCompositionPicker = true
            } label: {
                Label("Add to Composition", systemImage: "doc.on.doc")
            }

            Divider()

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

    // Snippet extraction moved to SnippetExtractor utility (DRY)

    @ViewBuilder
    private func destinationView(for document: Document, scrollTo range: NSRange?) -> some View {
        let config = themeManager.makeDocumentConfig()

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

    // makeConfig() moved to ThemeManager.makeDocumentConfig() (DRY)
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

#Preview {
    AllHighlightsView()
        .environmentObject(ThemeManager())
}
