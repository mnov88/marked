//
//  CompositionDetailView.swift
//  markdowned
//
//  Detail view for a single composition with fragment management
//

import SwiftUI

struct CompositionDetailView: View {
    let composition: Composition

    @ObservedObject private var compositionsManager = CompositionsManager.shared
    @ObservedObject private var documentsManager = DocumentsManager.shared
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showingAddHighlights = false
    @State private var showingExport = false
    @State private var editMode: EditMode = .inactive
    @State private var navigationTarget: FragmentNavigationTarget?

    // Get live composition data
    private var liveComposition: Composition {
        compositionsManager.composition(withId: composition.id) ?? composition
    }

    var body: some View {
        Group {
            if liveComposition.isEmpty {
                emptyState
            } else {
                fragmentsList
            }
        }
        .navigationTitle(liveComposition.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingAddHighlights = true
                    } label: {
                        Label("Add Highlights", systemImage: "plus")
                    }

                    Divider()

                    Button {
                        showingExport = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(liveComposition.isEmpty)

                    Divider()

                    // Sort mode picker
                    Menu {
                        ForEach(CompositionSortMode.allCases) { mode in
                            Button {
                                updateSortMode(mode)
                            } label: {
                                if liveComposition.sortMode == mode {
                                    Label(mode.displayName, systemImage: "checkmark")
                                } else {
                                    Text(mode.displayName)
                                }
                            }
                        }
                    } label: {
                        Label("Sort: \(liveComposition.sortMode.displayName)", systemImage: "arrow.up.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                if !liveComposition.isEmpty && liveComposition.sortMode == .manual {
                    EditButton()
                }
            }
        }
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $showingAddHighlights) {
            AddHighlightsSheet(compositionId: liveComposition.id)
        }
        .sheet(isPresented: $showingExport) {
            CompositionExportView(composition: liveComposition)
        }
        .navigationDestination(item: $navigationTarget) { target in
            destinationView(for: target)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Fragments", systemImage: "doc.text")
        } description: {
            Text("Add highlights from your documents to build this composition")
        } actions: {
            Button {
                showingAddHighlights = true
            } label: {
                Text("Add Highlights")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var fragmentsList: some View {
        List {
            // Sort mode indicator (when not manual)
            if liveComposition.sortMode != .manual {
                Section {
                    HStack {
                        Image(systemName: liveComposition.sortMode.icon)
                        Text("Sorted by \(liveComposition.sortMode.displayName.lowercased())")
                        Spacer()
                        Text("Drag to reorder disabled")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }

            // Fragments
            Section {
                ForEach(liveComposition.sortedFragments()) { fragment in
                    FragmentRowView(fragment: fragment) {
                        navigateToSource(fragment)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            removeFragment(fragment)
                        } label: {
                            Label("Remove", systemImage: "minus.circle")
                        }
                    }
                }
                .onMove(perform: liveComposition.sortMode == .manual ? moveFragments : nil)
                .onDelete(perform: deleteFragments)
            } header: {
                Text("\(liveComposition.fragmentCount) fragments")
            }

            // Add more button
            Section {
                Button {
                    showingAddHighlights = true
                } label: {
                    Label("Add More Highlights", systemImage: "plus")
                }
            }
        }
    }

    // MARK: - Actions

    private func updateSortMode(_ mode: CompositionSortMode) {
        do {
            try compositionsManager.updateSortMode(liveComposition.id, sortMode: mode)
            // Exit edit mode when switching to non-manual sort
            if mode != .manual {
                editMode = .inactive
            }
        } catch {
            print("Failed to update sort mode: \(error)")
        }
    }

    private func moveFragments(from source: IndexSet, to destination: Int) {
        do {
            try compositionsManager.reorderFragments(
                in: liveComposition.id,
                fromOffsets: source,
                toOffset: destination
            )
        } catch {
            print("Failed to reorder fragments: \(error)")
        }
    }

    private func deleteFragments(at offsets: IndexSet) {
        let fragments = liveComposition.sortedFragments()
        for index in offsets {
            removeFragment(fragments[index])
        }
    }

    private func removeFragment(_ fragment: CompositionFragment) {
        do {
            try compositionsManager.removeFragment(fragment.id, from: liveComposition.id)
        } catch {
            print("Failed to remove fragment: \(error)")
        }
    }

    private func navigateToSource(_ fragment: CompositionFragment) {
        navigationTarget = FragmentNavigationTarget(
            documentId: fragment.documentId,
            highlightRange: fragment.range
        )
    }

    @ViewBuilder
    private func destinationView(for target: FragmentNavigationTarget) -> some View {
        if let document = documentsManager.document(withId: target.documentId) {
            let config = makeConfig()

            switch document.content {
            case .plain(let s):
                DocHighlightingView(
                    documentId: document.id,
                    string: s,
                    config: config,
                    initialScrollTarget: target.highlightRange
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
                    initialScrollTarget: target.highlightRange
                ) { url in
                    print("Tapped link:", url.absoluteString)
                }
                .navigationTitle(document.title)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func makeConfig() -> DHConfig {
        var config = DHConfig()
        config.style = themeManager.currentTheme.toDHStyle()
        config.usePageLayout = themeManager.currentTheme.usePageLayout
        return config
    }
}

// MARK: - Navigation Target

private struct FragmentNavigationTarget: Identifiable, Hashable {
    let id = UUID()
    let documentId: UUID
    let highlightRange: NSRange

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FragmentNavigationTarget, rhs: FragmentNavigationTarget) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    NavigationStack {
        CompositionDetailView(
            composition: Composition(
                id: UUID(),
                title: "Sample Composition",
                sortMode: .manual,
                fragments: [],
                createdAt: Date(),
                modifiedAt: Date()
            )
        )
        .environmentObject(ThemeManager())
    }
}
