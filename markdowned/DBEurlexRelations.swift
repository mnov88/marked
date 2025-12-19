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

    static var databaseTableName: String { "article" }
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

    static var databaseTableName: String { "case_article_interpretation" }
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

    static var databaseTableName: String { "legal_relation" }
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

    static var databaseTableName: String { "eurovoc_concept" }
}

/// Junction table for legislation-Eurovoc many-to-many
struct DBLegislationEurovoc: Codable, FetchableRecord, PersistableRecord {
    var legislationId: String
    var eurovocId: String

    enum CodingKeys: String, CodingKey {
        case legislationId = "legislation_id"
        case eurovocId = "eurovoc_id"
    }

    static var databaseTableName: String { "legislation_eurovoc" }
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

    static var databaseTableName: String { "legislation_title" }
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

    static var databaseTableName: String { "case_citation" }
}
