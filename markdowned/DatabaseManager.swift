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

    /// Database connection - guaranteed to be initialized or app crashes at startup
    private let dbQueue: DatabaseQueue

    private init() {
        do {
            dbQueue = try Self.createDatabaseQueue()
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }

    // MARK: - Database Setup

    private static func createDatabaseQueue() throws -> DatabaseQueue {
        let fileManager = FileManager.default
        let documentsPath = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dbPath = documentsPath.appendingPathComponent(StorageKeys.databaseFileName).path

        // Configure database
        var config = Configuration()
        config.prepareDatabase { db in
            // Enable foreign key constraints
            try db.execute(sql: "PRAGMA foreign_keys = ON")

            #if DEBUG
            db.trace { Logger.sql($0.description) }
            #endif
        }

        // Open database connection and run migrations
        let queue = try DatabaseQueue(path: dbPath, configuration: config)

        // Run migrations
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        try registerMigrations(on: &migrator)
        try migrator.migrate(queue)

        return queue
    }

    private static func registerMigrations(on migrator: inout DatabaseMigrator) throws {
        // Migration v1: Initial schema
        migrator.registerMigration("v1_initial_schema") { db in
            try db.create(table: "document") { t in
                t.primaryKey("id", .text)
                t.column("title", .text).notNull()
                t.column("contentType", .text).notNull()
                t.column("contentData", .blob).notNull()
                t.column("sourceURL", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("modifiedAt", .datetime).notNull()
            }

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

            try db.create(index: "idx_highlight_documentId", on: "highlight", columns: ["documentId"])
        }

        // Migration v2: UserDefaults migration marker
        migrator.registerMigration("v2_migrate_userdefaults") { _ in
            Logger.debug("Migration v2: Ready for UserDefaults highlights migration")
        }

        // Migration v3: Compositions
        migrator.registerMigration("v3_compositions") { db in
            try db.create(table: "composition") { t in
                t.primaryKey("id", .text)
                t.column("title", .text).notNull()
                t.column("sortMode", .text).notNull().defaults(to: "manual")
                t.column("createdAt", .datetime).notNull()
                t.column("modifiedAt", .datetime).notNull()
            }

            try db.create(table: "compositionFragment") { t in
                t.primaryKey("id", .text)
                t.column("compositionId", .text)
                    .notNull()
                    .indexed()
                    .references("composition", onDelete: .cascade)
                t.column("highlightId", .text)
                    .notNull()
                    .indexed()
                    .references("highlight", onDelete: .cascade)
                t.column("sortOrder", .integer).notNull()
                t.column("createdAt", .datetime).notNull()
                t.uniqueKey(["compositionId", "highlightId"])
            }

            try db.create(index: "idx_compositionFragment_compositionId", on: "compositionFragment", columns: ["compositionId"])
            try db.create(index: "idx_compositionFragment_highlightId", on: "compositionFragment", columns: ["highlightId"])

            Logger.debug("Migration v3: Created composition tables")
        }

        // Migration v4: Categories
        migrator.registerMigration("v4_categories") { db in
            try db.create(table: "category") { t in
                t.primaryKey("id", .text)
                t.column("name", .text).notNull()
                t.column("colorHex", .text).notNull()
                t.column("icon", .text).notNull()
                t.column("sortOrder", .integer).notNull().defaults(to: 0)
                t.column("createdAt", .datetime).notNull()
            }

            try db.create(table: "documentCategory") { t in
                t.column("documentId", .text)
                    .notNull()
                    .references("document", onDelete: .cascade)
                t.column("categoryId", .text)
                    .notNull()
                    .references("category", onDelete: .cascade)
                t.column("addedAt", .datetime).notNull()
                t.primaryKey(["documentId", "categoryId"])
            }

            try db.create(index: "idx_documentCategory_documentId", on: "documentCategory", columns: ["documentId"])
            try db.create(index: "idx_documentCategory_categoryId", on: "documentCategory", columns: ["categoryId"])

            Logger.debug("Migration v4: Created category tables")
        }

        // Migration v5: Full-text search with FTS5
        migrator.registerMigration("v5_fts") { db in
            // Add contentText column to store searchable plain text
            try db.alter(table: "document") { t in
                t.add(column: "contentText", .text)
            }

            // Populate contentText for existing documents
            // For plain type, contentData is UTF-8 text; for attributed, we extract during app runtime
            try db.execute(sql: """
                UPDATE document SET contentText = CAST(contentData AS TEXT)
                WHERE contentType = 'plain'
            """)

            // Create FTS5 virtual table for full-text search
            try db.execute(sql: """
                CREATE VIRTUAL TABLE document_fts USING fts5(
                    title,
                    contentText,
                    content='document',
                    content_rowid='rowid'
                )
            """)

            // Populate FTS index with existing documents
            try db.execute(sql: """
                INSERT INTO document_fts(document_fts) VALUES('rebuild')
            """)

            // Create triggers to keep FTS in sync
            try db.execute(sql: """
                CREATE TRIGGER document_ai AFTER INSERT ON document BEGIN
                    INSERT INTO document_fts(rowid, title, contentText)
                    VALUES (NEW.rowid, NEW.title, NEW.contentText);
                END
            """)

            try db.execute(sql: """
                CREATE TRIGGER document_ad AFTER DELETE ON document BEGIN
                    INSERT INTO document_fts(document_fts, rowid, title, contentText)
                    VALUES ('delete', OLD.rowid, OLD.title, OLD.contentText);
                END
            """)

            try db.execute(sql: """
                CREATE TRIGGER document_au AFTER UPDATE ON document BEGIN
                    INSERT INTO document_fts(document_fts, rowid, title, contentText)
                    VALUES ('delete', OLD.rowid, OLD.title, OLD.contentText);
                    INSERT INTO document_fts(rowid, title, contentText)
                    VALUES (NEW.rowid, NEW.title, NEW.contentText);
                END
            """)

            Logger.debug("Migration v5: Created FTS5 full-text search")
        }

        // Migration v6: Case law database with FTS5 for fast search
        migrator.registerMigration("v6_case_law") { db in
            // Create case_law table for EU legal cases
            try db.create(table: "case_law") { t in
                t.primaryKey("id", .text)
                t.column("caseNumber", .text).notNull()
                t.column("caseTitle", .text).notNull()
                t.column("requestingCourt", .text).notNull()
                t.column("topics", .text).notNull()
                t.column("judgmentECLI", .text).notNull()
                t.column("judgmentCELEX", .text).notNull()
                t.column("hasAGOpinion", .boolean).notNull().defaults(to: false)
                t.column("agOpinionTitle", .text).notNull()
                t.column("agOpinionECLI", .text).notNull()
                t.column("hasSummary", .boolean).notNull().defaults(to: false)
                t.column("summaryCELEX", .text).notNull()

                // Pre-computed lowercase fields for fast filtering
                t.column("caseNumberLower", .text).notNull()
                t.column("caseTitleLower", .text).notNull()
                t.column("judgmentCELEXLower", .text).notNull()
            }

            // Create indexes for common queries
            try db.create(index: "idx_case_law_caseNumber", on: "case_law", columns: ["caseNumber"])
            try db.create(index: "idx_case_law_judgmentCELEX", on: "case_law", columns: ["judgmentCELEX"])

            // Create FTS5 virtual table for full-text search
            try db.execute(sql: """
                CREATE VIRTUAL TABLE case_law_fts USING fts5(
                    caseNumber,
                    caseTitle,
                    judgmentCELEX,
                    topics,
                    content='case_law',
                    content_rowid='rowid',
                    tokenize='unicode61 remove_diacritics 1'
                )
            """)

            // Create triggers to keep FTS in sync
            try db.execute(sql: """
                CREATE TRIGGER case_law_ai AFTER INSERT ON case_law BEGIN
                    INSERT INTO case_law_fts(rowid, caseNumber, caseTitle, judgmentCELEX, topics)
                    VALUES (NEW.rowid, NEW.caseNumber, NEW.caseTitle, NEW.judgmentCELEX, NEW.topics);
                END
            """)

            try db.execute(sql: """
                CREATE TRIGGER case_law_ad AFTER DELETE ON case_law BEGIN
                    INSERT INTO case_law_fts(case_law_fts, rowid, caseNumber, caseTitle, judgmentCELEX, topics)
                    VALUES ('delete', OLD.rowid, OLD.caseNumber, OLD.caseTitle, OLD.judgmentCELEX, OLD.topics);
                END
            """)

            try db.execute(sql: """
                CREATE TRIGGER case_law_au AFTER UPDATE ON case_law BEGIN
                    INSERT INTO case_law_fts(case_law_fts, rowid, caseNumber, caseTitle, judgmentCELEX, topics)
                    VALUES ('delete', OLD.rowid, OLD.caseNumber, OLD.caseTitle, OLD.judgmentCELEX, OLD.topics);
                    INSERT INTO case_law_fts(rowid, caseNumber, caseTitle, judgmentCELEX, topics)
                    VALUES (NEW.rowid, NEW.caseNumber, NEW.caseTitle, NEW.judgmentCELEX, NEW.topics);
                END
            """)

            Logger.debug("Migration v6: Created case_law table with FTS5")
        }
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
