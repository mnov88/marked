//
//  HighlightsManager.swift
//  markdowned
//
//  Global highlights manager with GRDB persistence
//

import Foundation
import SwiftUI
import Combine
import GRDB

@MainActor
final class HighlightsManager: ObservableObject {
    static let shared = HighlightsManager()

    // Dictionary mapping document ID to its highlights
    @Published private(set) var highlightsByDocument: [UUID: [DHTextHighlight]] = [:]

    private var observationCancellable: AnyCancellable?
    private let db = DatabaseManager.shared
    private let userDefaults = UserDefaults.standard
    private let highlightsKey = "documentHighlights"
    private let migrationKey = "highlights_migrated_to_grdb"

    private init() {
        migrateUserDefaultsIfNeeded()
        setupObservation()
    }

    // MARK: - Migration from UserDefaults

    private func migrateUserDefaultsIfNeeded() {
        // Check if migration already completed
        guard !userDefaults.bool(forKey: migrationKey) else { return }

        // Load existing highlights from UserDefaults
        guard let data = userDefaults.data(forKey: highlightsKey) else {
            userDefaults.set(true, forKey: migrationKey)
            return
        }

        do {
            let decoded = try JSONDecoder().decode([String: [DHTextHighlight]].self, from: data)

            // Migrate to GRDB
            try db.write { db in
                for (documentIdString, highlights) in decoded {
                    guard let documentId = UUID(uuidString: documentIdString) else { continue }

                    for highlight in highlights {
                        let dbHighlight = DBHighlight(from: highlight, documentId: documentId)
                        try dbHighlight.insert(db)
                    }
                }
            }

            // Mark migration as complete
            userDefaults.set(true, forKey: migrationKey)
            print("Successfully migrated \(decoded.count) document highlights from UserDefaults to GRDB")

        } catch {
            print("Failed to migrate highlights: \(error)")
        }
    }

    // MARK: - Database Observation

    private func setupObservation() {
        // Create ValueObservation for reactive updates
        let observation = ValueObservation.tracking { db in
            try DBHighlight
                .order(DBHighlight.Columns.location)
                .fetchAll(db)
        }

        // Observe database changes and update @Published highlightsByDocument
        observationCancellable = observation
            .publisher(in: db.queue, scheduling: .immediate)
            .catch { error -> Just<[DBHighlight]> in
                print("Highlights observation error: \(error)")
                return Just([])
            }
            .map { dbHighlights -> [UUID: [DHTextHighlight]] in
                // Group highlights by document ID
                var result: [UUID: [DHTextHighlight]] = [:]

                for dbHighlight in dbHighlights {
                    guard let documentId = UUID(uuidString: dbHighlight.documentId),
                          let highlight = try? dbHighlight.toHighlight() else {
                        continue
                    }

                    if result[documentId] == nil {
                        result[documentId] = []
                    }
                    result[documentId]?.append(highlight)
                }

                return result
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.highlightsByDocument, on: self)
    }

    // MARK: - Public API

    /// Get all highlights for a specific document
    func highlights(for documentId: UUID) -> [DHTextHighlight] {
        highlightsByDocument[documentId] ?? []
    }

    /// Add a highlight to a document
    func addHighlight(_ highlight: DHTextHighlight, to documentId: UUID) {
        do {
            let dbHighlight = DBHighlight(from: highlight, documentId: documentId)
            try db.write { db in
                try dbHighlight.insert(db)
            }
        } catch {
            print("Failed to add highlight: \(error)")
        }
    }

    /// Remove a specific highlight by ID
    func removeHighlight(id: UUID, from documentId: UUID) {
        do {
            try db.write { db in
                try DBHighlight.deleteOne(db, key: id.uuidString)
            }
        } catch {
            print("Failed to remove highlight: \(error)")
        }
    }

    /// Remove highlights that intersect with a given range
    func removeHighlights(intersecting range: NSRange, from documentId: UUID) {
        do {
            try db.write { db in
                let highlights = try DBHighlight.highlightsForDocument(documentId).fetchAll(db)

                for dbHighlight in highlights {
                    let highlightRange = NSRange(location: dbHighlight.location, length: dbHighlight.length)
                    if NSIntersectionRange(highlightRange, range).length > 0 {
                        try DBHighlight.deleteOne(db, key: dbHighlight.id)
                    }
                }
            }
        } catch {
            print("Failed to remove intersecting highlights: \(error)")
        }
    }

    /// Set/replace all highlights for a document
    func setHighlights(_ highlights: [DHTextHighlight], for documentId: UUID) {
        do {
            try db.write { db in
                // Remove existing highlights
                try DBHighlight.deleteForDocument(documentId, db: db)

                // Insert new highlights
                for highlight in highlights {
                    let dbHighlight = DBHighlight(from: highlight, documentId: documentId)
                    try dbHighlight.insert(db)
                }
            }
        } catch {
            print("Failed to set highlights: \(error)")
        }
    }

    /// Get all highlights across all documents with document info
    func allHighlights() -> [(documentId: UUID, highlight: DHTextHighlight)] {
        highlightsByDocument.flatMap { documentId, highlights in
            highlights.map { (documentId: documentId, highlight: $0) }
        }
    }

    /// Clear all highlights from all documents
    func clearAllHighlights() {
        do {
            try db.write { db in
                try DBHighlight.deleteAll(db)
            }
        } catch {
            print("Failed to clear all highlights: \(error)")
        }
    }

    // MARK: - Additional CRUD Operations

    /// Get highlights count for a specific document
    func highlightsCount(for documentId: UUID) throws -> Int {
        try db.read { db in
            try DBHighlight.highlightsForDocument(documentId).fetchCount(db)
        }
    }

    /// Get total highlights count across all documents
    func totalHighlightsCount() throws -> Int {
        try db.read { db in
            try DBHighlight.fetchCount(db)
        }
    }

    /// Delete all highlights for a specific document
    func deleteHighlights(for documentId: UUID) throws {
        try db.write { db in
            try DBHighlight.deleteForDocument(documentId, db: db)
        }
    }

    /// Get highlights by color
    func highlights(withColor colorHex: String) throws -> [(documentId: UUID, highlight: DHTextHighlight)] {
        try db.read { db in
            let dbHighlights = try DBHighlight
                .filter(DBHighlight.Columns.colorHex == colorHex)
                .fetchAll(db)

            return try dbHighlights.compactMap { dbHighlight in
                guard let documentId = UUID(uuidString: dbHighlight.documentId),
                      let highlight = try? dbHighlight.toHighlight() else {
                    return nil
                }
                return (documentId: documentId, highlight: highlight)
            }
        }
    }
}
