//
//  DBCompositionFragment.swift
//  markdowned
//
//  Database record model for composition fragments (junction between composition and highlight)
//

import Foundation
import GRDB

/// Database record for composition fragments using GRDB Codable records
/// Links a composition to a highlight with ordering information
struct DBCompositionFragment: Identifiable, Codable, FetchableRecord, PersistableRecord {
    var id: String // UUID as string
    var compositionId: String // UUID as string (foreign key to composition)
    var highlightId: String // UUID as string (foreign key to highlight)
    var sortOrder: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, compositionId, highlightId, sortOrder, createdAt
    }

    // Define column names for type-safe queries
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let compositionId = Column(CodingKeys.compositionId)
        static let highlightId = Column(CodingKeys.highlightId)
        static let sortOrder = Column(CodingKeys.sortOrder)
        static let createdAt = Column(CodingKeys.createdAt)
    }

    static var databaseTableName: String { "compositionFragment" }
}

// MARK: - Factory Methods

extension DBCompositionFragment {
    /// Create a new fragment linking a highlight to a composition
    static func create(
        compositionId: UUID,
        highlightId: UUID,
        sortOrder: Int
    ) -> DBCompositionFragment {
        DBCompositionFragment(
            id: UUID().uuidString,
            compositionId: compositionId.uuidString,
            highlightId: highlightId.uuidString,
            sortOrder: sortOrder,
            createdAt: Date()
        )
    }
}

// MARK: - Query Helpers

extension DBCompositionFragment {
    /// Fetch all fragments for a specific composition, ordered by sortOrder
    static func fragmentsForComposition(_ compositionId: UUID) -> QueryInterfaceRequest<DBCompositionFragment> {
        filter(Columns.compositionId == compositionId.uuidString)
            .order(Columns.sortOrder)
    }

    /// Delete all fragments for a specific composition
    static func deleteForComposition(_ compositionId: UUID, db: Database) throws {
        try filter(Columns.compositionId == compositionId.uuidString).deleteAll(db)
    }

    /// Delete all fragments referencing a specific highlight
    static func deleteForHighlight(_ highlightId: UUID, db: Database) throws {
        try filter(Columns.highlightId == highlightId.uuidString).deleteAll(db)
    }

    /// Check if a highlight is already in a composition
    static func exists(compositionId: UUID, highlightId: UUID, db: Database) throws -> Bool {
        try filter(Columns.compositionId == compositionId.uuidString)
            .filter(Columns.highlightId == highlightId.uuidString)
            .fetchCount(db) > 0
    }

    /// Get the next sort order for a composition
    static func nextSortOrder(for compositionId: UUID, db: Database) throws -> Int {
        let maxOrder = try filter(Columns.compositionId == compositionId.uuidString)
            .select(max(Columns.sortOrder))
            .asRequest(of: Int?.self)
            .fetchOne(db) ?? nil
        return (maxOrder ?? -1) + 1
    }
}
