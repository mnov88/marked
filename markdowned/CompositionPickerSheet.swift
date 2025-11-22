//
//  CompositionPickerSheet.swift
//  markdowned
//
//  Sheet for selecting which composition to add a highlight to
//

import SwiftUI

struct CompositionPickerSheet: View {
    let highlightId: UUID

    @ObservedObject private var compositionsManager = CompositionsManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showingNewComposition = false
    @State private var newCompositionTitle = ""

    var body: some View {
        NavigationStack {
            Group {
                if compositionsManager.compositions.isEmpty {
                    emptyState
                } else {
                    compositionList
                }
            }
            .navigationTitle("Add to Composition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewComposition = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New Composition", isPresented: $showingNewComposition) {
                TextField("Title", text: $newCompositionTitle)
                Button("Cancel", role: .cancel) {
                    newCompositionTitle = ""
                }
                Button("Create & Add") {
                    createAndAdd()
                }
            } message: {
                Text("Create a new composition and add this highlight")
            }
        }
        .presentationDetents([.medium])
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Compositions", systemImage: "doc.on.doc")
        } description: {
            Text("Create a composition to start assembling highlights")
        } actions: {
            Button {
                showingNewComposition = true
            } label: {
                Text("New Composition")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var compositionList: some View {
        List {
            ForEach(compositionsManager.compositions) { composition in
                Button {
                    addToComposition(composition.id)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(composition.title)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text("\(composition.fragmentCount) fragments")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Check if already in composition
                        if composition.fragments.contains(where: { $0.highlightId == highlightId }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(composition.fragments.contains(where: { $0.highlightId == highlightId }))
            }
        }
    }

    private func addToComposition(_ compositionId: UUID) {
        do {
            try compositionsManager.addHighlight(highlightId, to: compositionId)
            dismiss()
        } catch {
            print("Failed to add highlight to composition: \(error)")
        }
    }

    private func createAndAdd() {
        let title = newCompositionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            newCompositionTitle = ""
            return
        }

        do {
            let compositionId = try compositionsManager.createComposition(title: title)
            try compositionsManager.addHighlight(highlightId, to: compositionId)
            newCompositionTitle = ""
            dismiss()
        } catch {
            print("Failed to create composition: \(error)")
        }
    }
}

#Preview {
    CompositionPickerSheet(highlightId: UUID())
}
