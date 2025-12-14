//
//  Category.swift
//  markdowned
//
//  Document category models for organization
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - In-Memory Category Model

/// Represents a document category for organization
struct Category: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var color: PlatformColor
    var icon: String
    var sortOrder: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        color: PlatformColor = .systemBlue,
        icon: String = "folder",
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    // MARK: - Default Categories

    static let allDocuments = Category(
        name: "All Documents",
        color: .systemGray,
        icon: "doc.text",
        sortOrder: -2
    )

    static let uncategorized = Category(
        name: "Uncategorized",
        color: .systemGray2,
        icon: "tray",
        sortOrder: -1
    )

    static let highlights = Category(
        name: "Highlights",
        color: .systemYellow,
        icon: "highlighter",
        sortOrder: -3
    )

    // MARK: - Codable Conformance

    enum CodingKeys: String, CodingKey {
        case id, name, colorHex, icon, sortOrder, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let colorHex = try container.decode(String.self, forKey: .colorHex)
        color = PlatformColor(hex: colorHex) ?? .systemBlue
        icon = try container.decode(String.self, forKey: .icon)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(color.toHex(), forKey: .colorHex)
        try container.encode(icon, forKey: .icon)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - Database Category Model

import GRDB

struct DBCategory: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "category"

    var id: String
    var name: String
    var colorHex: String
    var icon: String
    var sortOrder: Int
    var createdAt: Date

    // MARK: - Convenience Initializers
    
    init(id: String, name: String, colorHex: String, icon: String, sortOrder: Int, createdAt: Date) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
    
    static func create(name: String, color: PlatformColor = .systemBlue, icon: String = "folder") -> DBCategory {
        DBCategory(
            id: UUID().uuidString,
            name: name,
            colorHex: color.hexString,
            icon: icon,
            sortOrder: 0,
            createdAt: Date()
        )
    }

    init(from category: Category) {
        self.id = category.id.uuidString
        self.name = category.name
        self.colorHex = category.color.hexString
        self.icon = category.icon
        self.sortOrder = category.sortOrder
        self.createdAt = category.createdAt
    }

    func toCategory() throws -> Category {
        guard let uuid = id.uuid else {
            throw DatabaseError(message: "Invalid UUID string: \(id)")
        }
        return Category(
            id: uuid,
            name: name,
            color: PlatformColor(hex: colorHex) ?? .systemBlue,
            icon: icon,
            sortOrder: sortOrder,
            createdAt: createdAt
        )
    }

    // MARK: - Queries

    static func allOrdered() -> QueryInterfaceRequest<DBCategory> {
        DBCategory.order(Column("sortOrder").asc, Column("name").asc)
    }
}

// MARK: - Document-Category Junction Table

struct DBDocumentCategory: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "documentCategory"

    var documentId: String
    var categoryId: String
    var addedAt: Date

    static func create(documentId: UUID, categoryId: UUID) -> DBDocumentCategory {
        DBDocumentCategory(
            documentId: documentId.uuidString,
            categoryId: categoryId.uuidString,
            addedAt: Date()
        )
    }

    static func categories(forDocument documentId: UUID) -> QueryInterfaceRequest<DBDocumentCategory> {
        DBDocumentCategory.filter(Column("documentId") == documentId.uuidString)
    }

    static func documents(inCategory categoryId: UUID) -> QueryInterfaceRequest<DBDocumentCategory> {
        DBDocumentCategory.filter(Column("categoryId") == categoryId.uuidString)
    }
}
