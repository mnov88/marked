//
//  MainNavigationView.swift
//  markdowned
//
//  Platform-adaptive navigation using iOS 26 NavigationSplitView with liquid glass sidebar
//

import SwiftUI

/// Main navigation container that adapts to platform (Mac/iPad/iPhone)
struct MainNavigationView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedItem: SidebarItem? = .allDocuments
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar column
            SidebarView(selection: $selectedItem)
                // iOS 26: Searchable on NavigationSplitView creates unified search
                .searchable(text: .constant(""), prompt: "Search documents")
        } detail: {
            // Detail column
            detailView(for: selectedItem)
        }
        // iOS 26: Liquid glass sidebar is automatic with Xcode 26
        // No additional modifiers needed for the new design
        .onReceive(NotificationCenter.default.publisher(for: .navigateToSection)) { notification in
            if let section = notification.userInfo?["section"] as? NavigationSection {
                withAnimation {
                    selectedItem = sidebarItem(for: section)
                }
            }
        }
    }

    /// Convert NavigationSection to SidebarItem
    private func sidebarItem(for section: NavigationSection) -> SidebarItem {
        switch section {
        case .documents:
            return .allDocuments
        case .highlights:
            return .highlights
        case .compositions:
            return .assembly
        case .settings:
            return .settings
        }
    }

    @ViewBuilder
    private func detailView(for item: SidebarItem?) -> some View {
        switch item {
        case .allDocuments, .category:
            DocumentsListView()
                .navigationTitle(item?.title ?? "Documents")
                #if os(macOS)
                .toolbar {
                    ToolbarItemGroup(placement: .automatic) {
                        // TODO: Add toolbar items (search, new document, etc.)
                        Button {
                            // New document action
                        } label: {
                            Label("New Document", systemImage: "plus")
                        }

                        Button {
                            // Share action
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                #endif

        case .highlights:
            AllHighlightsView()
                .navigationTitle("Highlights")

        case .assembly:
            CompositionsListView()

        case .settings:
            SettingsView()
                .navigationTitle("Settings")

        case .none:
            ContentUnavailableView(
                "No Selection",
                systemImage: "sidebar.left",
                description: Text("Select an item from the sidebar")
            )
        }
    }
}

/// Documents list view for the detail pane
struct DocumentsListView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject private var documentsManager = DocumentsManager.shared
    @State private var showingURLEntry = false
    @State private var searchText = ""
    @State private var cases: [Case] = []
    @State private var isLoadingCase = false
    @State private var hasLoadedCSV = false
    @State private var documentSearchResults: [(Document, String)] = []

    private let contentLoader = ContentLoader()

    var body: some View {
        List {
            // Document search results (FTS5)
            if !searchText.isEmpty && !documentSearchResults.isEmpty {
                Section("Documents") {
                    ForEach(documentSearchResults, id: \.0.id) { (doc, snippet) in
                        NavigationLink {
                            destination(for: doc)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(doc.title)
                                    .font(.headline)
                                if !snippet.isEmpty {
                                    Text(cleanSnippet(snippet))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }
            }

            // All documents section (when not searching)
            if searchText.isEmpty {
                ForEach(documentsManager.documents) { doc in
                    NavigationLink {
                        destination(for: doc)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(doc.title)
                                .font(.headline)
                            if let url = doc.sourceURL {
                                Text(url.absoluteString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }

            // Case search results (from CSV)
            if !searchText.isEmpty && !filteredCases.isEmpty {
                Section("Case Database") {
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
        .searchable(text: $searchText, prompt: "Search documents and cases")
        .onChange(of: searchText) { _, newValue in
            performDocumentSearch(query: newValue)
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
                    Logger.error("Failed to persist document from URL entry", error: error)
                }
            }
        }
        .overlay {
            if isLoadingCase {
                ZStack {
                    Color.black.opacity(UIConstants.Overlay.backgroundOpacity)
                    ProgressView("Loading case...")
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(UIConstants.Overlay.cornerRadius)
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

    // MARK: - Search

    private func performDocumentSearch(query: String) {
        guard !query.isEmpty else {
            documentSearchResults = []
            return
        }

        do {
            documentSearchResults = try documentsManager.fullTextSearchWithSnippets(query: query)
        } catch {
            Logger.error("Full-text search failed", error: error)
            documentSearchResults = []
        }
    }

    /// Remove HTML tags from snippet (mark tags from FTS5)
    private func cleanSnippet(_ snippet: String) -> String {
        snippet
            .replacingOccurrences(of: "<mark>", with: "")
            .replacingOccurrences(of: "</mark>", with: "")
    }

    private var filteredCases: [Case] {
        guard !searchText.isEmpty else { return [] }
        return cases.filter { $0.matches(searchText: searchText) }
    }

    private func loadCasesFromCSV() {
        guard let csvPath = Bundle.main.path(forResource: "allcases", ofType: "csv"),
              let csvString = try? String(contentsOfFile: csvPath, encoding: .utf8) else {
            Logger.debug("Could not load allcases.csv from bundle")
            cases = []
            return
        }

        cases = CaseDataParser.parse(csvString)
        Logger.debug("Loaded \(cases.count) cases from CSV")
    }

    private func loadCase(_ caseItem: Case) {
        guard let url = caseItem.celexURL else {
            Logger.debug("No valid URL for case")
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
                Logger.error("Failed to load case", error: error)
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
                Logger.debug("Tapped link: \(url.absoluteString)")
            }
            .navigationTitle(doc.title)
            .navigationBarTitleDisplayMode(.inline)
        case .attributed(let a):
            DocHighlightingView(documentId: doc.id, attributedString: a, config: config) { url in
                Logger.debug("Tapped link: \(url.absoluteString)")
            }
            .navigationTitle(doc.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // makeConfig() moved to ThemeManager.makeDocumentConfig() (DRY)
}

#Preview("Mac/iPad Navigation") {
    MainNavigationView()
        .environmentObject(ThemeManager())
}

#Preview("Documents List") {
    NavigationStack {
        DocumentsListView()
            .environmentObject(ThemeManager())
    }
}
