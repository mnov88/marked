//
//  DHViewModel.swift
//  markdowned
//
//  Created by Milos Novovic on 10/11/2025.
//


import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import Combine


// MARK: - ViewModel

@MainActor
final class DHViewModel: ObservableObject {
    private let documentId: UUID
    private let highlightsManager = HighlightsManager.shared

    @Published var highlights: [DHTextHighlight] = []

    init(documentId: UUID) {
        self.documentId = documentId
        self.highlights = highlightsManager.highlights(for: documentId)

        // Observe changes from the global manager
        highlightsManager.$highlightsByDocument
            .map { $0[documentId] ?? [] }
            .assign(to: &$highlights)
    }

    func add(range: NSRange, color: PlatformColor, in text: NSAttributedString) {
        guard range.clamped(toStringLength: text.length) != nil else { return }
        let highlight = DHTextHighlight(range: range, color: color)
        highlightsManager.addHighlight(highlight, to: documentId)
    }

    func remove(intersecting range: NSRange) {
        highlightsManager.removeHighlights(intersecting: range, from: documentId)
    }

    func remove(id: UUID) {
        highlightsManager.removeHighlight(id: id, from: documentId)
    }

    func highlight(id: UUID) -> DHTextHighlight? {
        highlights.first { $0.id == id }
    }
}