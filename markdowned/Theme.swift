//
//  Theme.swift
//  markdowned
//
//  Created by Milos Novovic on 17/11/2025.
//

import Foundation

struct Theme: Codable, Equatable {
    var fontName: String
    var fontSize: CGFloat
    var backgroundColorHex: String
    var textColorHex: String
    var lineHeightMultiple: CGFloat
    var usePageLayout: Bool
    var useSystemBackground: Bool
    var useSystemTextColor: Bool

    // Convert to DHStyle
    func toDHStyle() -> DHStyle {
        var style = DHStyle()

        // Set font
        if let font = PlatformFont(name: fontName, size: fontSize) {
            style.font = font
        } else {
            #if canImport(UIKit)
            style.font = .systemFont(ofSize: fontSize)
            #elseif canImport(AppKit)
            style.font = .systemFont(ofSize: fontSize)
            #endif
        }

        // Set colors (respect system color overrides)
        if useSystemBackground {
            style.backgroundColor = .systemBackground
        } else {
            style.backgroundColor = PlatformColor(hex: backgroundColorHex) ?? .systemBackground
        }

        if useSystemTextColor {
            style.textColor = .label
        } else {
            style.textColor = PlatformColor(hex: textColorHex) ?? .label
        }

        // Set line height
        style.lineHeightMultiple = lineHeightMultiple

        // Set content insets
        // Page layout constrains text container width, so we use standard insets
        style.contentInsets = PlatformEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)

        return style
    }
    
    // Preset themes
    static let system = Theme(
        fontName: "System",
        fontSize: 17,
        backgroundColorHex: "#FFFFFF",  // Fallback, not used
        textColorHex: "#000000",        // Fallback, not used
        lineHeightMultiple: 1.2,
        usePageLayout: false,
        useSystemBackground: true,
        useSystemTextColor: true
    )
    
    static let light = Theme(
        fontName: "System",
        fontSize: 17,
        backgroundColorHex: "#FFFFFF",
        textColorHex: "#000000",
        lineHeightMultiple: 1.2,
        usePageLayout: false,
        useSystemBackground: false,
        useSystemTextColor: false
    )
    
    static let dark = Theme(
        fontName: "System",
        fontSize: 17,
        backgroundColorHex: "#1C1C1E",
        textColorHex: "#FFFFFF",
        lineHeightMultiple: 1.2,
        usePageLayout: false,
        useSystemBackground: false,
        useSystemTextColor: false
    )
    
    static let sepia = Theme(
        fontName: "System",
        fontSize: 17,
        backgroundColorHex: "#F4ECD8",
        textColorHex: "#5B4636",
        lineHeightMultiple: 1.2,
        usePageLayout: false,
        useSystemBackground: false,
        useSystemTextColor: false
    )
    
    static let highContrast = Theme(
        fontName: "System",
        fontSize: 18,
        backgroundColorHex: "#000000",
        textColorHex: "#FFFF00",
        lineHeightMultiple: 1.2,
        usePageLayout: false,
        useSystemBackground: false,
        useSystemTextColor: false
    )
    
    static let allPresets: [(String, Theme)] = [
        ("System", .system),
        ("Light", .light),
        ("Dark", .dark),
        ("Sepia", .sepia),
        ("High Contrast", .highContrast)
    ]
}

