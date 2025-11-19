import SwiftUI
import UIKit
import Combine


// MARK: - ViewModel

@MainActor
final class DHViewModel: ObservableObject {
    @Published var highlights: [DHTextHighlight] = []

    func add(range: NSRange, color: UIColor, in text: NSAttributedString) {
        guard range.clamped(toStringLength: text.length) != nil else { return }
        highlights.append(DHTextHighlight(range: range, color: color))
    }

    func remove(intersecting range: NSRange) {
        highlights.removeAll { NSIntersectionRange($0.range, range).length > 0 }
    }

    func remove(id: UUID) {
        highlights.removeAll { $0.id == id }
    }

    func highlight(id: UUID) -> DHTextHighlight? {
        highlights.first { $0.id == id }
    }
}