//
//  Composition.swift
//  markdowned
//
//  In-memory model for compositions with resolved fragment data
//

import Foundation

/// Sort mode for composition fragments
enum CompositionSortMode: String, Codable, CaseIterable, Identifiable {
    case manual = "manual"
    case recent = "recent"
    case color = "color"
    case source = "source"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .recent: return "Recent"
        case .color: return "Color"
        case .source: return "Source"
        }
    }

    var icon: String {
        switch self {
        case .manual: return "hand.draw"
        case .recent: return "clock"
        case .color: return "paintpalette"
        case .source: return "doc.text"
        }
    }
}

/// A resolved fragment containing highlight data with document context
struct CompositionFragment: Identifiable, Hashable {
    let id: UUID
    let highlightId: UUID
    let documentId: UUID
    let documentTitle: String
    let textSnippet: String
    let range: NSRange
    let color: PlatformColor
    let sortOrder: Int
    let createdAt: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CompositionFragment, rhs: CompositionFragment) -> Bool {
        lhs.id == rhs.id
    }
}

/// In-memory composition model with resolved fragments
struct Composition: Identifiable, Hashable {
    let id: UUID
    var title: String
    var sortMode: CompositionSortMode
    var fragments: [CompositionFragment]
    let createdAt: Date
    var modifiedAt: Date

    /// Number of fragments in this composition
    var fragmentCount: Int { fragments.count }

    /// Check if composition has any fragments
    var isEmpty: Bool { fragments.isEmpty }

    /// Get fragments sorted according to current sort mode
    func sortedFragments() -> [CompositionFragment] {
        switch sortMode {
        case .manual:
            return fragments.sorted { $0.sortOrder < $1.sortOrder }
        case .recent:
            return fragments.sorted { $0.createdAt > $1.createdAt }
        case .color:
            return fragments.sorted { $0.color.hexString < $1.color.hexString }
        case .source:
            return fragments.sorted {
                if $0.documentTitle != $1.documentTitle {
                    return $0.documentTitle < $1.documentTitle
                }
                return $0.sortOrder < $1.sortOrder
            }
        }
    }

    /// Get a preview string of the composition (first few fragments)
    func previewText(maxFragments: Int = 2, maxLength: Int = 100) -> String {
        let sorted = sortedFragments()
        let preview = sorted.prefix(maxFragments)
            .map { $0.textSnippet.prefix(maxLength) }
            .joined(separator: " • ")
        return String(preview.prefix(maxLength * maxFragments))
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Composition, rhs: Composition) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Conversion from Database Models

extension Composition {
    /// Create a Composition from a DBComposition (fragments loaded separately)
    init(from dbComposition: DBComposition, fragments: [CompositionFragment] = []) throws {
        guard let uuid = UUID(uuidString: dbComposition.id) else {
            throw DatabaseError(message: "Invalid UUID string: \(dbComposition.id)")
        }

        self.id = uuid
        self.title = dbComposition.title
        self.sortMode = CompositionSortMode(rawValue: dbComposition.sortMode) ?? .manual
        self.fragments = fragments
        self.createdAt = dbComposition.createdAt
        self.modifiedAt = dbComposition.modifiedAt
    }
}
