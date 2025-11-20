//
//  DatabaseManager.swift
//  markdowned
//
//  Central database management with GRDB
//

import Foundation
import GRDB
import Combine

/// Singleton database manager that handles connection, migrations, and access
@MainActor
final class DatabaseManager {
    static let shared = DatabaseManager()

    private var dbQueue: DatabaseQueue!

    private init() {
        do {
            try setupDatabase()
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }

    // MARK: - Database Setup

    private func setupDatabase() throws {
        let fileManager = FileManager.default
        let documentsPath = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dbPath = documentsPath.appendingPathComponent("marked.sqlite").path

        // Configure database
        var config = Configuration()
        config.prepareDatabase { db in
            // Enable foreign key constraints
            try db.execute(sql: "PRAGMA foreign_keys = ON")

            #if DEBUG
            // Log SQL statements in debug builds
            db.trace { print("SQL: \($0)") }
            #endif
        }

        // Open database connection
        dbQueue = try DatabaseQueue(path: dbPath, configuration: config)

        // Run migrations
        try migrator.migrate(dbQueue)
    }

    // MARK: - Migrations

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        // Enable verbose migration logs in debug
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        // Migration v1: Initial schema
        migrator.registerMigration("v1_initial_schema") { db in
            // Create documents table
            try db.create(table: "document") { t in
                t.primaryKey("id", .text)
                t.column("title", .text).notNull()
                t.column("contentType", .text).notNull() // "plain" or "attributed"
                t.column("contentData", .blob).notNull()
                t.column("sourceURL", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("modifiedAt", .datetime).notNull()
            }

            // Create highlights table
            try db.create(table: "highlight") { t in
                t.primaryKey("id", .text)
                t.column("documentId", .text)
                    .notNull()
                    .indexed()
                    .references("document", onDelete: .cascade)
                t.column("location", .integer).notNull()
                t.column("length", .integer).notNull()
                t.column("colorHex", .text).notNull()
                t.column("createdAt", .datetime).notNull()
            }

            // Create index for efficient highlight queries
            try db.create(index: "idx_highlight_documentId", on: "highlight", columns: ["documentId"])
        }

        // Migration v2: Migrate existing UserDefaults highlights
        migrator.registerMigration("v2_migrate_userdefaults") { db in
            // This migration will be handled by HighlightsManager
            // when it first initializes with GRDB
            print("Migration v2: Ready for UserDefaults highlights migration")
        }

        return migrator
    }

    // MARK: - Database Access

    /// Access database for read operations
    func read<T>(_ block: (Database) throws -> T) throws -> T {
        try dbQueue.read(block)
    }

    /// Access database for write operations
    func write<T>(_ block: (Database) throws -> T) throws -> T {
        try dbQueue.write(block)
    }

    /// Access database queue directly for observations
    var queue: DatabaseQueue {
        dbQueue
    }
}
