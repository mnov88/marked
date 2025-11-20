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
            .assign(to: \.documents, on: self)
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
        let dbDocument = try DBDocument(from: document)
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
        var dbDocument = try DBDocument(from: document)
        dbDocument.touch() // Update modifiedAt timestamp

        try db.write { db in
            try dbDocument.update(db)
        }
    }

    /// Delete: Remove a document by ID
    func deleteDocument(id: UUID) throws {
        try db.write { db in
            try DBDocument.deleteOne(db, key: id.uuidString)
        }
    }

    /// Delete: Remove multiple documents
    func deleteDocuments(ids: [UUID]) throws {
        try db.write { db in
            for id in ids {
                try DBDocument.deleteOne(db, key: id.uuidString)
            }
        }
    }

    /// Delete: Remove all documents
    func deleteAllDocuments() throws {
        try db.write { db in
            try DBDocument.deleteAll(db)
        }
    }

    // MARK: - Query Operations

    /// Search documents by title
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
}
