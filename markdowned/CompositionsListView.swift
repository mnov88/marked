//
//  CompositionsListView.swift
//  markdowned
//
//  View showing all compositions for the Assembly feature
//

import SwiftUI

struct CompositionsListView: View {
    @ObservedObject private var compositionsManager = CompositionsManager.shared
    @State private var showingNewComposition = false
    @State private var newCompositionTitle = ""
    @State private var selectedComposition: Composition?

    var body: some View {
        NavigationStack {
            Group {
                if compositionsManager.compositions.isEmpty {
                    emptyState
                } else {
                    compositionsList
                }
            }
            .navigationTitle("Assembly")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewComposition = true
                    } label: {
                        Label("New Composition", systemImage: "plus")
                    }
                }
            }
            .alert("New Composition", isPresented: $showingNewComposition) {
                TextField("Title", text: $newCompositionTitle)
                Button("Cancel", role: .cancel) {
                    newCompositionTitle = ""
                }
                Button("Create") {
                    createComposition()
                }
            } message: {
                Text("Enter a title for your new composition")
            }
            .navigationDestination(item: $selectedComposition) { composition in
                CompositionDetailView(composition: composition)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Compositions", systemImage: "doc.on.doc")
        } description: {
            Text("Create a composition to assemble highlights from your documents")
        } actions: {
            Button {
                showingNewComposition = true
            } label: {
                Text("New Composition")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var compositionsList: some View {
        List {
            ForEach(compositionsManager.compositions) { composition in
                Button {
                    selectedComposition = composition
                } label: {
                    CompositionRowView(composition: composition)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteComposition(composition)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func createComposition() {
        let title = newCompositionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            newCompositionTitle = ""
            return
        }

        do {
            let id = try compositionsManager.createComposition(title: title)
            newCompositionTitle = ""
            // Navigate to the new composition
            if let composition = compositionsManager.composition(withId: id) {
                selectedComposition = composition
            }
        } catch {
            print("Failed to create composition: \(error)")
        }
    }

    private func deleteComposition(_ composition: Composition) {
        do {
            try compositionsManager.deleteComposition(composition.id)
        } catch {
            print("Failed to delete composition: \(error)")
        }
    }
}

// MARK: - Composition Row

struct CompositionRowView: View {
    let composition: Composition

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(composition.title)
                    .font(.headline)

                Spacer()

                Text("\(composition.fragmentCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(Capsule())
            }

            if !composition.isEmpty {
                Text(composition.previewText())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Text("No fragments yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .italic()
            }

            HStack {
                Image(systemName: composition.sortMode.icon)
                    .font(.caption2)
                Text(composition.sortMode.displayName)
                    .font(.caption2)

                Text("•")

                Text(composition.modifiedAt, style: .relative)
                    .font(.caption2)
            }
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CompositionsListView()
}
