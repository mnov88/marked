//
//  DBHighlight.swift
//  markdowned
//
//  Database record model for highlights
//

import Foundation
import GRDB
import UIKit

/// Database record for highlights - conforms to GRDB protocols
struct DBHighlight: Codable, Identifiable {
    var id: String // UUID as string
    var documentId: String // UUID as string (foreign key)
    var location: Int
    var length: Int
    var colorHex: String
    var createdAt: Date

    // Define column names for type-safe queries
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let documentId = Column(CodingKeys.documentId)
        static let location = Column(CodingKeys.location)
        static let length = Column(CodingKeys.length)
        static let colorHex = Column(CodingKeys.colorHex)
        static let createdAt = Column(CodingKeys.createdAt)
    }
}

// MARK: - GRDB Protocols

extension DBHighlight: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "highlight" }
}

// MARK: - Conversion to/from DHTextHighlight

extension DBHighlight {
    /// Convert from app's DHTextHighlight model to database record
    init(from highlight: DHTextHighlight, documentId: UUID) {
        self.id = highlight.id.uuidString
        self.documentId = documentId.uuidString
        self.location = highlight.range.location
        self.length = highlight.range.length
        self.colorHex = highlight.color.hexString
        self.createdAt = Date()
    }

    /// Convert database record to app's DHTextHighlight model
    func toHighlight() throws -> DHTextHighlight {
        guard let uuid = UUID(uuidString: id) else {
            throw DatabaseError.SQLITE_ERROR
        }

        let range = NSRange(location: location, length: length)
        let color = UIColor(hex: colorHex) ?? .systemYellow

        return DHTextHighlight(id: uuid, range: range, color: color)
    }
}

// MARK: - Query Helpers

extension DBHighlight {
    /// Fetch all highlights for a specific document
    static func highlightsForDocument(_ documentId: UUID) -> QueryInterfaceRequest<DBHighlight> {
        filter(Columns.documentId == documentId.uuidString)
            .order(Columns.location)
    }

    /// Delete all highlights for a specific document
    static func deleteForDocument(_ documentId: UUID, db: Database) throws {
        try filter(Columns.documentId == documentId.uuidString).deleteAll(db)
    }
}
