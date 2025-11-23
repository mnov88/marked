//
//  CategoriesManager.swift
//  markdowned
//
//  Global categories manager with GRDB persistence
//

import Foundation
import SwiftUI
import Combine
import GRDB

@MainActor
final class CategoriesManager: ObservableObject {
    static let shared = CategoriesManager()

    @Published private(set) var categories: [Category] = []
    @Published var lastError: AppError?

    private var observationCancellable: AnyCancellable?
    private let db = DatabaseManager.shared

    private init() {
        setupObservation()
    }

    // MARK: - Database Observation

    private func setupObservation() {
        let observation = ValueObservation.tracking { db in
            try DBCategory.allOrdered().fetchAll(db)
        }

        observationCancellable = observation
            .publisher(in: db.queue, scheduling: .immediate)
            .catch { error -> Just<[DBCategory]> in
                Logger.error("Categories observation error", error: error)
                return Just([])
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dbCategories in
                self?.categories = dbCategories.compactMap { try? $0.toCategory() }
            }
    }

    // MARK: - CRUD Operations

    /// Create a new category
    func createCategory(name: String, color: PlatformColor = .systemBlue, icon: String = "folder") throws -> UUID {
        let dbCategory = DBCategory.create(name: name, color: color, icon: icon)
        try db.write { db in
            try dbCategory.insert(db)
        }
        guard let uuid = dbCategory.id.uuid else {
            throw DatabaseError(message: "Failed to parse UUID for newly created category")
        }
        lastError = nil
        return uuid
    }

    /// Update a category
    func updateCategory(_ categoryId: UUID, name: String? = nil, color: PlatformColor? = nil, icon: String? = nil) throws {
        try db.write { db in
            guard var category = try DBCategory.fetchOne(db, key: categoryId.uuidString) else {
                throw DatabaseError(message: "Category not found: \(categoryId)")
            }
            if let name = name { category.name = name }
            if let color = color { category.colorHex = color.hexString }
            if let icon = icon { category.icon = icon }
            try category.update(db)
        }
        lastError = nil
    }

    /// Delete a category
    func deleteCategory(_ categoryId: UUID) throws {
        try db.write { db in
            try DBCategory.deleteOne(db, key: categoryId.uuidString)
        }
        lastError = nil
    }

    /// Reorder categories
    func reorderCategories(fromOffsets source: IndexSet, toOffset destination: Int) {
        var updatedCategories = categories
        updatedCategories.move(fromOffsets: source, toOffset: destination)

        do {
            try db.write { db in
                for (index, category) in updatedCategories.enumerated() {
                    try db.execute(
                        sql: "UPDATE category SET sortOrder = ? WHERE id = ?",
                        arguments: [index, category.id.uuidString]
                    )
                }
            }
            lastError = nil
        } catch {
            lastError = .database("Failed to reorder categories: \(error.localizedDescription)")
        }
    }

    // MARK: - Document-Category Operations

    /// Add a document to a category
    func addDocument(_ documentId: UUID, toCategory categoryId: UUID) throws {
        let junction = DBDocumentCategory.create(documentId: documentId, categoryId: categoryId)
        try db.write { db in
            try junction.insert(db)
        }
        lastError = nil
    }

    /// Remove a document from a category
    func removeDocument(_ documentId: UUID, fromCategory categoryId: UUID) throws {
        try db.write { db in
            try db.execute(
                sql: "DELETE FROM documentCategory WHERE documentId = ? AND categoryId = ?",
                arguments: [documentId.uuidString, categoryId.uuidString]
            )
        }
        lastError = nil
    }

    /// Get categories for a document
    func categories(for documentId: UUID) -> [Category] {
        do {
            let categoryIds = try db.read { db in
                try DBDocumentCategory.categories(forDocument: documentId)
                    .fetchAll(db)
                    .map { $0.categoryId }
            }
            return categories.filter { categoryIds.contains($0.id.uuidString) }
        } catch {
            Logger.error("Failed to get categories for document", error: error)
            return []
        }
    }

    /// Get document IDs in a category
    func documentIds(in categoryId: UUID) -> [UUID] {
        do {
            return try db.read { db in
                try DBDocumentCategory.documents(inCategory: categoryId)
                    .fetchAll(db)
                    .compactMap { $0.documentId.uuid }
            }
        } catch {
            Logger.error("Failed to get documents in category", error: error)
            return []
        }
    }

    /// Clear error state
    func clearError() {
        lastError = nil
    }
}
