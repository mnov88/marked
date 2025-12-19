//
//  DBLegislation.swift
//  markdowned
//
//  Database record model for EU legislation from bundled eurlex.db
//

import Foundation
import GRDB

/// Database record for EU legislation using GRDB
/// Maps to the legislation table in eurlex.db
struct DBLegislation: Identifiable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    var celex: String
    var eli: String?
    var docType: String
    var docYear: Int
    var docNumber: Int?
    var title: String
    var shortTitle: String?
    var dateDocument: String?
    var dateInForce: String?
    var dateEndValidity: String?
    var inForce: Bool
    var createdBy: String?
    var subjectMatter: String?
    var importedAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case celex
        case eli
        case docType = "doc_type"
        case docYear = "doc_year"
        case docNumber = "doc_number"
        case title
        case shortTitle = "short_title"
        case dateDocument = "date_document"
        case dateInForce = "date_in_force"
        case dateEndValidity = "date_end_validity"
        case inForce = "in_force"
        case createdBy = "created_by"
        case subjectMatter = "subject_matter"
        case importedAt = "imported_at"
        case updatedAt = "updated_at"
    }

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let celex = Column(CodingKeys.celex)
        static let eli = Column(CodingKeys.eli)
        static let docType = Column(CodingKeys.docType)
        static let docYear = Column(CodingKeys.docYear)
        static let docNumber = Column(CodingKeys.docNumber)
        static let title = Column(CodingKeys.title)
        static let shortTitle = Column(CodingKeys.shortTitle)
        static let dateDocument = Column(CodingKeys.dateDocument)
        static let dateInForce = Column(CodingKeys.dateInForce)
        static let dateEndValidity = Column(CodingKeys.dateEndValidity)
        static let inForce = Column(CodingKeys.inForce)
        static let createdBy = Column(CodingKeys.createdBy)
        static let subjectMatter = Column(CodingKeys.subjectMatter)
        static let importedAt = Column(CodingKeys.importedAt)
        static let updatedAt = Column(CodingKeys.updatedAt)
    }

    static var databaseTableName: String { "legislation" }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        celex = try container.decode(String.self, forKey: .celex)
        eli = try container.decodeIfPresent(String.self, forKey: .eli)
        docType = try container.decode(String.self, forKey: .docType)
        docYear = try container.decode(Int.self, forKey: .docYear)
        docNumber = try container.decodeIfPresent(Int.self, forKey: .docNumber)
        title = try container.decode(String.self, forKey: .title)
        shortTitle = try container.decodeIfPresent(String.self, forKey: .shortTitle)
        dateDocument = try container.decodeIfPresent(String.self, forKey: .dateDocument)
        dateInForce = try container.decodeIfPresent(String.self, forKey: .dateInForce)
        dateEndValidity = try container.decodeIfPresent(String.self, forKey: .dateEndValidity)
        inForce = (try container.decodeIfPresent(Int.self, forKey: .inForce) ?? 1) != 0
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        subjectMatter = try container.decodeIfPresent(String.self, forKey: .subjectMatter)
        importedAt = try container.decode(String.self, forKey: .importedAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }

    /// EUR-Lex URL for this legislation
    var eurlexURL: URL? {
        URL(string: "https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:\(celex)")
    }

    /// Cellar URL for full text
    var cellarURL: URL? {
        URL(string: "https://publications.europa.eu/resource/celex/\(celex)")
    }

    /// Display name (short title if available, otherwise truncated title)
    var displayTitle: String {
        shortTitle ?? String(title.prefix(100))
    }
}

// MARK: - Document Type

enum LegislationDocType: String, CaseIterable {
    case regulation = "REG"
    case directive = "DIR"
    case decision = "DEC"
    case regulationImpl = "REG-IMPL"
    case decisionImpl = "DEC-IMPL"
    case regulationDel = "REG-DEL"
    case decisionDel = "DEC-DEL"

    var displayName: String {
        switch self {
        case .regulation: return "Regulation"
        case .directive: return "Directive"
        case .decision: return "Decision"
        case .regulationImpl: return "Implementing Regulation"
        case .decisionImpl: return "Implementing Decision"
        case .regulationDel: return "Delegated Regulation"
        case .decisionDel: return "Delegated Decision"
        }
    }

    var icon: String {
        switch self {
        case .regulation, .regulationImpl, .regulationDel: return "doc.text.fill"
        case .directive: return "arrow.triangle.branch"
        case .decision, .decisionImpl, .decisionDel: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Search Result

struct LegislationSearchResult: Identifiable {
    let legislation: DBLegislation
    let rank: Double
    let snippet: String?

    var id: String { legislation.id }
}
