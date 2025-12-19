//
//  CaseLawManager.swift
//  markdowned
//
//  Manager for EU case law database with FTS5 search
//

import Foundation
import SwiftUI
import Combine
import GRDB

@MainActor
final class CaseLawManager: ObservableObject {
    static let shared = CaseLawManager()

    /// Whether the case law database has been initialized
    @Published private(set) var isInitialized = false

    /// Total count of cases in database
    @Published private(set) var caseCount = 0

    private let db = DatabaseManager.shared

    private init() {
        Task {
            await initializeCaseLawDatabase()
        }
    }

    // MARK: - Initialization

    /// Initialize the case law database from bundled CSV if needed
    private func initializeCaseLawDatabase() async {
        do {
            // Check if database already has cases
            let count = try db.read { db in
                try DBCaseLaw.fetchCount(db)
            }

            if count > 0 {
                caseCount = count
                isInitialized = true
                Logger.debug("Case law database already initialized with \(count) cases")
                return
            }

            // Import from bundled CSV
            try await importFromCSV()
            isInitialized = true

        } catch {
            Logger.error("Failed to initialize case law database", error: error)
        }
    }

    /// Import cases from bundled CSV file
    private func importFromCSV() async throws {
        guard let csvPath = Bundle.main.path(forResource: "allcases", ofType: "csv"),
              let csvString = try? String(contentsOfFile: csvPath, encoding: .utf8) else {
            Logger.debug("Could not load allcases.csv from bundle")
            return
        }

        // Parse CSV (reuse existing parser)
        let cases = CaseDataParser.parse(csvString)
        Logger.debug("Parsed \(cases.count) cases from CSV, importing to database...")

        // Insert in batches for performance
        let batchSize = 500
        var imported = 0

        try db.write { db in
            for case_ in cases {
                let record = DBCaseLaw(from: case_)
                try record.insert(db)
                imported += 1
            }
        }

        caseCount = imported
        Logger.debug("Imported \(imported) cases to database")
    }

    // MARK: - Search

    /// Search cases using FTS5 full-text search
    /// - Parameter query: Search query string
    /// - Parameter limit: Maximum results to return (default 50)
    /// - Returns: Array of matching Case objects
    func search(query: String, limit: Int = 50) throws -> [Case] {
        guard !query.isEmpty else { return [] }

        // Escape special FTS5 characters and prepare query
        let sanitizedQuery = sanitizeFTSQuery(query)

        return try db.read { db in
            // Use FTS5 MATCH for fast full-text search
            let sql = """
                SELECT case_law.*
                FROM case_law
                JOIN case_law_fts ON case_law.rowid = case_law_fts.rowid
                WHERE case_law_fts MATCH ?
                ORDER BY bm25(case_law_fts)
                LIMIT ?
            """

            let records = try DBCaseLaw.fetchAll(db, sql: sql, arguments: [sanitizedQuery, limit])
            return records.map { $0.toCase() }
        }
    }

    /// Fallback search using LIKE (if FTS query fails)
    /// - Parameter query: Search query string
    /// - Parameter limit: Maximum results to return
    /// - Returns: Array of matching Case objects
    func searchWithLike(query: String, limit: Int = 50) throws -> [Case] {
        guard !query.isEmpty else { return [] }

        let lowerQuery = query.lowercased()
        let pattern = "%\(lowerQuery)%"

        return try db.read { db in
            let sql = """
                SELECT * FROM case_law
                WHERE caseNumberLower LIKE ?
                   OR caseTitleLower LIKE ?
                   OR judgmentCELEXLower LIKE ?
                LIMIT ?
            """

            let records = try DBCaseLaw.fetchAll(db, sql: sql, arguments: [pattern, pattern, pattern, limit])
            return records.map { $0.toCase() }
        }
    }

    /// Combined search: tries FTS5 first, falls back to LIKE
    func searchCases(query: String, limit: Int = 50) -> [Case] {
        guard !query.isEmpty else { return [] }

        do {
            // Try FTS5 first (fastest)
            let results = try search(query: query, limit: limit)
            if !results.isEmpty {
                return results
            }

            // Fallback to LIKE for partial matches
            return try searchWithLike(query: query, limit: limit)
        } catch {
            Logger.error("Case search failed", error: error)

            // Last resort: try LIKE search
            do {
                return try searchWithLike(query: query, limit: limit)
            } catch {
                return []
            }
        }
    }

    // MARK: - Helpers

    /// Sanitize query for FTS5 MATCH
    private func sanitizeFTSQuery(_ query: String) -> String {
        // Remove special FTS5 operators and wrap in quotes for phrase matching
        // Also add * for prefix matching
        let cleaned = query
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Use prefix matching with *
        if cleaned.contains(" ") {
            // Multiple words: match each as prefix
            let words = cleaned.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .map { "\($0)*" }
            return words.joined(separator: " ")
        } else {
            // Single word: prefix match
            return "\(cleaned)*"
        }
    }

    /// Get a case by CELEX number
    func caseBy(celex: String) throws -> Case? {
        try db.read { db in
            try DBCaseLaw
                .filter(Column("judgmentCELEX") == celex)
                .fetchOne(db)?
                .toCase()
        }
    }

    /// Get a case by case number (e.g., "C-673/17")
    func caseBy(number: String) throws -> Case? {
        try db.read { db in
            try DBCaseLaw
                .filter(Column("caseNumber") == number)
                .fetchOne(db)?
                .toCase()
        }
    }
}
