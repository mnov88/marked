//
//  DBDocument.swift
//  markdowned
//
//  Database record model for documents
//

import Foundation
import GRDB
import UIKit

/// Database record for documents - conforms to GRDB protocols
struct DBDocument: Codable, Identifiable {
    var id: String // UUID as string
    var title: String
    var contentType: String // "plain" or "attributed"
    var contentData: Data
    var sourceURL: String?
    var createdAt: Date
    var modifiedAt: Date

    // Define column names for type-safe queries
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let title = Column(CodingKeys.title)
        static let contentType = Column(CodingKeys.contentType)
        static let contentData = Column(CodingKeys.contentData)
        static let sourceURL = Column(CodingKeys.sourceURL)
        static let createdAt = Column(CodingKeys.createdAt)
        static let modifiedAt = Column(CodingKeys.modifiedAt)
    }
}

// MARK: - GRDB Protocols

extension DBDocument: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "document" }
}

// MARK: - Conversion to/from Document

extension DBDocument {
    /// Convert from app's Document model to database record
    init(from document: Document) throws {
        self.id = document.id.uuidString
        self.title = document.title
        self.sourceURL = document.sourceURL?.absoluteString

        // Convert content to data
        switch document.content {
        case .plain(let text):
            self.contentType = "plain"
            guard let data = text.data(using: .utf8) else {
                throw DatabaseError.SQLITE_ERROR
            }
            self.contentData = data

        case .attributed(let attributedString):
            self.contentType = "attributed"
            // Use NSKeyedArchiver for NSAttributedString
            do {
                self.contentData = try NSKeyedArchiver.archivedData(
                    withRootObject: attributedString,
                    requiringSecureCoding: false
                )
            } catch {
                throw DatabaseError.SQLITE_ERROR
            }
        }

        let now = Date()
        self.createdAt = now
        self.modifiedAt = now
    }

    /// Convert database record to app's Document model
    func toDocument() throws -> Document {
        guard let uuid = UUID(uuidString: id) else {
            throw DatabaseError.SQLITE_ERROR
        }

        let url = sourceURL.flatMap { URL(string: $0) }

        let content: Document.Content
        switch contentType {
        case "plain":
            guard let text = String(data: contentData, encoding: .utf8) else {
                throw DatabaseError.SQLITE_ERROR
            }
            content = .plain(text)

        case "attributed":
            do {
                guard let attributedString = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(contentData) as? NSAttributedString else {
                    throw DatabaseError.SQLITE_ERROR
                }
                content = .attributed(attributedString)
            } catch {
                throw DatabaseError.SQLITE_ERROR
            }

        default:
            throw DatabaseError.SQLITE_ERROR
        }

        return Document(id: uuid, title: title, content: content, sourceURL: url)
    }

    /// Update modification date
    mutating func touch() {
        self.modifiedAt = Date()
    }
}
