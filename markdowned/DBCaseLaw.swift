//
//  DBCaseLaw.swift
//  markdowned
//
//  Database record model for EU case law from bundled eurlex.db
//  Schema: DATABASE_SCHEMA.md section 2. case_law
//

import Foundation
import GRDB

/// Database record for EU case law using GRDB
/// Maps to the case_law table in eurlex.db
struct DBCaseLaw: Identifiable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    var celex: String
    var ecli: String?
    var caseNumber: String?
    var title: String?
    var shortTitle: String?
    var parties: String?
    var court: String?
    var procedureType: String?
    var originCountry: String?
    var dateJudgment: String?
    var dateRequest: String?
    var hasAgOpinion: Bool
    var agOpinionEcli: String?
    var importedAt: String
    var updatedAt: String

    // GRDB column name mapping (snake_case in DB)
    enum CodingKeys: String, CodingKey {
        case id
        case celex
        case ecli
        case caseNumber = "case_number"
        case title
        case shortTitle = "short_title"
        case parties
        case court
        case procedureType = "procedure_type"
        case originCountry = "origin_country"
        case dateJudgment = "date_judgment"
        case dateRequest = "date_request"
        case hasAgOpinion = "has_ag_opinion"
        case agOpinionEcli = "ag_opinion_ecli"
        case importedAt = "imported_at"
        case updatedAt = "updated_at"
    }

    /// Column accessors for type-safe queries
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let celex = Column(CodingKeys.celex)
        static let ecli = Column(CodingKeys.ecli)
        static let caseNumber = Column(CodingKeys.caseNumber)
        static let title = Column(CodingKeys.title)
        static let shortTitle = Column(CodingKeys.shortTitle)
        static let parties = Column(CodingKeys.parties)
        static let court = Column(CodingKeys.court)
        static let procedureType = Column(CodingKeys.procedureType)
        static let originCountry = Column(CodingKeys.originCountry)
        static let dateJudgment = Column(CodingKeys.dateJudgment)
        static let dateRequest = Column(CodingKeys.dateRequest)
        static let hasAgOpinion = Column(CodingKeys.hasAgOpinion)
        static let agOpinionEcli = Column(CodingKeys.agOpinionEcli)
        static let importedAt = Column(CodingKeys.importedAt)
        static let updatedAt = Column(CodingKeys.updatedAt)
    }

    static var databaseTableName: String { "case_law" }

    /// Custom decoder for SQLite INTEGER -> Bool conversion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        celex = try container.decode(String.self, forKey: .celex)
        ecli = try container.decodeIfPresent(String.self, forKey: .ecli)
        caseNumber = try container.decodeIfPresent(String.self, forKey: .caseNumber)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        shortTitle = try container.decodeIfPresent(String.self, forKey: .shortTitle)
        parties = try container.decodeIfPresent(String.self, forKey: .parties)
        court = try container.decodeIfPresent(String.self, forKey: .court)
        procedureType = try container.decodeIfPresent(String.self, forKey: .procedureType)
        originCountry = try container.decodeIfPresent(String.self, forKey: .originCountry)
        dateJudgment = try container.decodeIfPresent(String.self, forKey: .dateJudgment)
        dateRequest = try container.decodeIfPresent(String.self, forKey: .dateRequest)

        // SQLite stores booleans as INTEGER (0/1)
        hasAgOpinion = (try container.decodeIfPresent(Int.self, forKey: .hasAgOpinion) ?? 0) != 0
        agOpinionEcli = try container.decodeIfPresent(String.self, forKey: .agOpinionEcli)
        importedAt = try container.decode(String.self, forKey: .importedAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }

    /// EUR-Lex URL for this case
    var eurlexURL: URL? {
        URL(string: "https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:\(celex)")
    }

    /// Cellar URL for full text
    var cellarURL: URL? {
        URL(string: "https://publications.europa.eu/resource/celex/\(celex)")
    }

    /// Extract year from CELEX (format: 6YYYYXX... where YYYY is year)
    var year: Int? {
        guard celex.count >= 5 else { return nil }
        let startIndex = celex.index(celex.startIndex, offsetBy: 1)
        let endIndex = celex.index(celex.startIndex, offsetBy: 5)
        return Int(celex[startIndex..<endIndex])
    }

    /// Display title (short title if available, otherwise case number or celex)
    var displayTitle: String {
        shortTitle ?? caseNumber ?? celex
    }
}

// MARK: - FTS Search Result

/// Result from FTS5 full-text search with relevance ranking
struct CaseLawSearchResult: Identifiable {
    let caseLaw: DBCaseLaw
    let rank: Double
    let snippet: String?

    var id: String { caseLaw.id }
}
