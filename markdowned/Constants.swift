//
//  Constants.swift
//  markdowned
//
//  Centralized constants to avoid magic numbers and strings
//

import Foundation

// MARK: - UI Constants

enum UIConstants {
    /// Text view configuration
    enum TextView {
        static let lineFragmentPadding: CGFloat = 8
        static let defaultLineHeightMultiple: CGFloat = 1.2
        static let paragraphSpacing: CGFloat = 4
    }

    /// Page layout configuration
    enum PageLayout {
        static let maxContentWidth: CGFloat = 700
        static let narrowMaxWidth: CGFloat = 760
        static let mediumMaxWidth: CGFloat = 700
        static let wideMaxWidth: CGFloat = 600

        static let narrowInset: CGFloat = 16
        static let mediumInset: CGFloat = 24
        static let wideInset: CGFloat = 40
    }

    /// Content insets
    enum Insets {
        static let top: CGFloat = 24
        static let bottom: CGFloat = 24
        static let defaultHorizontal: CGFloat = 16
    }

    /// Highlight colors indicator size
    enum Highlight {
        static let indicatorSize: CGFloat = 12
        static let indicatorCornerRadius: CGFloat = 3
    }

    /// Loading overlay
    enum Overlay {
        static let backgroundOpacity: Double = 0.3
        static let cornerRadius: CGFloat = 10
    }

    /// Font sizes
    enum Font {
        static let minSize: CGFloat = 12
        static let maxSize: CGFloat = 28
        static let defaultSize: CGFloat = 17
        static let highContrastSize: CGFloat = 18
        static let citationSize: CGFloat = 12
    }
}

// MARK: - Pagination Constants

enum PaginationConstants {
    static let defaultPageSize: Int = 20
    static let searchResultsLimit: Int = 20
}

// MARK: - Indentation Constants

enum IndentationConstants {
    static let baseIndent: CGFloat = 20
}

// MARK: - HTTP Constants

enum HTTPConstants {
    /// Default User-Agent for web requests
    static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"

    /// Request timeout in seconds
    static let timeout: TimeInterval = 30
}

// MARK: - Storage Keys

enum StorageKeys {
    /// UserDefaults keys
    enum UserDefaults {
        static let selectedThemeType = "selectedThemeType"
        static let customTheme = "customTheme"
        static let usePageLayout = "usePageLayout"
        static let highlightsMigrated = "highlights_migrated_to_grdb"
        static let documentHighlights = "documentHighlights"
    }

    /// Database file name
    static let databaseFileName = "marked.sqlite"
}

// MARK: - Snippet Constants

enum SnippetConstants {
    static let defaultMaxLength: Int = 200
    static let defaultContextLength: Int = 40
}

// MARK: - Logger (replaces scattered print statements)

import os.log

/// Centralized logging utility - replaces scattered print() statements
/// Uses os.log for proper system integration in production
enum Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.marked.app"

    private static let generalLog = OSLog(subsystem: subsystem, category: "general")
    private static let databaseLog = OSLog(subsystem: subsystem, category: "database")
    private static let networkLog = OSLog(subsystem: subsystem, category: "network")

    /// Log debug messages (only in DEBUG builds)
    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        os_log("%{public}@ [%{public}@:%{public}d]", log: generalLog, type: .debug, message, fileName, line)
        #endif
    }

    /// Log info messages
    static func info(_ message: String) {
        os_log("%{public}@", log: generalLog, type: .info, message)
    }

    /// Log error messages
    static func error(_ message: String, error: Error? = nil) {
        if let error = error {
            os_log("%{public}@: %{public}@", log: generalLog, type: .error, message, error.localizedDescription)
        } else {
            os_log("%{public}@", log: generalLog, type: .error, message)
        }
    }

    /// Log SQL queries (debug only)
    static func sql(_ query: String) {
        #if DEBUG
        os_log("SQL: %{public}@", log: databaseLog, type: .debug, query)
        #endif
    }

    /// Log network operations
    static func network(_ message: String) {
        os_log("%{public}@", log: networkLog, type: .info, message)
    }
}
