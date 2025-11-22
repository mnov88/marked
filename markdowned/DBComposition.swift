//
//  DBComposition.swift
//  markdowned
//
//  Database record model for compositions (document assembly)
//

import Foundation
import GRDB

/// Database record for compositions using GRDB Codable records
struct DBComposition: Identifiable, Codable, FetchableRecord, PersistableRecord {
    var id: String // UUID as string
    var title: String
    var sortMode: String // "manual", "recent", "color", "source"
    var createdAt: Date
    var modifiedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, sortMode, createdAt, modifiedAt
    }

    // Define column names for type-safe queries
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let title = Column(CodingKeys.title)
        static let sortMode = Column(CodingKeys.sortMode)
        static let createdAt = Column(CodingKeys.createdAt)
        static let modifiedAt = Column(CodingKeys.modifiedAt)
    }

    static var databaseTableName: String { "composition" }
}

// MARK: - Factory Methods

extension DBComposition {
    /// Create a new composition with default values
    static func create(title: String, sortMode: String = "manual") -> DBComposition {
        let now = Date()
        return DBComposition(
            id: UUID().uuidString,
            title: title,
            sortMode: sortMode,
            createdAt: now,
            modifiedAt: now
        )
    }

    /// Update modification date
    mutating func touch() {
        self.modifiedAt = Date()
    }
}

// MARK: - Query Helpers

extension DBComposition {
    /// Fetch all compositions ordered by modification date (most recent first)
    static func allOrdered() -> QueryInterfaceRequest<DBComposition> {
        order(Columns.modifiedAt.desc)
    }

    /// Fetch composition by ID
    static func byId(_ id: UUID) -> QueryInterfaceRequest<DBComposition> {
        filter(Columns.id == id.uuidString)
    }
}
