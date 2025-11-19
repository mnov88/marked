//
//  CaseDataParser.swift
//  markdowned
//
//  Created by Milos Novovic on 16/11/2025.
//

import Foundation

struct CaseDataParser {
    /// Parse CSV data into Case objects
    static func parse(_ csvString: String) -> [Case] {
        var cases: [Case] = []
        
        // Split into lines
        let lines = csvString.components(separatedBy: .newlines)
        
        // Skip header row and empty lines
        for line in lines.dropFirst() where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            if let caseData = parseLine(line) {
                cases.append(caseData)
            }
        }
        
        return cases
    }
    
    private static func parseLine(_ line: String) -> Case? {
        let fields = parseCSVLine(line)
        
        // Ensure we have enough fields
        guard fields.count >= 11 else { return nil }
        
        return Case(
            caseNumber: fields[0].trimmingCharacters(in: .whitespaces),
            caseTitle: fields[1].trimmingCharacters(in: .whitespaces),
            requestingCourt: fields[2].trimmingCharacters(in: .whitespaces),
            topics: fields[3].trimmingCharacters(in: .whitespaces),
            judgmentECLI: fields[4].trimmingCharacters(in: .whitespaces),
            judgmentCELEX: fields[5].trimmingCharacters(in: .whitespaces),
            hasAGOpinion: fields[6].trimmingCharacters(in: .whitespaces).lowercased() == "yes",
            agOpinionTitle: fields[7].trimmingCharacters(in: .whitespaces),
            agOpinionECLI: fields[8].trimmingCharacters(in: .whitespaces),
            hasSummary: fields[9].trimmingCharacters(in: .whitespaces).lowercased() == "yes",
            summaryCELEX: fields[10].trimmingCharacters(in: .whitespaces)
        )
    }
    
    /// Parse a CSV line handling quoted fields
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        // Add the last field
        fields.append(currentField)
        
        return fields
    }
}

