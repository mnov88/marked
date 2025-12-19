//
//  Case.swift
//  markdowned
//
//  Created by Milos Novovic on 16/11/2025.
//

import Foundation
import GRDB

// MARK: - Case (View Model)

struct Case: Identifiable, Hashable {
    let id: UUID
    let caseNumber: String
    let caseTitle: String
    let requestingCourt: String
    let topics: String
    let judgmentECLI: String
    let judgmentCELEX: String
    let hasAGOpinion: Bool
    let agOpinionTitle: String
    let agOpinionECLI: String
    let hasSummary: Bool
    let summaryCELEX: String

    init(
        id: UUID = UUID(),
        caseNumber: String,
        caseTitle: String,
        requestingCourt: String,
        topics: String,
        judgmentECLI: String,
        judgmentCELEX: String,
        hasAGOpinion: Bool,
        agOpinionTitle: String,
        agOpinionECLI: String,
        hasSummary: Bool,
        summaryCELEX: String
    ) {
        self.id = id
        self.caseNumber = caseNumber
        self.caseTitle = caseTitle
        self.requestingCourt = requestingCourt
        self.topics = topics
        self.judgmentECLI = judgmentECLI
        self.judgmentCELEX = judgmentCELEX
        self.hasAGOpinion = hasAGOpinion
        self.agOpinionTitle = agOpinionTitle
        self.agOpinionECLI = agOpinionECLI
        self.hasSummary = hasSummary
        self.summaryCELEX = summaryCELEX
    }

    var displayTitle: String {
        caseTitle.isEmpty ? caseNumber : caseTitle
    }

    var celexURL: URL? {
        guard !judgmentCELEX.isEmpty else { return nil }
        return URL(string: "https://publications.europa.eu/resource/celex/\(judgmentCELEX.replacingOccurrences(of: "_SUM", with: ""))")
    }
}

// MARK: - DBCaseLaw (Database Record)

/// Database record for case law, with GRDB persistence
struct DBCaseLaw: Identifiable, Codable, FetchableRecord, PersistableRecord {
    var id: String
    var caseNumber: String
    var caseTitle: String
    var requestingCourt: String
    var topics: String
    var judgmentECLI: String
    var judgmentCELEX: String
    var hasAGOpinion: Bool
    var agOpinionTitle: String
    var agOpinionECLI: String
    var hasSummary: Bool
    var summaryCELEX: String

    // Pre-computed lowercase for fast LIKE queries (backup to FTS)
    var caseNumberLower: String
    var caseTitleLower: String
    var judgmentCELEXLower: String

    static var databaseTableName: String { "case_law" }

    /// Create from a Case view model
    init(from case_: Case) {
        self.id = case_.id.uuidString
        self.caseNumber = case_.caseNumber
        self.caseTitle = case_.caseTitle
        self.requestingCourt = case_.requestingCourt
        self.topics = case_.topics
        self.judgmentECLI = case_.judgmentECLI
        self.judgmentCELEX = case_.judgmentCELEX
        self.hasAGOpinion = case_.hasAGOpinion
        self.agOpinionTitle = case_.agOpinionTitle
        self.agOpinionECLI = case_.agOpinionECLI
        self.hasSummary = case_.hasSummary
        self.summaryCELEX = case_.summaryCELEX

        // Pre-compute lowercase versions
        self.caseNumberLower = case_.caseNumber.lowercased()
        self.caseTitleLower = case_.caseTitle.lowercased()
        self.judgmentCELEXLower = case_.judgmentCELEX.lowercased()
    }

    /// Convert to Case view model
    func toCase() -> Case {
        Case(
            id: UUID(uuidString: id) ?? UUID(),
            caseNumber: caseNumber,
            caseTitle: caseTitle,
            requestingCourt: requestingCourt,
            topics: topics,
            judgmentECLI: judgmentECLI,
            judgmentCELEX: judgmentCELEX,
            hasAGOpinion: hasAGOpinion,
            agOpinionTitle: agOpinionTitle,
            agOpinionECLI: agOpinionECLI,
            hasSummary: hasSummary,
            summaryCELEX: summaryCELEX
        )
    }
}

