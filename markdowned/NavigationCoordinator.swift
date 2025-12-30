//
//  NavigationCoordinator.swift
//  markdowned
//
//  Centralized navigation state management for programmatic navigation,
//  deep links, and state restoration.
//

import SwiftUI

@MainActor
@Observable
final class NavigationCoordinator {
    static let shared = NavigationCoordinator()

    // MARK: - Navigation State

    var selectedSection: NavigationSection = .documents
    var selectedDocumentId: UUID? = nil
    var sidebarVisibility: NavigationSplitViewVisibility = .automatic

    /// Navigation path for document detail navigation (used by NavigationStack in detail column)
    var documentNavigationPath = NavigationPath()

    // MARK: - Persistence Keys

    private let sectionKey = "nav.selectedSection"
    private let documentKey = "nav.selectedDocumentId"

    private init() {
        restoreState()
    }

    // MARK: - Navigation Actions

    func navigate(to section: NavigationSection) {
        selectedSection = section
        saveState()
    }

    func navigate(to documentId: UUID) {
        selectedSection = .documents
        selectedDocumentId = documentId
        // Push document onto navigation path for NavigationStack navigation
        documentNavigationPath.append(documentId)
        saveState()
    }

    /// Navigate to document within current section (used by document list)
    func openDocument(_ documentId: UUID) {
        selectedDocumentId = documentId
        documentNavigationPath.append(documentId)
    }

    /// Clear document navigation (pop back to list)
    func closeDocument() {
        if !documentNavigationPath.isEmpty {
            documentNavigationPath.removeLast()
        }
        selectedDocumentId = nil
    }

    /// Handle external deep links (markdowned:// scheme)
    /// - Returns: true if the URL was handled
    func handleDeepLink(_ url: URL) -> Bool {
        guard url.scheme == "markdowned" else { return false }

        switch url.host {
        case "document":
            if let uuid = UUID(uuidString: url.lastPathComponent) {
                navigate(to: uuid)
                return true
            }
        case "section":
            if let section = NavigationSection(rawValue: url.lastPathComponent) {
                navigate(to: section)
                return true
            }
        default:
            break
        }
        return false
    }

    /// Handle internal links from UITextView (dh:// scheme)
    /// - Returns: true if the URL was handled
    func handleInternalLink(_ url: URL) -> Bool {
        guard url.scheme == "dh" else { return false }

        switch url.host {
        case "article":
            // Parse article number from dh://article/N
            if let articleNumber = Int(url.lastPathComponent) {
                // TODO: Search DocumentsManager for document containing "Article N"
                // For now, just log
                Logger.debug("Internal link to Article \(articleNumber) - navigation not yet implemented")
            }
        default:
            break
        }
        return false
    }

    // MARK: - State Persistence

    func saveState() {
        UserDefaults.standard.set(selectedSection.rawValue, forKey: sectionKey)
        UserDefaults.standard.set(selectedDocumentId?.uuidString, forKey: documentKey)
    }

    func restoreState() {
        if let raw = UserDefaults.standard.string(forKey: sectionKey),
           let section = NavigationSection(rawValue: raw) {
            selectedSection = section
        }
        if let uuidString = UserDefaults.standard.string(forKey: documentKey),
           let uuid = UUID(uuidString: uuidString) {
            selectedDocumentId = uuid
        }
    }
}

// MARK: - SidebarItem Mapping

extension NavigationSection {
    var sidebarItem: SidebarItem {
        switch self {
        case .documents: return .allDocuments
        case .highlights: return .highlights
        case .compositions: return .assembly
        case .settings: return .settings
        }
    }
}

extension SidebarItem {
    var navigationSection: NavigationSection? {
        switch self {
        case .allDocuments: return .documents
        case .highlights: return .highlights
        case .assembly: return .compositions
        case .settings: return .settings
        case .category: return nil // Categories stay in documents section
        }
    }
}
