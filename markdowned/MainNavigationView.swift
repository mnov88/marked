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

    private let contentLoader = ContentLoader()

    var body: some View {
        List {
            // Documents section
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

            // Case search results
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

    private var filteredCases: [Case] {
        guard !searchText.isEmpty else { return [] }
        return cases.filter { $0.matches(searchText: searchText) }
    }

    private func loadCasesFromCSV() {
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
        let config = makeConfig()

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

    private func makeConfig() -> DHConfig {
        var config = DHConfig()
        config.style = themeManager.currentTheme.toDHStyle()
        config.usePageLayout = themeManager.currentTheme.usePageLayout
        return config
    }
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
