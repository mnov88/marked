import Foundation
import SwiftUI

/// Theme configuration for markdown rendering
/// Maps 1:1 with web app's Theme interface (lib/themes.ts)
struct Theme: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let fontFamily: String
    let fontSize: Double
    let lineHeight: Double
    let textColor: String // Hex color
    let backgroundColor: String
    let linkColor: String
    let headingScale: Double
    let codeFontFamily: String?
    let codeBackgroundColor: String?

    init(
        id: String,
        name: String,
        fontFamily: String,
        fontSize: Double,
        lineHeight: Double,
        textColor: String,
        backgroundColor: String,
        linkColor: String,
        headingScale: Double,
        codeFontFamily: String? = nil,
        codeBackgroundColor: String? = nil
    ) {
        self.id = id
        self.name = name
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.linkColor = linkColor
        self.headingScale = headingScale
        self.codeFontFamily = codeFontFamily ?? "Courier"
        self.codeBackgroundColor = codeBackgroundColor ?? "#F3F4F6"
    }
}

// MARK: - Color Conversions
extension Theme {
    var textUIColor: UIColor {
        UIColor(hex: textColor) ?? .label
    }

    var backgroundUIColor: UIColor {
        UIColor(hex: backgroundColor) ?? .systemBackground
    }

    var linkUIColor: UIColor {
        UIColor(hex: linkColor) ?? .systemBlue
    }

    var codeBackgroundUIColor: UIColor {
        UIColor(hex: codeBackgroundColor ?? "#F3F4F6") ?? .systemGray6
    }

    var textSwiftUIColor: Color {
        Color(uiColor: textUIColor)
    }

    var backgroundSwiftUIColor: Color {
        Color(uiColor: backgroundUIColor)
    }

    var linkSwiftUIColor: Color {
        Color(uiColor: linkUIColor)
    }
}

// MARK: - Font Helpers
extension Theme {
    /// Get UIFont for body text
    func bodyFont(size: CGFloat? = nil) -> UIFont {
        let fontSize = size ?? self.fontSize
        return UIFont(name: fontFamily, size: fontSize) ?? .systemFont(ofSize: fontSize)
    }

    /// Get UIFont for headings
    func headingFont(level: Int, size: CGFloat? = nil) -> UIFont {
        let baseSize = size ?? self.fontSize
        let scale = headingScale / Double(level)
        let fontSize = baseSize * scale
        return UIFont(name: fontFamily, size: fontSize) ?? .systemFont(ofSize: fontSize, weight: .bold)
    }

    /// Get UIFont for code
    func codeFont(size: CGFloat? = nil) -> UIFont {
        let fontSize = (size ?? self.fontSize) * 0.9
        return UIFont(name: codeFontFamily ?? "Courier", size: fontSize)
            ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }
}

// MARK: - Preset Themes
extension Theme {
    /// Professional theme - Georgia serif, traditional palette
    static let professional = Theme(
        id: "professional",
        name: "Professional",
        fontFamily: "Georgia",
        fontSize: 16,
        lineHeight: 1.6,
        textColor: "#1f2937",
        backgroundColor: "#ffffff",
        linkColor: "#2563eb",
        headingScale: 1.5
    )

    /// Modern theme - System UI fonts, sky blue accent
    static let modern = Theme(
        id: "modern",
        name: "Modern",
        fontFamily: ".AppleSystemUIFont", // System font
        fontSize: 16,
        lineHeight: 1.5,
        textColor: "#111827",
        backgroundColor: "#ffffff",
        linkColor: "#0ea5e9",
        headingScale: 1.4
    )

    /// Minimal theme - Large base size, neutral grays
    static let minimal = Theme(
        id: "minimal",
        name: "Minimal",
        fontFamily: ".AppleSystemUIFont",
        fontSize: 18,
        lineHeight: 1.75,
        textColor: "#374151",
        backgroundColor: "#ffffff",
        linkColor: "#6b7280",
        headingScale: 1.3
    )

    /// Academic theme - Times New Roman, double line-height
    static let academic = Theme(
        id: "academic",
        name: "Academic",
        fontFamily: "Times New Roman",
        fontSize: 14,
        lineHeight: 2.0,
        textColor: "#000000",
        backgroundColor: "#ffffff",
        linkColor: "#1e40af",
        headingScale: 1.6
    )

    /// Creative theme - Purple accent, large headings
    static let creative = Theme(
        id: "creative",
        name: "Creative",
        fontFamily: ".AppleSystemUIFont",
        fontSize: 16,
        lineHeight: 1.6,
        textColor: "#1f2937",
        backgroundColor: "#faf5ff",
        linkColor: "#9333ea",
        headingScale: 1.8
    )

    /// All preset themes
    static let allPresets: [Theme] = [
        .professional,
        .modern,
        .minimal,
        .academic,
        .creative
    ]

    /// Default theme
    static let `default` = professional
}

// MARK: - Theme Storage
extension Theme {
    /// UserDefaults key for custom theme
    static let customThemeKey = "customTheme"

    /// UserDefaults key for selected theme ID
    static let selectedThemeIdKey = "selectedThemeId"

    /// Save custom theme to UserDefaults
    func saveAsCustom() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        UserDefaults.standard.set(data, forKey: Self.customThemeKey)
    }

    /// Load custom theme from UserDefaults
    static func loadCustom() -> Theme? {
        guard let data = UserDefaults.standard.data(forKey: customThemeKey) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(Theme.self, from: data)
    }

    /// Get theme by ID (from presets or custom)
    static func theme(withId id: String) -> Theme? {
        if id == "custom" {
            return loadCustom()
        }
        return allPresets.first { $0.id == id }
    }
}

// MARK: - CSS Generation (for HTML export)
extension Theme {
    /// Generate CSS string for HTML export
    func generateCSS() -> String {
        return """
        body {
            font-family: \(fontFamily);
            font-size: \(fontSize)px;
            line-height: \(lineHeight);
            color: \(textColor);
            background-color: \(backgroundColor);
            max-width: 800px;
            margin: 0 auto;
            padding: 2rem;
        }

        a {
            color: \(linkColor);
            text-decoration: none;
        }

        a:hover {
            text-decoration: underline;
        }

        h1 { font-size: \(fontSize * headingScale)px; margin: 1.5em 0 0.5em; }
        h2 { font-size: \(fontSize * headingScale * 0.85)px; margin: 1.3em 0 0.5em; }
        h3 { font-size: \(fontSize * headingScale * 0.7)px; margin: 1.2em 0 0.5em; }
        h4 { font-size: \(fontSize * headingScale * 0.6)px; margin: 1.1em 0 0.5em; }
        h5 { font-size: \(fontSize * headingScale * 0.5)px; margin: 1em 0 0.5em; }
        h6 { font-size: \(fontSize * headingScale * 0.4)px; margin: 1em 0 0.5em; }

        p {
            margin: 0.8em 0;
        }

        code {
            background-color: \(codeBackgroundColor ?? "#F3F4F6");
            padding: 0.2em 0.4em;
            border-radius: 3px;
            font-family: \(codeFontFamily ?? "Courier"), monospace;
            font-size: \(fontSize * 0.9)px;
        }

        pre {
            background-color: \(codeBackgroundColor ?? "#F3F4F6");
            padding: 1rem;
            border-radius: 5px;
            overflow-x: auto;
        }

        pre code {
            background-color: transparent;
            padding: 0;
        }

        blockquote {
            border-left: 4px solid #e5e7eb;
            padding-left: 1rem;
            margin-left: 0;
            color: #6b7280;
        }

        ul, ol {
            padding-left: 2em;
        }

        li {
            margin: 0.3em 0;
        }

        /* Highlight colors */
        mark.highlight-sun { background-color: rgba(251, 191, 36, 0.32); }
        mark.highlight-mint { background-color: rgba(16, 185, 129, 0.22); }
        mark.highlight-lavender { background-color: rgba(168, 85, 247, 0.20); }
        mark.highlight-coral { background-color: rgba(251, 113, 133, 0.26); }

        /* Print styles */
        @media print {
            body {
                max-width: 100%;
            }

            a {
                color: \(textColor);
            }

            h1, h2, h3, h4, h5, h6 {
                page-break-after: avoid;
            }

            p, blockquote, ul, ol {
                page-break-inside: avoid;
            }
        }
        """
    }
}
