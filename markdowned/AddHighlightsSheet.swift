//
//  AddHighlightsSheet.swift
//  markdowned
//
//  Sheet for selecting highlights to add to a composition
//

import SwiftUI

struct AddHighlightsSheet: View {
    let compositionId: UUID

    @ObservedObject private var highlightsManager = HighlightsManager.shared
    @ObservedObject private var documentsManager = DocumentsManager.shared
    @ObservedObject private var compositionsManager = CompositionsManager.shared

    @Environment(\.dismiss) private var dismiss

    @State private var selectedHighlightIds: Set<UUID> = []
    @State private var searchText = ""

    // Get existing fragment highlight IDs to exclude
    private var existingHighlightIds: Set<UUID> {
        guard let composition = compositionsManager.composition(withId: compositionId) else {
            return []
        }
        return Set(composition.fragments.map { $0.highlightId })
    }

    // Group highlights by document, excluding already-added ones
    private var availableHighlights: [HighlightGroup] {
        let allHighlights = highlightsManager.allHighlights()
        let filtered = allHighlights.filter { !existingHighlightIds.contains($0.highlight.id) }

        // Apply search filter
        let searched: [(documentId: UUID, highlight: DHTextHighlight)]
        if searchText.isEmpty {
            searched = filtered
        } else {
            searched = filtered.filter { item in
                guard let document = documentsManager.document(withId: item.documentId) else {
                    return false
                }
                let snippet = extractSnippet(for: item.highlight, in: document)
                return snippet.localizedCaseInsensitiveContains(searchText) ||
                       document.title.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Group by document
        let grouped = Dictionary(grouping: searched) { $0.documentId }

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

    var body: some View {
        NavigationStack {
            Group {
                if availableHighlights.isEmpty {
                    emptyState
                } else {
                    highlightsList
                }
            }
            .navigationTitle("Add Highlights")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search highlights")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedHighlightIds.count))") {
                        addSelectedHighlights()
                    }
                    .disabled(selectedHighlightIds.isEmpty)
                }
            }
        }
        .onAppear {
            print("🔍 AddHighlightsSheet appeared")
            print("📊 Available highlights count: \(availableHighlights.count)")
            print("📚 Total highlights: \(highlightsManager.allHighlights().count)")
            print("✅ Existing highlight IDs: \(existingHighlightIds.count)")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Highlights Available", systemImage: "highlighter")
        } description: {
            if existingHighlightIds.isEmpty {
                Text("Create highlights in your documents first, then add them here")
            } else {
                Text("All your highlights have been added to this composition")
            }
        }
    }

    private var highlightsList: some View {
        List {
            ForEach(availableHighlights, id: \.documentId) { group in
                Section {
                    ForEach(group.highlights) { highlight in
                        Button {
                            toggleSelection(for: highlight.id)
                        } label: {
                            HStack {
                                Image(systemName: selectedHighlightIds.contains(highlight.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedHighlightIds.contains(highlight.id) ? .blue : .secondary)
                                highlightRow(highlight: highlight, documentId: group.documentId)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(group.documentTitle)
                }
            }
        }
    }
    
    private func toggleSelection(for id: UUID) {
        if selectedHighlightIds.contains(id) {
            selectedHighlightIds.remove(id)
        } else {
            selectedHighlightIds.insert(id)
        }
    }

    private func highlightRow(highlight: DHTextHighlight, documentId: UUID) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(platformColor: highlight.color))
                .frame(width: 12, height: 12)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                if let document = documentsManager.document(withId: documentId) {
                    Text(extractSnippet(for: highlight, in: document))
                        .font(.body)
                        .lineLimit(3)
                }

                Text("Location: \(highlight.range.location)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func extractSnippet(for highlight: DHTextHighlight, in document: Document, maxLength: Int = 150) -> String {
        let text: String
        switch document.content {
        case .plain(let s):
            text = s
        case .attributed(let a):
            text = a.string
        }

        let nsString = text as NSString
        guard highlight.range.location >= 0,
              highlight.range.location + highlight.range.length <= nsString.length else {
            return ""
        }

        let snippet = nsString.substring(with: highlight.range)
        if snippet.count > maxLength {
            return String(snippet.prefix(maxLength)) + "…"
        }
        return snippet
    }

    private func addSelectedHighlights() {
        do {
            try compositionsManager.addHighlights(Array(selectedHighlightIds), to: compositionId)
            dismiss()
        } catch {
            print("Failed to add highlights: \(error)")
        }
    }
}

// MARK: - Supporting Types

private struct HighlightGroup {
    let documentId: UUID
    let documentTitle: String
    let highlights: [DHTextHighlight]
}

#Preview {
    AddHighlightsSheet(compositionId: UUID())
}
