import Foundation
import SwiftData
import Observation

/// ViewModel for document reading and editing
/// Handles markdown rendering, highlights, and theme application
@MainActor
@Observable
class DocumentViewModel {
    private let document: Document
    private let highlightService: HighlightService
    private let exportService: ExportService

    // State
    var renderedContent: NSAttributedString?
    var highlights: [Highlight] = []
    var selectedTheme: Theme = .professional
    var isHighlightMode: Bool = false
    var selectedHighlightColor: HighlightColor = .sun
    var isLoading: Bool = false
    var error: Error?

    // Export state
    var isExporting: Bool = false
    var exportProgress: Double = 0.0

    init(
        document: Document,
        highlightService: HighlightService,
        theme: Theme = .professional
    ) {
        self.document = document
        self.highlightService = highlightService
        self.selectedTheme = theme
        self.exportService = ExportService(theme: theme)
    }

    // MARK: - Document Access

    var documentName: String {
        document.name
    }

    var documentContent: String {
        document.content
    }

    var documentSize: String {
        document.sizeFormatted
    }

    var createdAt: Date {
        document.createdAt
    }

    var sourceIcon: String {
        document.sourceIcon
    }

    // MARK: - Rendering

    /// Render markdown with current theme
    func renderContent() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load highlights
            highlights = try await highlightService.fetchHighlights(for: document)

            // Render markdown
            let renderer = MarkdownRenderer(theme: selectedTheme)
            renderedContent = renderer.render(document.content, highlights: highlights)
        } catch {
            handleError(error)
        }
    }

    /// Update theme and re-render
    func updateTheme(_ theme: Theme) async {
        selectedTheme = theme
        await renderContent()
    }

    // MARK: - Highlight Operations

    /// Create highlight at range
    func createHighlight(at range: NSRange, color: HighlightColor? = nil) async {
        let highlightColor = color ?? selectedHighlightColor

        do {
            let highlight = try await highlightService.createHighlight(
                in: document,
                color: highlightColor,
                range: range
            )

            highlights.append(highlight)
            await renderContent() // Re-render with new highlight
        } catch {
            handleError(error)
        }
    }

    /// Update highlight color
    func updateHighlightColor(_ highlight: Highlight, to color: HighlightColor) async {
        do {
            try await highlightService.updateColor(of: highlight, to: color)
            await renderContent()
        } catch {
            handleError(error)
        }
    }

    /// Delete highlight
    func deleteHighlight(_ highlight: Highlight) async {
        do {
            try await highlightService.deleteHighlight(highlight)
            highlights.removeAll { $0.id == highlight.id }
            await renderContent()
        } catch {
            handleError(error)
        }
    }

    /// Delete all highlights
    func deleteAllHighlights() async {
        do {
            try await highlightService.deleteAllHighlights(in: document)
            highlights.removeAll()
            await renderContent()
        } catch {
            handleError(error)
        }
    }

    /// Toggle highlight mode
    func toggleHighlightMode() {
        isHighlightMode.toggle()
    }

    /// Select highlight color
    func selectHighlightColor(_ color: HighlightColor) {
        selectedHighlightColor = color
    }

    // MARK: - Highlight Navigation

    /// Navigate to highlight
    func navigateToHighlight(_ highlight: Highlight) -> NSRange {
        return highlight.range
    }

    /// Find next highlight
    func findNextHighlight(after offset: Int) async -> Highlight? {
        do {
            return try await highlightService.findNextHighlight(in: document, after: offset)
        } catch {
            return nil
        }
    }

    /// Find previous highlight
    func findPreviousHighlight(before offset: Int) async -> Highlight? {
        do {
            return try await highlightService.findPreviousHighlight(in: document, before: offset)
        } catch {
            return nil
        }
    }

    // MARK: - Export Operations

    /// Export as HTML
    func exportHTML() async -> URL? {
        isExporting = true
        exportProgress = 0.5
        defer {
            isExporting = false
            exportProgress = 0.0
        }

        let html = exportService.exportHTML(document: document, highlights: highlights)
        exportProgress = 0.8

        let filename = document.name.replacingOccurrences(of: ".md", with: ".html")
        let url = exportService.saveHTMLToTemporaryFile(html: html, filename: filename)

        exportProgress = 1.0
        return url
    }

    /// Export as PDF
    func exportPDF(pageSize: PDFPageSize = .a4) async -> URL? {
        isExporting = true
        exportProgress = 0.3
        defer {
            isExporting = false
            exportProgress = 0.0
        }

        guard let pdfData = exportService.exportPDF(
            document: document,
            highlights: highlights,
            pageSize: pageSize
        ) else {
            handleError(ExportError.pdfGenerationFailed)
            return nil
        }

        exportProgress = 0.8

        let filename = document.name.replacingOccurrences(of: ".md", with: ".pdf")
        let url = exportService.saveToTemporaryFile(data: pdfData, filename: filename)

        exportProgress = 1.0
        return url
    }

    // MARK: - Statistics

    /// Get highlight statistics
    func getHighlightStatistics() -> HighlightStatistics {
        let grouped = Dictionary(grouping: highlights, by: { $0.highlightColor })
        let counts = grouped.mapValues { $0.count }

        return HighlightStatistics(
            totalHighlights: highlights.count,
            colorCounts: counts
        )
    }

    /// Get reading statistics
    func getReadingStatistics() -> ReadingStatistics {
        let wordCount = document.content.wordCount
        let readingTime = document.content.estimatedReadingTime

        return ReadingStatistics(
            wordCount: wordCount,
            estimatedReadingTime: readingTime,
            characterCount: document.content.count
        )
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        self.error = error
        print("Error: \(error.localizedDescription)")
    }
}

// MARK: - Supporting Types

struct HighlightStatistics {
    let totalHighlights: Int
    let colorCounts: [HighlightColor?: Int]
}

struct ReadingStatistics {
    let wordCount: Int
    let estimatedReadingTime: Int
    let characterCount: Int

    var formattedReadingTime: String {
        if estimatedReadingTime == 1 {
            return "1 minute"
        } else {
            return "\(estimatedReadingTime) minutes"
        }
    }
}

enum ExportError: LocalizedError {
    case pdfGenerationFailed
    case htmlGenerationFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .pdfGenerationFailed:
            return "Failed to generate PDF"
        case .htmlGenerationFailed:
            return "Failed to generate HTML"
        case .saveFailed:
            return "Failed to save export"
        }
    }
}
