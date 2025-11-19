//
//  Case.swift
//  markdowned
//
//  Created by Milos Novovic on 16/11/2025.
//

import Foundation

struct Case: Identifiable, Hashable {
    let id = UUID()
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
    
    var displayTitle: String {
        caseTitle.isEmpty ? caseNumber : caseTitle
    }
    
    var celexURL: URL? {
        guard !judgmentCELEX.isEmpty else { return nil }
        print("https://publications.europa.eu/resource/celex/\(judgmentCELEX.replacingOccurrences(of: "_SUM", with: ""))")
        return URL(string: "https://publications.europa.eu/resource/celex/\(judgmentCELEX.replacingOccurrences(of: "_SUM", with: ""))")
    }
    
    // For search matching
    func matches(searchText: String) -> Bool {
        let search = searchText.lowercased()
        return caseNumber.lowercased().contains(search) ||
               caseTitle.lowercased().contains(search) ||
               judgmentCELEX.lowercased().contains(search)
    }
}

