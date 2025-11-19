import Foundation
import SwiftData

/// Core document model representing a markdown document
/// Maps 1:1 with web app's UploadedFile interface
@Model
final class Document {
    @Attribute(.unique) var id: String
    var name: String
    var content: String
    var size: Int
    var source: String // "upload", "url", "paste", "icloud"
    var sourceUrl: String?
    var createdAt: Date
    var modifiedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Highlight.document)
    var highlights: [Highlight]?

    init(
        id: String = UUID().uuidString,
        name: String,
        content: String,
        size: Int,
        source: String,
        sourceUrl: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.content = content
        self.size = size
        self.source = source
        self.sourceUrl = sourceUrl
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Computed Properties
extension Document {
    /// Human-readable file size
    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    /// Check if document was imported from URL
    var isFromURL: Bool {
        source == "url"
    }

    /// Check if document was uploaded from files
    var isFromUpload: Bool {
        source == "upload"
    }

    /// Check if document was pasted
    var isFromPaste: Bool {
        source == "paste"
    }

    /// Get source icon name
    var sourceIcon: String {
        switch source {
        case "url": return "link"
        case "upload": return "doc"
        case "paste": return "doc.on.clipboard"
        case "icloud": return "icloud"
        default: return "doc.text"
        }
    }
}

// MARK: - Validation
extension Document {
    /// Maximum file size (10MB)
    static let maxSize = 10_000_000

    /// Check if document size is valid
    var isValidSize: Bool {
        size <= Self.maxSize
    }

    /// Validate document
    func validate() throws {
        guard !name.isEmpty else {
            throw DocumentError.invalidName
        }

        guard !content.isEmpty else {
            throw DocumentError.emptyContent
        }

        guard isValidSize else {
            throw DocumentError.fileTooLarge
        }
    }
}

// MARK: - Document Errors
enum DocumentError: LocalizedError {
    case invalidName
    case emptyContent
    case fileTooLarge
    case accessDenied
    case invalidFormat
    case importFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Document name cannot be empty"
        case .emptyContent:
            return "Document content cannot be empty"
        case .fileTooLarge:
            return "File size exceeds 10MB limit"
        case .accessDenied:
            return "Access to file denied"
        case .invalidFormat:
            return "Invalid markdown format"
        case .importFailed(let reason):
            return "Import failed: \(reason)"
        }
    }
}
