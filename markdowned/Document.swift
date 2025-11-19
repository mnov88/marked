//
//  Document.swift
//  markdowned
//
//  Created by Milos Novovic on 16/11/2025.
//

import Foundation
import UIKit

/// Document model supporting both static content and URL-loaded content
struct Document: Identifiable, Hashable {
    enum Content: Hashable {
        case plain(String)
        case attributed(NSAttributedString)
    }
    
    let id: UUID
    let title: String
    let content: Content
    let sourceURL: URL?
    
    init(id: UUID = UUID(), title: String, content: Content, sourceURL: URL? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.sourceURL = sourceURL
    }
    
    // Convenience initializers
    static func plain(_ text: String, title: String, sourceURL: URL? = nil) -> Document {
        Document(title: title, content: .plain(text), sourceURL: sourceURL)
    }
    
    static func attributed(_ text: NSAttributedString, title: String, sourceURL: URL? = nil) -> Document {
        Document(title: title, content: .attributed(text), sourceURL: sourceURL)
    }
}

