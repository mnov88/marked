//
//  EurlexDatabaseManager.swift
//  markdowned
//
//  Manages the bundled EUR-Lex case law database with FTS5 full-text search.
//  The database is copied from the app bundle to Documents on first launch.
//

import Foundation
import GRDB
import Combine

/// Manager for the bundled EUR-Lex case law database
/// Provides full-text search with relevance ranking
@MainActor
final class EurlexDatabaseManager: ObservableObject {
    static let shared = EurlexDatabaseManager()

    /// Published search results for reactive UI updates
    @Published private(set) var searchResults: [CaseLawSearchResult] = []
    @Published private(set) var isReady: Bool = false
    @Published private(set) var totalCaseCount: Int = 0

    /// Database connection (read-only)
    private var dbQueue: DatabaseQueue?

    private init() {
        Task {
            await initialize()
        }
    }

    // MARK: - Initialization

    /// Initialize database connection, copying from bundle if needed
    private func initialize() async {
        do {
            let dbPath = try await ensureDatabase()
            dbQueue = try openDatabase(at: dbPath)
            totalCaseCount = try countCases()
            isReady = true
            Logger.info("EUR-Lex database ready with \(totalCaseCount) cases")
        } catch {
            Logger.error("Failed to initialize EUR-Lex database", error: error)
            isReady = false
        }
    }

    /// Ensure database exists in Documents, copying from bundle if needed
    private func ensureDatabase() async throws -> String {
        let fileManager = FileManager.default
        let documentsPath = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let destinationURL = documentsPath.appendingPathComponent(StorageKeys.eurlexDatabaseFileName)

        // Check if database already exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            Logger.debug("EUR-Lex database exists at: \(destinationURL.path)")
            return destinationURL.path
        }

        // Copy from bundle
        guard let bundleURL = Bundle.main.url(forResource: "eurlex", withExtension: "db") else {
            throw EurlexError.bundleDatabaseNotFound
        }

        try fileManager.copyItem(at: bundleURL, to: destinationURL)
        Logger.info("Copied EUR-Lex database from bundle to: \(destinationURL.path)")

        return destinationURL.path
    }

    /// Open database connection with read-only configuration
    private func openDatabase(at path: String) throws -> DatabaseQueue {
        var config = Configuration()
        config.readonly = true
        config.prepareDatabase { db in
            // Enable foreign keys (even though read-only)
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }

        return try DatabaseQueue(path: path, configuration: config)
    }

    /// Count total cases in database
    private func countCases() throws -> Int {
        guard let dbQueue = dbQueue else { return 0 }
        return try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM case_law") ?? 0
        }
    }

    // MARK: - Search

    /// Search case law using FTS5 full-text search with BM25 ranking
    /// - Parameters:
    ///   - query: Search query string
    ///   - limit: Maximum number of results (default 50)
    /// - Returns: Array of search results sorted by relevance
    func search(query: String, limit: Int = 50) throws -> [CaseLawSearchResult] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        // Prepare FTS5 query - escape special characters and add prefix matching
        let ftsQuery = prepareFTSQuery(query)

        return try dbQueue.read { db in
            // Query using FTS5 with BM25 ranking
            // bm25() returns negative values where more negative = better match
            let sql = """
                SELECT
                    c.*,
                    bm25(case_law_fts, 10.0, 5.0, 2.0, 1.0, 1.0, 0.5) as rank,
                    snippet(case_law_fts, 1, '<mark>', '</mark>', '...', 32) as snippet
                FROM case_law c
                JOIN case_law_fts fts ON c.rowid = fts.rowid
                WHERE case_law_fts MATCH ?
                ORDER BY rank ASC
                LIMIT ?
            """

            let rows = try Row.fetchAll(db, sql: sql, arguments: [ftsQuery, limit])

            return rows.compactMap { row -> CaseLawSearchResult? in
                guard let caseLaw = try? DBCaseLaw(row: row) else { return nil }
                let rank = row["rank"] as? Double ?? 0
                let snippet = row["snippet"] as? String
                return CaseLawSearchResult(caseLaw: caseLaw, rank: rank, snippet: snippet)
            }
        }
    }

    /// Search and update published results (for reactive UI)
    func searchAndPublish(query: String, limit: Int = 50) {
        do {
            searchResults = try search(query: query, limit: limit)
        } catch {
            Logger.error("Case law search failed", error: error)
            searchResults = []
        }
    }

    /// Prepare FTS5 query with proper escaping and prefix matching
    private func prepareFTSQuery(_ query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Split into words and prepare for FTS5
        let words = trimmed.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { word -> String in
                // Escape FTS5 special characters
                let escaped = word
                    .replacingOccurrences(of: "\"", with: "\"\"")
                    .replacingOccurrences(of: "-", with: " ")

                // Add prefix matching for partial word search
                return "\"\(escaped)\"*"
            }

        // Combine words with OR for broader matching
        return words.joined(separator: " OR ")
    }

    // MARK: - Direct Queries

    /// Fetch a single case by CELEX number
    func fetchCase(byCelex celex: String) throws -> DBCaseLaw? {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try DBCaseLaw.filter(DBCaseLaw.Columns.celex == celex).fetchOne(db)
        }
    }

    /// Fetch cases by year
    func fetchCases(byYear year: Int, limit: Int = 100) throws -> [DBCaseLaw] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try DBCaseLaw
                .filter(DBCaseLaw.Columns.docYear == year)
                .order(DBCaseLaw.Columns.caseNumber)
                .limit(limit)
                .fetchAll(db)
        }
    }

    /// Fetch recent cases (by year descending)
    func fetchRecentCases(limit: Int = 20) throws -> [DBCaseLaw] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try DBCaseLaw
                .order(DBCaseLaw.Columns.docYear.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    /// Get available years for filtering
    func fetchAvailableYears() throws -> [Int] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            let sql = "SELECT DISTINCT doc_year FROM case_law WHERE doc_year IS NOT NULL ORDER BY doc_year DESC"
            return try Int.fetchAll(db, sql: sql)
        }
    }

    // MARK: - Statistics

    /// Get search statistics for a query
    func searchStatistics(query: String) throws -> SearchStatistics {
        let results = try search(query: query, limit: 1000)

        var yearDistribution: [Int: Int] = [:]
        for result in results {
            if let year = result.caseLaw.docYear {
                yearDistribution[year, default: 0] += 1
            }
        }

        return SearchStatistics(
            totalResults: results.count,
            yearDistribution: yearDistribution,
            hasAGOpinionCount: results.filter { $0.caseLaw.hasAgOpinion }.count
        )
    }
}

// MARK: - Error Types

enum EurlexError: LocalizedError {
    case bundleDatabaseNotFound
    case databaseNotInitialized
    case searchFailed(String)

    var errorDescription: String? {
        switch self {
        case .bundleDatabaseNotFound:
            return "EUR-Lex database not found in app bundle"
        case .databaseNotInitialized:
            return "EUR-Lex database not initialized"
        case .searchFailed(let reason):
            return "Search failed: \(reason)"
        }
    }
}

// MARK: - Search Statistics

struct SearchStatistics {
    let totalResults: Int
    let yearDistribution: [Int: Int]
    let hasAGOpinionCount: Int

    var topYears: [(year: Int, count: Int)] {
        yearDistribution
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { (year: $0.key, count: $0.value) }
    }
}
