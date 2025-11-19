import SwiftUI

/// Highlight color definitions matching web app's color palette
/// Maps to lib/highlights.ts HIGHLIGHT_COLORS
enum HighlightColor: String, CaseIterable, Codable, Hashable {
    case sun
    case mint
    case lavender
    case coral

    /// UIColor with exact RGBA values from web app
    var uiColor: UIColor {
        switch self {
        case .sun:
            // rgba(251, 191, 36, 0.32)
            return UIColor(red: 251/255, green: 191/255, blue: 36/255, alpha: 0.32)
        case .mint:
            // rgba(16, 185, 129, 0.22)
            return UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 0.22)
        case .lavender:
            // rgba(168, 85, 247, 0.20)
            return UIColor(red: 168/255, green: 85/255, blue: 247/255, alpha: 0.20)
        case .coral:
            // rgba(251, 113, 133, 0.26)
            return UIColor(red: 251/255, green: 113/255, blue: 133/255, alpha: 0.26)
        }
    }

    /// SwiftUI Color
    var color: Color {
        Color(uiColor: uiColor)
    }

    /// Solid color for UI elements (buttons, swatches)
    var solidColor: Color {
        switch self {
        case .sun:
            return Color(red: 251/255, green: 191/255, blue: 36/255)
        case .mint:
            return Color(red: 16/255, green: 185/255, blue: 129/255)
        case .lavender:
            return Color(red: 168/255, green: 85/255, blue: 247/255)
        case .coral:
            return Color(red: 251/255, green: 113/255, blue: 133/255)
        }
    }

    /// Display name
    var displayName: String {
        rawValue.capitalized
    }

    /// Icon for color (emoji or SF Symbol)
    var icon: String {
        switch self {
        case .sun: return "sun.max.fill"
        case .mint: return "leaf.fill"
        case .lavender: return "sparkles"
        case .coral: return "heart.fill"
        }
    }
}
