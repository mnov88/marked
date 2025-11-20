//
//  PlatformTypes.swift
//  markdowned
//
//  Platform abstraction layer for cross-platform compatibility
//

import SwiftUI

#if canImport(UIKit)
import UIKit
public typealias PlatformColor = UIColor
public typealias PlatformFont = UIFont
public typealias PlatformImage = UIImage
public typealias PlatformEdgeInsets = UIEdgeInsets
public typealias PlatformViewController = UIViewController
#elseif canImport(AppKit)
import AppKit
public typealias PlatformColor = NSColor
public typealias PlatformFont = NSFont
public typealias PlatformImage = NSImage
public typealias PlatformEdgeInsets = NSEdgeInsets
public typealias PlatformViewController = NSViewController
#endif

// MARK: - Color Extensions

extension PlatformColor {
    /// Initialize from hex string (e.g., "#FFEB3B")
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        #if canImport(UIKit)
        self.init(red: r, green: g, blue: b, alpha: 1.0)
        #elseif canImport(AppKit)
        self.init(red: r, green: g, blue: b, alpha: 1.0)
        #endif
    }

    /// Convert to hex string (e.g., "#FFEB3B")
    var hexString: String {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        #elseif canImport(AppKit)
        guard let rgbColor = usingColorSpace(.deviceRGB) else {
            return "#000000"
        }
        let r = rgbColor.redComponent
        let g = rgbColor.greenComponent
        let b = rgbColor.blueComponent
        #endif

        let rgb = (Int(r * 255) << 16) | (Int(g * 255) << 8) | Int(b * 255)
        return String(format: "#%06X", rgb)
    }

    /// System background color (adapts to light/dark mode)
    static var platformSystemBackground: PlatformColor {
        #if canImport(UIKit)
        return .systemBackground
        #elseif canImport(AppKit)
        return .windowBackgroundColor
        #endif
    }

    /// System label color (adapts to light/dark mode)
    static var platformLabel: PlatformColor {
        #if canImport(UIKit)
        return .label
        #elseif canImport(AppKit)
        return .labelColor
        #endif
    }

    /// System link color
    static var platformLink: PlatformColor {
        #if canImport(UIKit)
        return .link
        #elseif canImport(AppKit)
        return .linkColor
        #endif
    }
}

// MARK: - Edge Insets Extensions

extension PlatformEdgeInsets {
    static func all(_ value: CGFloat) -> PlatformEdgeInsets {
        #if canImport(UIKit)
        return UIEdgeInsets(top: value, left: value, bottom: value, right: value)
        #elseif canImport(AppKit)
        return NSEdgeInsets(top: value, left: value, bottom: value, right: value)
        #endif
    }
}

// MARK: - SwiftUI Bridge

extension Color {
    init(platformColor: PlatformColor) {
        #if canImport(UIKit)
        self.init(uiColor: platformColor)
        #elseif canImport(AppKit)
        self.init(nsColor: platformColor)
        #endif
    }
}
