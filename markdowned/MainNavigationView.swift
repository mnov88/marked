//
//  MainNavigationView.swift
//  markdowned
//
//  Platform-adaptive navigation using iOS 26 NavigationSplitView with liquid glass sidebar
//

import SwiftUI

/// Main navigation container that adapts to platform (Mac/iPad/iPhone)
struct MainNavigationView: View {
    @Environment(NavigationCoordinator.self) private var coordinator
    @EnvironmentObject private var themeManager: ThemeManager

    /// Computed binding that maps NavigationSection ↔ SidebarItem
    private var selectedItem: Binding<SidebarItem?> {
        Binding(
            get: { coordinator.selectedSection.sidebarItem },
            set: { item in
                if let section = item?.navigationSection {
                    coordinator.navigate(to: section)
                }
            }
        )
    }

    /// Binding to coordinator's sidebar visibility
    private var columnVisibility: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { coordinator.sidebarVisibility },
            set: { coordinator.sidebarVisibility = $0 }
        )
    }

    var body: some View {
        NavigationSplitView(columnVisibility: columnVisibility) {
            // Sidebar column
            SidebarView(selection: selectedItem)
                // iOS 26: Searchable on NavigationSplitView creates unified search
                .searchable(text: .constant(""), prompt: "Search documents")
        } detail: {
            // Detail column
            detailView(for: selectedItem.wrappedValue)
        }
        // iOS 26: Liquid glass sidebar is automatic with Xcode 26
        // No additional modifiers needed for the new design
        // Navigation via NotificationCenter is now handled by NavigationCoordinator
    }

    @ViewBuilder
    private func detailView(for item: SidebarItem?) -> some View {
        switch item {
        case .allDocuments:
            DocumentsListView(filterCategory: nil)
                .navigationTitle("All Documents")

        case .category(let category):
            DocumentsListView(filterCategory: category)
                .navigationTitle(category.name)

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
    let filterCategory: Category?

    @Environment(NavigationCoordinator.self) private var coordinator
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject private var documentsManager = DocumentsManager.shared
    @ObservedObject private var categoriesManager = CategoriesManager.shared
    @ObservedObject private var eurlexManager = EurlexDatabaseManager.shared
    @State private var showingURLEntry = false
    @State private var showingFolderImport = false
    @State private var searchText = ""
    @State private var caseSearchResults: [CaseLawSearchResult] = []
    @State private var legislationSearchResults: [LegislationSearchResult] = []
    @State private var isLoadingCase = false
    @State private var isLoadingLegislation = false
    @State private var documentSearchResults: [(Document, String)] = []
    @State private var documentToRename: Document?
    @State private var newDocumentTitle = ""
    @State private var documentForCategory: Document?
    @State private var searchDebounceTask: Task<Void, Never>?

    private let contentLoader = ContentLoader()

    /// Documents filtered by category (if filter is set)
    private var filteredDocuments: [Document] {
        guard let category = filterCategory else {
            return documentsManager.documents
        }
        let documentIds = Set(categoriesManager.documentIds(in: category.id))
        return documentsManager.documents.filter { documentIds.contains($0.id) }
    }

    var body: some View {
        List {
            // Document search results (FTS5)
            if !searchText.isEmpty && !documentSearchResults.isEmpty {
                Section("Documents") {
                    ForEach(documentSearchResults, id: \.0.id) { (doc, snippet) in
                        documentRow(for: doc, snippet: snippet)
                    }
                }
            }

            // All documents section (when not searching)
            if searchText.isEmpty {
                if filteredDocuments.isEmpty && filterCategory != nil {
                    Section {
                        ContentUnavailableView {
                            Label("No Documents", systemImage: "doc.text")
                        } description: {
                            Text("No documents in this category yet")
                        }
                    }
                } else {
                    ForEach(filteredDocuments) { doc in
                        documentRow(for: doc)
                    }
                    .onDelete(perform: deleteDocuments)
                }
            }

            // Case search results (from EUR-Lex database)
            if !searchText.isEmpty && !caseSearchResults.isEmpty {
                Section {
                    ForEach(caseSearchResults.prefix(30)) { result in
                        CaseSearchResultRow(
                            result: result,
                            isLoading: isLoadingCase,
                            onSelect: { loadCaseFromResult(result) }
                        )
                    }
                } header: {
                    HStack {
                        Text("EU Case Law")
                        Spacer()
                        if eurlexManager.isReady {
                            Text("\(caseSearchResults.count) results")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Legislation search results (from EUR-Lex database)
            if !searchText.isEmpty && !legislationSearchResults.isEmpty {
                Section {
                    ForEach(legislationSearchResults.prefix(30)) { result in
                        LegislationSearchResultRow(
                            result: result,
                            isLoading: isLoadingLegislation,
                            onSelect: { loadLegislationFromResult(result) }
                        )
                    }
                } header: {
                    HStack {
                        Text("EU Legislation")
                        Spacer()
                        if eurlexManager.isReady {
                            Text("\(legislationSearchResults.count) results")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Show database status when not searching
            if searchText.isEmpty && eurlexManager.isReady {
                Section {
                    HStack {
                        Image(systemName: "building.columns")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("EUR-Lex Database")
                                .font(.subheadline)
                            Text("\(eurlexManager.totalCaseCount) cases • \(eurlexManager.totalLegislationCount) legislation")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Search")
                } footer: {
                    Text("Search case law, legislation, or keywords")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search documents and cases")
        .onChange(of: searchText) { _, newValue in
            performSearch(query: newValue)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingURLEntry = true
                    } label: {
                        Label("Add from URL", systemImage: "link")
                    }

                    Button {
                        showingFolderImport = true
                    } label: {
                        Label("Import from Folder", systemImage: "folder")
                    }
                } label: {
                    Label("Add", systemImage: "plus")
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
        .sheet(isPresented: $showingFolderImport) {
            FolderImportView()
        }
        .sheet(item: $documentForCategory) { doc in
            CategoryAssignmentSheet(document: doc)
        }
        .alert("Rename Document", isPresented: .init(
            get: { documentToRename != nil },
            set: { if !$0 { documentToRename = nil } }
        )) {
            TextField("Title", text: $newDocumentTitle)
            Button("Cancel", role: .cancel) {
                documentToRename = nil
                newDocumentTitle = ""
            }
            Button("Rename") {
                if let doc = documentToRename, !newDocumentTitle.isEmpty {
                    renameDocument(doc, to: newDocumentTitle)
                }
                documentToRename = nil
                newDocumentTitle = ""
            }
        }
        .overlay {
            if isLoadingCase || isLoadingLegislation {
                ZStack {
                    Color.black.opacity(UIConstants.Overlay.backgroundOpacity)
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text(isLoadingCase ? "Loading case..." : "Loading legislation...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(24)
                    .background(.regularMaterial)
                    .cornerRadius(UIConstants.Overlay.cornerRadius)
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Search

    /// Perform combined search with debouncing for EUR-Lex queries
    private func performSearch(query: String) {
        // Cancel previous search task
        searchDebounceTask?.cancel()

        guard !query.isEmpty else {
            documentSearchResults = []
            caseSearchResults = []
            legislationSearchResults = []
            return
        }

        // Document search (immediate)
        do {
            documentSearchResults = try documentsManager.fullTextSearchWithSnippets(query: query)
        } catch {
            Logger.error("Document search failed", error: error)
            documentSearchResults = []
        }

        // EUR-Lex search (case law + legislation, debounced for performance)
        searchDebounceTask = Task {
            // Small delay to debounce rapid typing
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

            guard !Task.isCancelled else { return }

            // Search case law
            do {
                let caseResults = try eurlexManager.search(query: query, limit: 50)
                await MainActor.run {
                    self.caseSearchResults = caseResults
                }
            } catch {
                Logger.error("Case law search failed", error: error)
                await MainActor.run {
                    self.caseSearchResults = []
                }
            }

            guard !Task.isCancelled else { return }

            // Search legislation
            do {
                let legResults = try eurlexManager.searchLegislation(query: query, limit: 50)
                await MainActor.run {
                    self.legislationSearchResults = legResults
                }
            } catch {
                Logger.error("Legislation search failed", error: error)
                await MainActor.run {
                    self.legislationSearchResults = []
                }
            }
        }
    }

    /// Remove HTML tags from snippet (mark tags from FTS5)
    private func cleanSnippet(_ snippet: String) -> String {
        snippet
            .replacingOccurrences(of: "<mark>", with: "")
            .replacingOccurrences(of: "</mark>", with: "")
    }

    /// Load case from search result
    private func loadCaseFromResult(_ result: CaseLawSearchResult) {
        let caseItem = result.toCase()
        guard let url = caseItem.celexURL else {
            Logger.debug("No valid URL for case: \(result.caseLaw.celex)")
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

    /// Load legislation from search result
    private func loadLegislationFromResult(_ result: LegislationSearchResult) {
        guard let url = result.legislation.eurlexURL else {
            Logger.debug("No valid URL for legislation: \(result.legislation.celex)")
            return
        }

        isLoadingLegislation = true

        Task {
            do {
                let document = try await contentLoader.loadContent(from: url.absoluteString, title: result.legislation.displayTitle)
                try documentsManager.addDocument(document)
                isLoadingLegislation = false
                searchText = ""
            } catch {
                Logger.error("Failed to load legislation", error: error)
                isLoadingLegislation = false
            }
        }
    }

    // MARK: - Document Row

    @ViewBuilder
    private func documentRow(for doc: Document, snippet: String? = nil) -> some View {
        NavigationLink {
            destination(for: doc)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(doc.title)
                    .font(.headline)
                if let snippet = snippet, !snippet.isEmpty {
                    Text(cleanSnippet(snippet))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else if let url = doc.sourceURL {
                    Text(url.absoluteString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                // Show assigned categories
                let docCategories = categoriesManager.categories(for: doc.id)
                if !docCategories.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(docCategories.prefix(3)) { category in
                            HStack(spacing: 2) {
                                Image(systemName: category.icon)
                                    .font(.caption2)
                                Text(category.name)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color(platformColor: category.color).opacity(0.2))
                            .cornerRadius(4)
                        }
                        if docCategories.count > 3 {
                            Text("+\(docCategories.count - 3)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .contextMenu {
            Button {
                documentToRename = doc
                newDocumentTitle = doc.title
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button {
                documentForCategory = doc
            } label: {
                Label("Assign to Category", systemImage: "folder")
            }

            Divider()

            Button(role: .destructive) {
                deleteDocument(doc)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteDocument(doc)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Document CRUD

    private func deleteDocuments(at offsets: IndexSet) {
        for index in offsets {
            let doc = filteredDocuments[index]
            deleteDocument(doc)
        }
    }

    private func deleteDocument(_ doc: Document) {
        do {
            try documentsManager.deleteDocument(id: doc.id)
        } catch {
            Logger.error("Failed to delete document", error: error)
        }
    }

    private func renameDocument(_ doc: Document, to newTitle: String) {
        let updatedDoc = Document(
            id: doc.id,
            title: newTitle,
            content: doc.content,
            sourceURL: doc.sourceURL
        )
        do {
            try documentsManager.updateDocument(updatedDoc)
        } catch {
            Logger.error("Failed to rename document", error: error)
        }
    }

    @ViewBuilder
    private func destination(for doc: Document) -> some View {
        let config = themeManager.makeDocumentConfig()

        switch doc.content {
        case .plain(let s):
            DocHighlightingView(documentId: doc.id, string: s, config: config) { url in
                if !coordinator.handleInternalLink(url) {
                    Logger.debug("Unhandled link: \(url.absoluteString)")
                }
            }
            .navigationTitle(doc.title)
            .navigationBarTitleDisplayMode(.inline)
        case .attributed(let a):
            DocHighlightingView(documentId: doc.id, attributedString: a, config: config) { url in
                if !coordinator.handleInternalLink(url) {
                    Logger.debug("Unhandled link: \(url.absoluteString)")
                }
            }
            .navigationTitle(doc.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // makeConfig() moved to ThemeManager.makeDocumentConfig() (DRY)
}

// MARK: - Category Assignment Sheet

/// Sheet for assigning a document to categories
struct CategoryAssignmentSheet: View {
    let document: Document

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var categoriesManager = CategoriesManager.shared
    @State private var selectedCategories: Set<UUID> = []
    @State private var showNewCategoryAlert = false
    @State private var newCategoryName = ""

    var body: some View {
        NavigationStack {
            List {
                if categoriesManager.categories.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("No Categories", systemImage: "folder")
                        } description: {
                            Text("Create a category to organize your documents")
                        } actions: {
                            Button("Create Category") {
                                showNewCategoryAlert = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    Section {
                        ForEach(categoriesManager.categories) { category in
                            Button {
                                toggleCategory(category.id)
                            } label: {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(Color(platformColor: category.color))
                                        .frame(width: 24)
                                    Text(category.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedCategories.contains(category.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Categories")
                    }

                    Section {
                        Button {
                            showNewCategoryAlert = true
                        } label: {
                            Label("Create New Category", systemImage: "plus")
                        }
                    }
                }
            }
            .navigationTitle("Assign Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveAssignments()
                        dismiss()
                    }
                }
            }
            .alert("New Category", isPresented: $showNewCategoryAlert) {
                TextField("Category name", text: $newCategoryName)
                Button("Cancel", role: .cancel) {
                    newCategoryName = ""
                }
                Button("Create") {
                    if !newCategoryName.isEmpty {
                        if let id = try? categoriesManager.createCategory(name: newCategoryName) {
                            selectedCategories.insert(id)
                        }
                        newCategoryName = ""
                    }
                }
            }
            .onAppear {
                loadCurrentAssignments()
            }
        }
    }

    private func loadCurrentAssignments() {
        let current = categoriesManager.categories(for: document.id)
        selectedCategories = Set(current.map { $0.id })
    }

    private func toggleCategory(_ categoryId: UUID) {
        if selectedCategories.contains(categoryId) {
            selectedCategories.remove(categoryId)
        } else {
            selectedCategories.insert(categoryId)
        }
    }

    private func saveAssignments() {
        let currentCategories = Set(categoriesManager.categories(for: document.id).map { $0.id })

        // Remove from categories no longer selected
        for categoryId in currentCategories.subtracting(selectedCategories) {
            try? categoriesManager.removeDocument(document.id, fromCategory: categoryId)
        }

        // Add to newly selected categories
        for categoryId in selectedCategories.subtracting(currentCategories) {
            try? categoriesManager.addDocument(document.id, toCategory: categoryId)
        }
    }
}

// MARK: - Case Search Result Row

/// Enhanced row view for case law search results
struct CaseSearchResultRow: View {
    let result: CaseLawSearchResult
    let isLoading: Bool
    let onSelect: () -> Void

    /// Format relevance score for display
    private var relevanceLabel: String {
        // BM25 returns negative scores, more negative = better match
        let score = abs(result.rank)
        if score > 8 { return "Excellent" }
        if score > 5 { return "Good" }
        if score > 3 { return "Fair" }
        return "Partial"
    }

    private var relevanceColor: Color {
        let score = abs(result.rank)
        if score > 8 { return .green }
        if score > 5 { return .blue }
        if score > 3 { return .orange }
        return .secondary
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                // Case number with year badge
                HStack(alignment: .center, spacing: 8) {
                    Text(result.caseLaw.caseNumber ?? "Unknown")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let year = result.caseLaw.year {
                        Text(String(year))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    // Relevance indicator
                    HStack(spacing: 3) {
                        Circle()
                            .fill(relevanceColor)
                            .frame(width: 6, height: 6)
                        Text(relevanceLabel)
                            .font(.caption2)
                            .foregroundStyle(relevanceColor)
                    }
                }

                // Title or parties
                if let title = result.caseLaw.title, !title.isEmpty {
                    // Extract parties from title (format: "Case C-xxx/xx. PartyA v PartyB")
                    let displayTitle = extractDisplayTitle(from: title)
                    Text(displayTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                // Snippet from FTS match (if available)
                if let snippet = result.snippet, !snippet.isEmpty {
                    Text(formatSnippet(snippet))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }

                // Metadata row
                HStack(spacing: 12) {
                    // CELEX badge
                    Label(result.caseLaw.celex, systemImage: "number")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    // AG Opinion indicator
                    if result.caseLaw.hasAgOpinion {
                        Label("AG Opinion", systemImage: "person.text.rectangle")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                    }

                    // Court indicator
                    if let court = result.caseLaw.court, !court.isEmpty {
                        Text(court)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 2)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
    }

    /// Extract display title from case title
    private func extractDisplayTitle(from title: String) -> String {
        // Format: "Case C-xxx/xx. PartyA v PartyB"
        if let dotIndex = title.firstIndex(of: ".") {
            let afterDot = title[title.index(after: dotIndex)...]
            return afterDot.trimmingCharacters(in: .whitespaces)
        }
        return title
    }

    /// Format FTS snippet for display
    private func formatSnippet(_ snippet: String) -> String {
        snippet
            .replacingOccurrences(of: "<mark>", with: "")
            .replacingOccurrences(of: "</mark>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Legislation Search Result Row

/// Enhanced row view for legislation search results
struct LegislationSearchResultRow: View {
    let result: LegislationSearchResult
    let isLoading: Bool
    let onSelect: () -> Void

    /// Format relevance score for display
    private var relevanceLabel: String {
        let score = abs(result.rank)
        if score > 8 { return "Excellent" }
        if score > 5 { return "Good" }
        if score > 3 { return "Fair" }
        return "Partial"
    }

    private var relevanceColor: Color {
        let score = abs(result.rank)
        if score > 8 { return .green }
        if score > 5 { return .blue }
        if score > 3 { return .orange }
        return .secondary
    }

    /// Icon for document type
    private var docTypeIcon: String {
        if let docType = LegislationDocType(rawValue: result.legislation.docType) {
            return docType.icon
        }
        return "doc.text"
    }

    /// Display name for document type
    private var docTypeName: String {
        if let docType = LegislationDocType(rawValue: result.legislation.docType) {
            return docType.displayName
        }
        return result.legislation.docType
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                // Document type with year badge
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: docTypeIcon)
                        .foregroundStyle(.blue)

                    Text(docTypeName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(String(result.legislation.docYear))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.15))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())

                    Spacer()

                    // Relevance indicator
                    HStack(spacing: 3) {
                        Circle()
                            .fill(relevanceColor)
                            .frame(width: 6, height: 6)
                        Text(relevanceLabel)
                            .font(.caption2)
                            .foregroundStyle(relevanceColor)
                    }
                }

                // Title
                Text(result.legislation.displayTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Snippet from FTS match (if available)
                if let snippet = result.snippet, !snippet.isEmpty {
                    Text(formatSnippet(snippet))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }

                // Metadata row
                HStack(spacing: 12) {
                    // CELEX badge
                    Label(result.legislation.celex, systemImage: "number")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    // In force indicator
                    if result.legislation.inForce {
                        Label("In force", systemImage: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    } else {
                        Label("Not in force", systemImage: "xmark.seal")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }

                    // Document number (if available)
                    if let docNum = result.legislation.docNumber {
                        Text("No. \(docNum)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 2)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
    }

    /// Format FTS snippet for display
    private func formatSnippet(_ snippet: String) -> String {
        snippet
            .replacingOccurrences(of: "<mark>", with: "")
            .replacingOccurrences(of: "</mark>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview("Mac/iPad Navigation") {
    MainNavigationView()
        .environment(NavigationCoordinator.shared)
        .environmentObject(ThemeManager())
}

#Preview("Documents List") {
    NavigationStack {
        DocumentsListView(filterCategory: nil)
            .environment(NavigationCoordinator.shared)
            .environmentObject(ThemeManager())
    }
}
