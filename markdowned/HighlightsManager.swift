//
//  HighlightsManager.swift
//  markdowned
//
//  Global highlights manager with persistence
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class HighlightsManager: ObservableObject {
    static let shared = HighlightsManager()

    private let userDefaults = UserDefaults.standard
    private let highlightsKey = "documentHighlights"

    // Dictionary mapping document ID to its highlights
    @Published private(set) var highlightsByDocument: [UUID: [DHTextHighlight]] = [:]

    // Debouncing support to reduce UserDefaults writes
    private var saveTask: Task<Void, Never>?
    private let saveDebounceDuration: Duration = .milliseconds(500)

    private init() {
        loadHighlights()
    }

    // MARK: - Persistence

    private func loadHighlights() {
        guard let data = userDefaults.data(forKey: highlightsKey) else { return }

        do {
            let decoded = try JSONDecoder().decode([String: [DHTextHighlight]].self, from: data)
            // Convert String keys back to UUID
            highlightsByDocument = decoded.reduce(into: [:]) { result, pair in
                if let uuid = UUID(uuidString: pair.key) {
                    result[uuid] = pair.value
                }
            }
        } catch {
            print("Failed to load highlights: \(error)")
        }
    }

    private func saveHighlights() {
        // Cancel any pending save task
        saveTask?.cancel()

        // Schedule new save with debounce
        saveTask = Task { @MainActor in
            do {
                try await Task.sleep(for: saveDebounceDuration)

                // Only save if not cancelled
                guard !Task.isCancelled else { return }

                // Convert UUID keys to String for JSON encoding
                let stringKeyedDict = highlightsByDocument.reduce(into: [:]) { result, pair in
                    result[pair.key.uuidString] = pair.value
                }
                let encoded = try JSONEncoder().encode(stringKeyedDict)
                userDefaults.set(encoded, forKey: highlightsKey)
            } catch {
                // Task was cancelled or encoding failed
                if !(error is CancellationError) {
                    print("Failed to save highlights: \(error)")
                }
            }
        }
    }

    /// Force immediate save (e.g., on app termination)
    func saveImmediately() {
        saveTask?.cancel()
        do {
            let stringKeyedDict = highlightsByDocument.reduce(into: [:]) { result, pair in
                result[pair.key.uuidString] = pair.value
            }
            let encoded = try JSONEncoder().encode(stringKeyedDict)
            userDefaults.set(encoded, forKey: highlightsKey)
        } catch {
            print("Failed to save highlights immediately: \(error)")
        }
    }

    // MARK: - Public API

    func highlights(for documentId: UUID) -> [DHTextHighlight] {
        highlightsByDocument[documentId] ?? []
    }

    func addHighlight(_ highlight: DHTextHighlight, to documentId: UUID) {
        var highlights = highlightsByDocument[documentId] ?? []
        highlights.append(highlight)
        highlightsByDocument[documentId] = highlights
        saveHighlights()
    }

    func removeHighlight(id: UUID, from documentId: UUID) {
        guard var highlights = highlightsByDocument[documentId] else { return }
        highlights.removeAll { $0.id == id }
        highlightsByDocument[documentId] = highlights
        saveHighlights()
    }

    func removeHighlights(intersecting range: NSRange, from documentId: UUID) {
        guard var highlights = highlightsByDocument[documentId] else { return }
        highlights.removeAll { NSIntersectionRange($0.range, range).length > 0 }
        highlightsByDocument[documentId] = highlights
        saveHighlights()
    }

    func setHighlights(_ highlights: [DHTextHighlight], for documentId: UUID) {
        highlightsByDocument[documentId] = highlights
        saveHighlights()
    }

    // Get all highlights across all documents with document info
    func allHighlights() -> [(documentId: UUID, highlight: DHTextHighlight)] {
        highlightsByDocument.flatMap { documentId, highlights in
            highlights.map { (documentId: documentId, highlight: $0) }
        }
    }

    func clearAllHighlights() {
        highlightsByDocument.removeAll()
        saveHighlights()
    }

    /// Clean up highlights for documents that no longer exist
    func cleanupOrphanedHighlights(validDocumentIds: Set<UUID>) {
        let orphanedIds = Set(highlightsByDocument.keys).subtracting(validDocumentIds)
        guard !orphanedIds.isEmpty else { return }

        for orphanedId in orphanedIds {
            highlightsByDocument.removeValue(forKey: orphanedId)
        }
        saveHighlights()
    }

    deinit {
        // Ensure any pending save is executed before deallocation
        saveTask?.cancel()
    }
}
