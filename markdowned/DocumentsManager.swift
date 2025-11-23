//
//  DocumentsManager.swift
//  markdowned
//
//  Global documents manager with GRDB persistence
//

import Foundation
import SwiftUI
import Combine
import GRDB

@MainActor
final class DocumentsManager: ObservableObject {
    static let shared = DocumentsManager()

    @Published var documents: [Document] = []

    // Error state for UI feedback
    @Published var lastError: AppError?

    private var observationCancellable: AnyCancellable?
    private let db = DatabaseManager.shared

    private init() {
        setupObservation()
        initializeDefaultDocuments()
    }

    // MARK: - Database Observation

    private func setupObservation() {
        // Create ValueObservation for reactive updates
        let observation = ValueObservation.tracking { db in
            try DBDocument
                .order(DBDocument.Columns.modifiedAt.desc)
                .fetchAll(db)
        }

        // Observe database changes and update @Published documents
        observationCancellable = observation
            .publisher(in: db.queue, scheduling: .immediate)
            .catch { error -> Just<[DBDocument]> in
                print("Documents observation error: \(error)")
                return Just([])
            }
            .map { dbDocuments in
                // Convert database records to app models
                dbDocuments.compactMap { try? $0.toDocument() }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \DocumentsManager.documents, on: self)
    }

    // MARK: - Initialization

    private func initializeDefaultDocuments() {
        Task {
            do {
                // Check if database is empty
                let count = try db.read { db in
                    try DBDocument.fetchCount(db)
                }

                // If empty, add default documents
                if count == 0 {
                    try await createDefaultDocuments()
                }
            } catch {
                print("Error initializing documents: \(error)")
            }
        }
    }

    private func createDefaultDocuments() async throws {
        let s1 = LoremGen.plain(paragraphs: 30)
        let s2 = dsaText
        let attr = NSMutableAttributedString(string: "Article 4\n\n1. Mixed content for demo.")

        let documents = [
            Document.plain(s1, title: "Regulation — Part I"),
            Document.plain(s2, title: "Regulation — Part II"),
            Document.attributed(attr, title: "Regulation — Part III (Attributed)")
        ]

        for document in documents {
            try addDocument(document)
        }
    }

    // MARK: - CRUD Operations

    /// Create: Add a new document to the database
    func addDocument(_ document: Document) throws {
        let dbDocument = try DBDocument(fromDocument: document)
        try db.write { db in
            try dbDocument.insert(db)
        }
    }

    /// Read: Get a document by ID
    func document(withId id: UUID) -> Document? {
        documents.first { $0.id == id }
    }

    /// Read: Get a document from database (for immediate access)
    func fetchDocument(withId id: UUID) throws -> Document? {
        try db.read { db in
            if let dbDoc = try DBDocument.fetchOne(db, key: id.uuidString) {
                return try dbDoc.toDocument()
            }
            return nil
        }
    }

    /// Update: Update an existing document
    func updateDocument(_ document: Document) throws {
        var dbDocument = try DBDocument(fromDocument: document)
        dbDocument.touch() // Update modifiedAt timestamp

        try db.write { db in
            try dbDocument.update(db)
        }
    }

    /// Delete: Remove a document by ID
    func deleteDocument(id: UUID) throws {
        _ = try db.write { db in
            try DBDocument.deleteOne(db, key: id.uuidString)
        }
    }

    /// Delete: Remove multiple documents
    func deleteDocuments(ids: [UUID]) throws {
        _ = try db.write { db in
            for id in ids {
                try DBDocument.deleteOne(db, key: id.uuidString)
            }
        }
    }

    /// Delete: Remove all documents
    func deleteAllDocuments() throws {
        _ = try db.write { db in
            try DBDocument.deleteAll(db)
        }
    }

    // MARK: - Query Operations

    /// Search documents by title (legacy)
    func searchDocuments(title: String) throws -> [Document] {
        try db.read { db in
            let dbDocuments = try DBDocument
                .filter(DBDocument.Columns.title.like("%\(title)%"))
                .order(DBDocument.Columns.modifiedAt.desc)
                .fetchAll(db)
            return try dbDocuments.map { try $0.toDocument() }
        }
    }

    /// Get documents count
    func documentsCount() throws -> Int {
        try db.read { db in
            try DBDocument.fetchCount(db)
        }
    }

    // MARK: - Full-Text Search

    /// Full-text search across document titles and content using FTS5
    /// - Parameters:
    ///   - query: Search query (supports FTS5 syntax: AND, OR, NOT, phrases "like this")
    ///   - limit: Maximum results to return
    /// - Returns: Array of matching documents with relevance-ranked results
    func fullTextSearch(query: String, limit: Int = PaginationConstants.searchResultsLimit) throws -> [Document] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }

        // Escape special FTS5 characters and prepare query
        let sanitizedQuery = sanitizeFTSQuery(query)

        return try db.read { db in
            // Use FTS5 MATCH with ranking by relevance (bm25)
            let sql = """
                SELECT document.*
                FROM document
                JOIN document_fts ON document.rowid = document_fts.rowid
                WHERE document_fts MATCH ?
                ORDER BY bm25(document_fts) ASC
                LIMIT ?
            """

            let dbDocuments = try DBDocument.fetchAll(db, sql: sql, arguments: [sanitizedQuery, limit])
            return dbDocuments.compactMap { try? $0.toDocument() }
        }
    }

    /// Search with snippet highlighting
    /// Returns tuples of (document, highlighted snippet)
    func fullTextSearchWithSnippets(query: String, limit: Int = PaginationConstants.searchResultsLimit) throws -> [(Document, String)] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }

        let sanitizedQuery = sanitizeFTSQuery(query)

        return try db.read { db in
            let sql = """
                SELECT document.*,
                       snippet(document_fts, 1, '<mark>', '</mark>', '...', 32) as matchSnippet
                FROM document
                JOIN document_fts ON document.rowid = document_fts.rowid
                WHERE document_fts MATCH ?
                ORDER BY bm25(document_fts) ASC
                LIMIT ?
            """

            let rows = try Row.fetchAll(db, sql: sql, arguments: [sanitizedQuery, limit])
            return rows.compactMap { row -> (Document, String)? in
                guard let dbDoc = try? DBDocument(row: row),
                      let doc = try? dbDoc.toDocument() else {
                    return nil
                }
                let snippet = row["matchSnippet"] as? String ?? ""
                return (doc, snippet)
            }
        }
    }

    /// Sanitize query for FTS5 - convert natural language to FTS5 syntax
    private func sanitizeFTSQuery(_ query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespaces)

        // If query contains FTS5 operators, use as-is
        let ftsOperators = ["AND", "OR", "NOT", "\"", "*"]
        let hasOperators = ftsOperators.contains { trimmed.contains($0) }

        if hasOperators {
            return trimmed
        }

        // Convert space-separated words to prefix search (word*)
        let words = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        return words.map { "\($0)*" }.joined(separator: " ")
    }
}
