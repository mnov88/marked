//
//  CompositionsManager.swift
//  markdowned
//
//  Global compositions manager with GRDB persistence
//

import Foundation
import SwiftUI
import Combine
import GRDB

@MainActor
final class CompositionsManager: ObservableObject {
    static let shared = CompositionsManager()

    @Published private(set) var compositions: [Composition] = []

    private var observationCancellable: AnyCancellable?
    private let db = DatabaseManager.shared
    private let documentsManager = DocumentsManager.shared
    private let highlightsManager = HighlightsManager.shared

    private init() {
        setupObservation()
    }

    // MARK: - Database Observation

    private func setupObservation() {
        // Create ValueObservation for reactive updates
        let observation = ValueObservation.tracking { db -> [(DBComposition, [DBCompositionFragment])] in
            let compositions = try DBComposition.allOrdered().fetchAll(db)
            return try compositions.map { composition in
                let fragments = try DBCompositionFragment.fragmentsForComposition(
                    UUID(uuidString: composition.id)!
                ).fetchAll(db)
                return (composition, fragments)
            }
        }

        // Observe database changes and update @Published compositions
        observationCancellable = observation
            .publisher(in: db.queue, scheduling: .immediate)
            .catch { error -> Just<[(DBComposition, [DBCompositionFragment])]> in
                print("Compositions observation error: \(error)")
                return Just([])
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] compositionData in
                self?.updateCompositions(from: compositionData)
            }
    }

    private func updateCompositions(from data: [(DBComposition, [DBCompositionFragment])]) {
        compositions = data.compactMap { dbComposition, dbFragments in
            resolveComposition(dbComposition, fragments: dbFragments)
        }
    }

    private func resolveComposition(
        _ dbComposition: DBComposition,
        fragments dbFragments: [DBCompositionFragment]
    ) -> Composition? {
        // Resolve each fragment with its highlight and document data
        let resolvedFragments: [CompositionFragment] = dbFragments.compactMap { dbFragment in
            guard let fragmentId = UUID(uuidString: dbFragment.id),
                  let highlightId = UUID(uuidString: dbFragment.highlightId) else {
                return nil
            }

            // Find the highlight and its document
            let allHighlights = highlightsManager.allHighlights()
            guard let highlightData = allHighlights.first(where: { $0.highlight.id == highlightId }) else {
                return nil
            }

            let documentId = highlightData.documentId
            let highlight = highlightData.highlight

            guard let document = documentsManager.document(withId: documentId) else {
                return nil
            }

            // Extract text snippet from document
            let snippet = extractSnippet(for: highlight, in: document)

            return CompositionFragment(
                id: fragmentId,
                highlightId: highlightId,
                documentId: documentId,
                documentTitle: document.title,
                textSnippet: snippet,
                range: highlight.range,
                color: highlight.color,
                sortOrder: dbFragment.sortOrder,
                createdAt: dbFragment.createdAt
            )
        }

        do {
            return try Composition(from: dbComposition, fragments: resolvedFragments)
        } catch {
            print("Failed to resolve composition: \(error)")
            return nil
        }
    }

    private func extractSnippet(for highlight: DHTextHighlight, in document: Document, maxLength: Int = 200) -> String {
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

    // MARK: - CRUD Operations

    /// Create a new composition
    func createComposition(title: String) throws -> UUID {
        let dbComposition = DBComposition.create(title: title)
        try db.write { db in
            try dbComposition.insert(db)
        }
        return UUID(uuidString: dbComposition.id)!
    }

    /// Update a composition's title
    func updateTitle(_ compositionId: UUID, title: String) throws {
        try db.write { db in
            guard var composition = try DBComposition.fetchOne(db, key: compositionId.uuidString) else {
                throw DatabaseError(message: "Composition not found: \(compositionId)")
            }
            composition.title = title
            composition.touch()
            try composition.update(db)
        }
    }

    /// Update a composition's sort mode
    func updateSortMode(_ compositionId: UUID, sortMode: CompositionSortMode) throws {
        try db.write { db in
            guard var composition = try DBComposition.fetchOne(db, key: compositionId.uuidString) else {
                throw DatabaseError(message: "Composition not found: \(compositionId)")
            }
            composition.sortMode = sortMode.rawValue
            composition.touch()
            try composition.update(db)
        }
    }

    /// Delete a composition
    func deleteComposition(_ compositionId: UUID) throws {
        try db.write { db in
            // Fragments are deleted via cascade
            try DBComposition.deleteOne(db, key: compositionId.uuidString)
        }
    }

    /// Get a specific composition by ID
    func composition(withId id: UUID) -> Composition? {
        compositions.first { $0.id == id }
    }

    // MARK: - Fragment Management

    /// Add a highlight to a composition
    func addHighlight(_ highlightId: UUID, to compositionId: UUID) throws {
        try db.write { db in
            // Check if already exists
            guard try !DBCompositionFragment.exists(compositionId: compositionId, highlightId: highlightId, db: db) else {
                return // Already in composition
            }

            // Get next sort order
            let sortOrder = try DBCompositionFragment.nextSortOrder(for: compositionId, db: db)

            // Create and insert fragment
            let fragment = DBCompositionFragment.create(
                compositionId: compositionId,
                highlightId: highlightId,
                sortOrder: sortOrder
            )
            try fragment.insert(db)

            // Update composition's modification date
            if var composition = try DBComposition.fetchOne(db, key: compositionId.uuidString) {
                composition.touch()
                try composition.update(db)
            }
        }
    }

    /// Add multiple highlights to a composition
    func addHighlights(_ highlightIds: [UUID], to compositionId: UUID) throws {
        try db.write { db in
            var sortOrder = try DBCompositionFragment.nextSortOrder(for: compositionId, db: db)

            for highlightId in highlightIds {
                // Check if already exists
                guard try !DBCompositionFragment.exists(compositionId: compositionId, highlightId: highlightId, db: db) else {
                    continue
                }

                let fragment = DBCompositionFragment.create(
                    compositionId: compositionId,
                    highlightId: highlightId,
                    sortOrder: sortOrder
                )
                try fragment.insert(db)
                sortOrder += 1
            }

            // Update composition's modification date
            if var composition = try DBComposition.fetchOne(db, key: compositionId.uuidString) {
                composition.touch()
                try composition.update(db)
            }
        }
    }

    /// Remove a fragment from a composition
    func removeFragment(_ fragmentId: UUID, from compositionId: UUID) throws {
        try db.write { db in
            try DBCompositionFragment.deleteOne(db, key: fragmentId.uuidString)

            // Update composition's modification date
            if var composition = try DBComposition.fetchOne(db, key: compositionId.uuidString) {
                composition.touch()
                try composition.update(db)
            }
        }
    }

    /// Reorder fragments within a composition
    func reorderFragments(in compositionId: UUID, fromOffsets: IndexSet, toOffset: Int) throws {
        guard let composition = composition(withId: compositionId) else { return }

        var fragments = composition.sortedFragments()
        fragments.move(fromOffsets: fromOffsets, toOffset: toOffset)

        try db.write { db in
            // Update sort orders
            for (index, fragment) in fragments.enumerated() {
                if var dbFragment = try DBCompositionFragment.fetchOne(db, key: fragment.id.uuidString) {
                    dbFragment.sortOrder = index
                    try dbFragment.update(db)
                }
            }

            // Update composition's modification date
            if var dbComposition = try DBComposition.fetchOne(db, key: compositionId.uuidString) {
                dbComposition.touch()
                try dbComposition.update(db)
            }
        }
    }

    /// Move a single fragment to a new position
    func moveFragment(_ fragmentId: UUID, in compositionId: UUID, to newIndex: Int) throws {
        guard let composition = composition(withId: compositionId),
              let currentIndex = composition.sortedFragments().firstIndex(where: { $0.id == fragmentId }) else {
            return
        }

        try reorderFragments(
            in: compositionId,
            fromOffsets: IndexSet(integer: currentIndex),
            toOffset: newIndex > currentIndex ? newIndex + 1 : newIndex
        )
    }

    // MARK: - Export

    /// Export composition as plain text
    func exportAsPlainText(_ composition: Composition) -> String {
        let fragments = composition.sortedFragments()
        return fragments
            .map { $0.textSnippet }
            .joined(separator: "\n\n---\n\n")
    }

    /// Export composition as Markdown with source citations
    func exportAsMarkdown(_ composition: Composition) -> String {
        let fragments = composition.sortedFragments()
        var output = "# \(composition.title)\n\n"

        for fragment in fragments {
            output += "> \(fragment.textSnippet)\n"
            output += ">\n"
            output += "> — *\(fragment.documentTitle)*\n\n"
        }

        return output
    }

    /// Export composition as attributed string preserving highlight colors
    func exportAsAttributedString(_ composition: Composition) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let fragments = composition.sortedFragments()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 12

        for (index, fragment) in fragments.enumerated() {
            // Add fragment text with highlight color background
            let fragmentText = NSMutableAttributedString(string: fragment.textSnippet)
            fragmentText.addAttributes([
                .backgroundColor: fragment.color.withAlphaComponent(0.3),
                .paragraphStyle: paragraphStyle
            ], range: NSRange(location: 0, length: fragmentText.length))

            result.append(fragmentText)

            // Add source citation
            let citation = NSAttributedString(
                string: "\n— \(fragment.documentTitle)\n",
                attributes: [
                    .foregroundColor: PlatformColor.secondaryLabel,
                    .font: PlatformFont.italicSystemFont(ofSize: 12)
                ]
            )
            result.append(citation)

            // Add separator if not last
            if index < fragments.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }

        return result
    }
}
