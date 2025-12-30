//
//  EurlexDatabaseManager.swift
//  markdowned
//
//  Manages the bundled EUR-Lex database with FTS5 full-text search.
//  Supports legislation, case law, articles, relationships, and Eurovoc concepts.
//  The database is copied from the app bundle to Documents on first launch.
//

import Foundation
import GRDB
import Combine

/// Manager for the bundled EUR-Lex database
/// Provides full-text search with relevance ranking for both legislation and case law
@MainActor
final class EurlexDatabaseManager: ObservableObject {
    static let shared = EurlexDatabaseManager()

    // MARK: - Published Properties

    @Published private(set) var isReady: Bool = false
    @Published private(set) var totalCaseCount: Int = 0
    @Published private(set) var totalLegislationCount: Int = 0

    /// Database connection (read-only)
    private var dbQueue: DatabaseQueue?

    /// Cached FTS table existence flags (checked once at init)
    private var hasCaseLawFTS: Bool = false
    private var hasLegislationFTS: Bool = false

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
            totalCaseCount = try countTable("case_law")
            totalLegislationCount = try countTable("legislation")

            // Cache FTS table existence (checked once, not per-query)
            hasCaseLawFTS = try checkFTSTableExists("case_law_fts")
            hasLegislationFTS = try checkFTSTableExists("legislation_fts")

            isReady = true
            Logger.info("EUR-Lex database ready: \(totalCaseCount) cases, \(totalLegislationCount) legislation, FTS: case=\(hasCaseLawFTS) leg=\(hasLegislationFTS)")
        } catch {
            Logger.error("Failed to initialize EUR-Lex database", error: error)
            isReady = false
        }
    }

    /// Check if an FTS5 virtual table exists
    private func checkFTSTableExists(_ tableName: String) throws -> Bool {
        guard let dbQueue = dbQueue else { return false }
        return try dbQueue.read { db in
            try Bool.fetchOne(db, sql: """
                SELECT COUNT(*) > 0 FROM sqlite_master
                WHERE type='table' AND name=?
            """, arguments: [tableName]) ?? false
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

    /// Count rows in a table
    private func countTable(_ table: String) throws -> Int {
        guard let dbQueue = dbQueue else { return 0 }
        return try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(table)") ?? 0
        }
    }

    // MARK: - Case Law Search

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

        // Use cached FTS flag instead of per-query check
        if hasCaseLawFTS {
            return try dbQueue.read { db in
                // Query using FTS5 with BM25 ranking
                // bm25() returns negative values where more negative = better match
                // case_law_fts columns: celex(0), ecli(1), casenumber(2), title(3), shorttitle(4), parties(5), court(6)
                // Use shorttitle (4) for snippet - title is often generic "Official Journal..." text
                let sql = """
                    SELECT
                        c.*,
                        bm25(case_law_fts) as rank,
                        snippet(case_law_fts, 4, '<mark>', '</mark>', '...', 64) as snippet
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
        } else {
            // Fallback to LIKE search if no FTS
            return try dbQueue.read { db in
                let sql = """
                    SELECT * FROM case_law
                    WHERE title LIKE ? OR celex LIKE ? OR case_number LIKE ? OR parties LIKE ?
                    ORDER BY date_judgment DESC
                    LIMIT ?
                """
                let pattern = "%\(query)%"
                return try DBCaseLaw
                    .fetchAll(db, sql: sql, arguments: [pattern, pattern, pattern, pattern, limit])
                    .map { CaseLawSearchResult(caseLaw: $0, rank: 0, snippet: nil) }
            }
        }
    }

    /// @Published search results for reactive UI binding
    @Published private(set) var searchResults: [CaseLawSearchResult] = []

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

    /// Fetch cases by year (extracted from CELEX: 6YYYYXX...)
    func fetchCases(byYear year: Int, limit: Int = 100) throws -> [DBCaseLaw] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            // Extract year from CELEX (format: 6YYYYXX where YYYY is the year)
            let sql = """
                SELECT * FROM case_law
                WHERE CAST(SUBSTR(celex, 2, 4) AS INTEGER) = ?
                ORDER BY case_number
                LIMIT ?
            """
            return try DBCaseLaw.fetchAll(db, sql: sql, arguments: [year, limit])
        }
    }

    /// Fetch recent cases (by judgment date descending)
    func fetchRecentCases(limit: Int = 20) throws -> [DBCaseLaw] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try DBCaseLaw
                .order(DBCaseLaw.Columns.dateJudgment.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    /// Get available years for filtering (from CELEX numbers)
    func fetchAvailableCaseYears() throws -> [Int] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            let sql = """
                SELECT DISTINCT CAST(SUBSTR(celex, 2, 4) AS INTEGER) as year
                FROM case_law
                WHERE LENGTH(celex) >= 5
                ORDER BY year DESC
            """
            return try Int.fetchAll(db, sql: sql)
        }
    }

    // MARK: - Legislation Search

    /// Search legislation using FTS5 full-text search with BM25 ranking
    func searchLegislation(query: String, limit: Int = 50) throws -> [LegislationSearchResult] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let ftsQuery = prepareFTSQuery(query)

        // Use cached FTS flag instead of per-query check
        if hasLegislationFTS {
            return try dbQueue.read { db in
                // Using default BM25 weights for FTS column compatibility
                // snippet() column 2 = title in legislation_fts (celex, eli, title, ...)
                let sql = """
                    SELECT
                        l.*,
                        bm25(legislation_fts) as rank,
                        snippet(legislation_fts, 2, '<mark>', '</mark>', '...', 64) as snippet
                    FROM legislation l
                    JOIN legislation_fts fts ON l.rowid = fts.rowid
                    WHERE legislation_fts MATCH ?
                    ORDER BY rank ASC
                    LIMIT ?
                """
                let rows = try Row.fetchAll(db, sql: sql, arguments: [ftsQuery, limit])

                return rows.compactMap { row -> LegislationSearchResult? in
                    guard let legislation = try? DBLegislation(row: row) else { return nil }
                    let rank = row["rank"] as? Double ?? 0
                    let snippet = row["snippet"] as? String
                    return LegislationSearchResult(legislation: legislation, rank: rank, snippet: snippet)
                }
            }
        } else {
            // Fallback to LIKE search if no FTS
            return try dbQueue.read { db in
                let sql = """
                    SELECT * FROM legislation
                    WHERE title LIKE ? OR celex LIKE ? OR short_title LIKE ?
                    ORDER BY doc_year DESC
                    LIMIT ?
                """
                let pattern = "%\(query)%"
                return try DBLegislation
                    .fetchAll(db, sql: sql, arguments: [pattern, pattern, pattern, limit])
                    .map { LegislationSearchResult(legislation: $0, rank: 0, snippet: nil) }
            }
        }
    }

    /// Fetch legislation by CELEX
    func fetchLegislation(byCelex celex: String) throws -> DBLegislation? {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }
        return try dbQueue.read { db in
            try DBLegislation.filter(DBLegislation.Columns.celex == celex).fetchOne(db)
        }
    }

    /// Fetch legislation by document type
    func fetchLegislation(byType type: String, limit: Int = 100) throws -> [DBLegislation] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }
        return try dbQueue.read { db in
            try DBLegislation
                .filter(DBLegislation.Columns.docType == type)
                .order(DBLegislation.Columns.docYear.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    /// Fetch legislation by year
    func fetchLegislation(byYear year: Int, limit: Int = 100) throws -> [DBLegislation] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }
        return try dbQueue.read { db in
            try DBLegislation
                .filter(DBLegislation.Columns.docYear == year)
                .order(DBLegislation.Columns.docNumber)
                .limit(limit)
                .fetchAll(db)
        }
    }

    /// Get available document types
    func fetchAvailableDocTypes() throws -> [String] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }
        return try dbQueue.read { db in
            try String.fetchAll(db, sql: "SELECT DISTINCT doc_type FROM legislation ORDER BY doc_type")
        }
    }

    // MARK: - Relationship Queries

    /// Get legislation that amends a specific document
    func fetchAmendments(for celex: String) throws -> [DBLegislation] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }
        return try dbQueue.read { db in
            let sql = """
                SELECT l.* FROM legislation l
                JOIN legal_relation lr ON l.id = lr.source_id
                WHERE lr.target_celex = ? AND lr.relation_type = 'amends'
                ORDER BY l.date_document DESC
            """
            return try DBLegislation.fetchAll(db, sql: sql, arguments: [celex])
        }
    }

    /// Get all related legislation for a document
    func fetchRelatedLegislation(for celex: String) throws -> [(DBLegislation, String)] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }
        return try dbQueue.read { db in
            let sql = """
                SELECT l.*, lr.relation_type FROM legislation l
                JOIN legal_relation lr ON l.id = lr.source_id
                WHERE lr.target_celex = ?
                ORDER BY lr.relation_type, l.date_document DESC
            """
            let rows = try Row.fetchAll(db, sql: sql, arguments: [celex])
            return rows.compactMap { row -> (DBLegislation, String)? in
                guard let leg = try? DBLegislation(row: row) else { return nil }
                let relType = row["relation_type"] as? String ?? "unknown"
                return (leg, relType)
            }
        }
    }

    /// Get Eurovoc concepts for legislation
    func fetchEurovocConcepts(for legislationId: String) throws -> [DBEurovocConcept] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }
        return try dbQueue.read { db in
            let sql = """
                SELECT ec.* FROM eurovoc_concept ec
                JOIN legislation_eurovoc le ON ec.id = le.eurovoc_id
                WHERE le.legislation_id = ?
                ORDER BY ec.label
            """
            return try DBEurovocConcept.fetchAll(db, sql: sql, arguments: [legislationId])
        }
    }

    /// Get cases interpreting a specific article
    func fetchCasesInterpreting(articleNum: Int, legislationCelex: String) throws -> [DBCaseLaw] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }
        return try dbQueue.read { db in
            let sql = """
                SELECT c.* FROM case_law c
                JOIN case_article_interpretation cai ON c.id = cai.case_id
                JOIN article a ON cai.article_id = a.id
                JOIN legislation l ON a.legislation_id = l.id
                WHERE l.celex = ? AND a.article_num = ?
                ORDER BY c.date_judgment DESC
            """
            return try DBCaseLaw.fetchAll(db, sql: sql, arguments: [legislationCelex, articleNum])
        }
    }

    /// Get articles interpreted by a case
    func fetchInterpretedArticles(forCase caseId: String) throws -> [(DBArticle, DBLegislation)] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }
        return try dbQueue.read { db in
            let sql = """
                SELECT a.*, l.* FROM article a
                JOIN case_article_interpretation cai ON a.id = cai.article_id
                JOIN legislation l ON a.legislation_id = l.id
                WHERE cai.case_id = ?
                ORDER BY l.celex, a.article_num
            """
            let rows = try Row.fetchAll(db, sql: sql, arguments: [caseId])
            return rows.compactMap { row -> (DBArticle, DBLegislation)? in
                guard let article = try? DBArticle(row: row),
                      let leg = try? DBLegislation(row: row) else { return nil }
                return (article, leg)
            }
        }
    }

    /// Get cases citing a specific case
    func fetchCitingCases(for celex: String) throws -> [DBCaseLaw] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }
        return try dbQueue.read { db in
            let sql = """
                SELECT c.* FROM case_law c
                JOIN case_citation cc ON c.id = cc.citing_case_id
                WHERE cc.cited_celex = ?
                ORDER BY c.date_judgment DESC
            """
            return try DBCaseLaw.fetchAll(db, sql: sql, arguments: [celex])
        }
    }

    /// Get most cited cases
    func fetchMostCitedCases(limit: Int = 20) throws -> [(DBCaseLaw, Int)] {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }
        return try dbQueue.read { db in
            let sql = """
                SELECT c.*, COUNT(cc.id) as citation_count
                FROM case_law c
                JOIN case_citation cc ON c.id = cc.cited_case_id
                GROUP BY c.id
                ORDER BY citation_count DESC
                LIMIT ?
            """
            let rows = try Row.fetchAll(db, sql: sql, arguments: [limit])
            return rows.compactMap { row -> (DBCaseLaw, Int)? in
                guard let caseLaw = try? DBCaseLaw(row: row) else { return nil }
                let count = row["citation_count"] as? Int ?? 0
                return (caseLaw, count)
            }
        }
    }

    // MARK: - Statistics

    /// Get database statistics
    func fetchStatistics() throws -> EurlexStatistics {
        guard let dbQueue = dbQueue else {
            throw EurlexError.databaseNotInitialized
        }
        return try dbQueue.read { db in
            let caseCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM case_law") ?? 0
            let legCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM legislation") ?? 0
            let articleCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM article") ?? 0
            let relationCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM legal_relation") ?? 0
            let eurovocCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM eurovoc_concept") ?? 0
            let citationCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM case_citation") ?? 0

            return EurlexStatistics(
                caseCount: caseCount,
                legislationCount: legCount,
                articleCount: articleCount,
                relationCount: relationCount,
                eurovocCount: eurovocCount,
                citationCount: citationCount
            )
        }
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

// MARK: - Statistics Types

struct EurlexStatistics {
    let caseCount: Int
    let legislationCount: Int
    let articleCount: Int
    let relationCount: Int
    let eurovocCount: Int
    let citationCount: Int
}

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
