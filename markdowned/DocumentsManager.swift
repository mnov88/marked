//
//  DocumentsManager.swift
//  markdowned
//
//  Global documents manager
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class DocumentsManager: ObservableObject {
    static let shared = DocumentsManager()

    @Published var documents: [Document] = []

    private init() {
        // Initialize with mock documents
        let s1 = LoremGen.plain(paragraphs: 30)
        let s2 = dsaText
        let attr = NSMutableAttributedString(string: "Article 4\n\n1. Mixed content for demo.")
        documents = [
            Document.plain(s1, title: "Regulation — Part I"),
            Document.plain(s2, title: "Regulation — Part II"),
            Document.attributed(attr, title: "Regulation — Part III (Attributed)")
        ]
    }

    func addDocument(_ document: Document) {
        documents.append(document)
    }

    func document(withId id: UUID) -> Document? {
        documents.first { $0.id == id }
    }
}
