//
//  TextHighlight.swift
//  markdowned
//
//  Highlight list view and preview/demo components
//

import SwiftUI
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
                                Color(platformColor: h.color)
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
    @ObservedObject private var caseLawManager = CaseLawManager.shared
    @State private var showingURLEntry = false
    @State private var searchText = ""
    @State private var caseSearchResults: [Case] = []
    @State private var isLoadingCase = false
    @State private var searchTask: Task<Void, Never>?

    private let contentLoader = ContentLoader()

    var body: some View {
        NavigationStack {
            List {
                // Documents section
                Section("Documents") {
                    ForEach(documentsManager.documents) { doc in
                        NavigationLink(doc.title) { destination(for: doc) }
                    }
                }

                // Search results section (from database with FTS5)
                if !searchText.isEmpty && !caseSearchResults.isEmpty {
                    Section("Case Search Results") {
                        ForEach(caseSearchResults) { caseItem in
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
            .onChange(of: searchText) { _, newValue in
                performCaseSearch(query: newValue)
            }
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
        }
    }

    /// Perform case search with debouncing (database FTS5)
    private func performCaseSearch(query: String) {
        searchTask?.cancel()

        guard !query.isEmpty else {
            caseSearchResults = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms debounce
            guard !Task.isCancelled else { return }

            let results = caseLawManager.searchCases(query: query, limit: 30)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                caseSearchResults = results
            }
        }
    }

    private func loadCase(_ caseItem: Case) {
        guard let url = caseItem.celexURL else {
            print("No valid URL for case")
            return
        }

        isLoadingCase = true

        Task {
            do {
                let document = try await contentLoader.loadContent(from: url.absoluteString, title: caseItem.displayTitle)
                try documentsManager.addDocument(document)
                isLoadingCase = false
                searchText = ""
            } catch {
                print("Failed to load case: \(error)")
                isLoadingCase = false
            }
        }
    }

    @ViewBuilder
    private func destination(for doc: Document) -> some View {
        let config = themeManager.makeDocumentConfig()

        switch doc.content {
        case .plain(let s):
            DocHighlightingView(documentId: doc.id, string: s, config: config) { url in
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
}

#Preview {
    MockDocList()
        .environmentObject(ThemeManager())
}
