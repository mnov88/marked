//
//  markdownedTests.swift
//  markdownedTests
//
//  Created by Milos Novovic on 05/11/2025.
//

import Testing
import Foundation
@testable import markdowned

struct markdownedTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func headingDetectionMatchesLegalFormatterPatterns() async throws {
        let content = """
JUDGMENT OF THE COURT

The questions referred

Hereby rules:
"""
        let spans = DHConfig.defaultHeadings(content as NSString)
        let ns = content as NSString

        #expect(spans.count == 3)
        #expect(ns.substring(with: spans[0].range) == "JUDGMENT OF THE COURT")
        #expect(ns.substring(with: spans[1].range) == "The questions referred")
        #expect(ns.substring(with: spans[2].range) == "Hereby rules:")

        #expect(spans[0].level == .h2)
        #expect(spans[1].level == .h3)
        #expect(spans[2].level == .h3)
    }

    @Test func headingDetectionCoversSpecialSectionsAndQuestions() async throws {
        let content = """
OPINION OF ADVOCATE GENERAL

Legal context

Questions 1 to 3

The questions referred for a preliminary ruling

Procedure
"""
        let spans = DHConfig.defaultHeadings(content as NSString)
        let ns = content as NSString

        // Map text -> level for easier assertions
        var map: [String: DHHeadingSpan.Level] = [:]
        for span in spans {
            map[ns.substring(with: span.range)] = span.level
        }

        #expect(map["OPINION OF ADVOCATE GENERAL"] == .h2)
        #expect(map["Legal context"] == .h3)
        #expect(map["Questions 1 to 3"] == .h3)
        #expect(map["The questions referred for a preliminary ruling"] == .h3)
        #expect(map["Procedure"] == .h3)
    }

    @Test func headingDetectionHandlesSpelledOutQuestionRanges() async throws {
        let content = """
The first question

The first and second questions
"""
        let spans = DHConfig.defaultHeadings(content as NSString)
        let ns = content as NSString

        var map: [String: DHHeadingSpan.Level] = [:]
        for span in spans {
            map[ns.substring(with: span.range)] = span.level
        }

        #expect(map["The first question"] == .h3)
        #expect(map["The first and second questions"] == .h3)
    }

    @Test func headingDetectionMatchesNewRegexAdditions() async throws {
        let content = """
[Text rectified …]

ORDER OF THE COURT (Sixth Chamber)

On those grounds, the Court (Grand Chamber) hereby rules:

The first part of the second question
"""
        let spans = DHConfig.defaultHeadings(content as NSString)
        let ns = content as NSString

        var map: [String: DHHeadingSpan.Level] = [:]
        for span in spans {
            map[ns.substring(with: span.range)] = span.level
        }

        #expect(map["[Text rectified …]"] == .h2)
        #expect(map["ORDER OF THE COURT (Sixth Chamber)"] == .h2)
        #expect(map["On those grounds, the Court (Grand Chamber) hereby rules:"] == .h2)
        #expect(map["The first part of the second question"] == .h3)
    }

}
