//
//  DBEurlexRelations.swift
//  markdowned
//
//  Database models for EUR-Lex relationships: articles, interpretations,
//  legal relations, Eurovoc concepts, and case citations.
//

import Foundation
import GRDB

// MARK: - Article

/// Article reference within legislation
struct DBArticle: Identifiable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    var legislationId: String
    var articleNum: Int
    var paragraphNum: Int?
    var point: String?
    var displayText: String
    var rawReference: String?

    enum CodingKeys: String, CodingKey {
        case id
        case legislationId = "legislation_id"
        case articleNum = "article_num"
        case paragraphNum = "paragraph_num"
        case point
        case displayText = "display_text"
        case rawReference = "raw_reference"
    }

    /// Column accessors for type-safe queries
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let legislationId = Column(CodingKeys.legislationId)
        static let articleNum = Column(CodingKeys.articleNum)
        static let paragraphNum = Column(CodingKeys.paragraphNum)
        static let point = Column(CodingKeys.point)
        static let displayText = Column(CodingKeys.displayText)
        static let rawReference = Column(CodingKeys.rawReference)
    }

    static var databaseTableName: String { "article" }

    // MARK: - Associations

    /// The legislation this article belongs to
    static let legislation = belongsTo(DBLegislation.self, using: ForeignKey(["legislation_id"]))

    /// Cases that interpret this article
    static let interpretations = hasMany(DBCaseArticleInterpretation.self, using: ForeignKey(["article_id"]))
}

// MARK: - Case Article Interpretation

/// Links cases to articles they interpret
struct DBCaseArticleInterpretation: Identifiable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    var caseId: String
    var articleId: String
    var interpretationType: String  // interprets, preliminary_question, interpreted_by

    enum CodingKeys: String, CodingKey {
        case id
        case caseId = "case_id"
        case articleId = "article_id"
        case interpretationType = "interpretation_type"
    }

    /// Column accessors for type-safe queries
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let caseId = Column(CodingKeys.caseId)
        static let articleId = Column(CodingKeys.articleId)
        static let interpretationType = Column(CodingKeys.interpretationType)
    }

    static var databaseTableName: String { "case_article_interpretation" }

    // MARK: - Associations

    /// The case that interprets
    static let caseLaw = belongsTo(DBCaseLaw.self, using: ForeignKey(["case_id"]))

    /// The article being interpreted
    static let article = belongsTo(DBArticle.self, using: ForeignKey(["article_id"]))
}

// MARK: - Legal Relation

/// Legal relationships between legislation documents
struct DBLegalRelation: Identifiable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    var sourceId: String
    var targetCelex: String
    var targetId: String?
    var relationType: String

    enum CodingKeys: String, CodingKey {
        case id
        case sourceId = "source_id"
        case targetCelex = "target_celex"
        case targetId = "target_id"
        case relationType = "relation_type"
    }

    /// Column accessors for type-safe queries
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let sourceId = Column(CodingKeys.sourceId)
        static let targetCelex = Column(CodingKeys.targetCelex)
        static let targetId = Column(CodingKeys.targetId)
        static let relationType = Column(CodingKeys.relationType)
    }

    static var databaseTableName: String { "legal_relation" }

    // MARK: - Associations

    /// The source legislation
    static let source = belongsTo(DBLegislation.self, key: "source", using: ForeignKey(["source_id"]))

    /// The target legislation (if imported)
    static let target = belongsTo(DBLegislation.self, key: "target", using: ForeignKey(["target_id"]))
}

enum LegalRelationType: String, CaseIterable {
    case basedOn = "based_on"
    case cites = "cites"
    case amends = "amends"
    case repeals = "repeals"
    case consolidatedBy = "consolidated_by"
    case correctedBy = "corrected_by"
    case treatyBasis = "treaty_basis"

    var displayName: String {
        switch self {
        case .basedOn: return "Based on"
        case .cites: return "Cites"
        case .amends: return "Amends"
        case .repeals: return "Repeals"
        case .consolidatedBy: return "Consolidated by"
        case .correctedBy: return "Corrected by"
        case .treatyBasis: return "Treaty basis"
        }
    }

    var icon: String {
        switch self {
        case .basedOn: return "arrow.down.doc"
        case .cites: return "quote.opening"
        case .amends: return "pencil.line"
        case .repeals: return "xmark.circle"
        case .consolidatedBy: return "doc.on.doc"
        case .correctedBy: return "exclamationmark.triangle"
        case .treatyBasis: return "building.columns"
        }
    }
}

// MARK: - Eurovoc Concept

/// Eurovoc thesaurus concept for subject classification
struct DBEurovocConcept: Identifiable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    var label: String
    var domainId: String?
    var domainLabel: String?

    enum CodingKeys: String, CodingKey {
        case id
        case label
        case domainId = "domain_id"
        case domainLabel = "domain_label"
    }

    /// Column accessors for type-safe queries
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let label = Column(CodingKeys.label)
        static let domainId = Column(CodingKeys.domainId)
        static let domainLabel = Column(CodingKeys.domainLabel)
    }

    static var databaseTableName: String { "eurovoc_concept" }

    // MARK: - Associations

    /// Legislation tagged with this concept (via join table)
    static let legislationLinks = hasMany(DBLegislationEurovoc.self, using: ForeignKey(["eurovoc_id"]))
}

/// Junction table for legislation-Eurovoc many-to-many
struct DBLegislationEurovoc: Codable, FetchableRecord, PersistableRecord {
    var legislationId: String
    var eurovocId: String

    enum CodingKeys: String, CodingKey {
        case legislationId = "legislation_id"
        case eurovocId = "eurovoc_id"
    }

    /// Column accessors for type-safe queries
    enum Columns {
        static let legislationId = Column(CodingKeys.legislationId)
        static let eurovocId = Column(CodingKeys.eurovocId)
    }

    static var databaseTableName: String { "legislation_eurovoc" }

    // MARK: - Associations

    /// The legislation
    static let legislation = belongsTo(DBLegislation.self, using: ForeignKey(["legislation_id"]))

    /// The Eurovoc concept
    static let eurovoc = belongsTo(DBEurovocConcept.self, using: ForeignKey(["eurovoc_id"]))
}

// MARK: - Legislation Title (Multilingual)

/// Multilingual titles for legislation
struct DBLegislationTitle: Identifiable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    var legislationId: String
    var language: String  // eng, fra, deu, spa, ita
    var title: String

    enum CodingKeys: String, CodingKey {
        case id
        case legislationId = "legislation_id"
        case language
        case title
    }

    /// Column accessors for type-safe queries
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let legislationId = Column(CodingKeys.legislationId)
        static let language = Column(CodingKeys.language)
        static let title = Column(CodingKeys.title)
    }

    static var databaseTableName: String { "legislation_title" }

    // MARK: - Associations

    /// The legislation this title belongs to
    static let legislation = belongsTo(DBLegislation.self, using: ForeignKey(["legislation_id"]))
}

// MARK: - Case Citation

/// Citations between cases (case-to-case references)
struct DBCaseCitation: Identifiable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    var citingCaseId: String
    var citedCelex: String
    var citedCaseId: String?
    var citedEcli: String?

    enum CodingKeys: String, CodingKey {
        case id
        case citingCaseId = "citing_case_id"
        case citedCelex = "cited_celex"
        case citedCaseId = "cited_case_id"
        case citedEcli = "cited_ecli"
    }

    /// Column accessors for type-safe queries
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let citingCaseId = Column(CodingKeys.citingCaseId)
        static let citedCelex = Column(CodingKeys.citedCelex)
        static let citedCaseId = Column(CodingKeys.citedCaseId)
        static let citedEcli = Column(CodingKeys.citedEcli)
    }

    static var databaseTableName: String { "case_citation" }

    // MARK: - Associations

    /// The case that cites
    static let citingCase = belongsTo(DBCaseLaw.self, key: "citingCase", using: ForeignKey(["citing_case_id"]))

    /// The cited case (if imported)
    static let citedCase = belongsTo(DBCaseLaw.self, key: "citedCase", using: ForeignKey(["cited_case_id"]))
}
