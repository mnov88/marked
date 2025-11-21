//
//  CrossPlatform.swift
//  markdowned
//
//  Cross-platform type aliases and extensions for UIKit/AppKit compatibility
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Type Aliases

#if canImport(UIKit)
public typealias PlatformColor = UIColor
public typealias PlatformFont = UIFont
public typealias PlatformEdgeInsets = UIEdgeInsets
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
public typealias PlatformColor = NSColor
public typealias PlatformFont = NSFont
public typealias PlatformEdgeInsets = NSEdgeInsets
public typealias PlatformImage = NSImage
#endif

// MARK: - PlatformColor Extensions

extension PlatformColor {

    /// Initialize color from hex string
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let rgb = UInt32(s, radix: 16) else { return nil }

        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0

        #if canImport(UIKit)
        self.init(red: r, green: g, blue: b, alpha: 1.0)
        #elseif canImport(AppKit)
        self.init(red: r, green: g, blue: b, alpha: 1.0)
        #endif
    }

    /// Convert color to hex string
    func toHex() -> String {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        #elseif canImport(AppKit)
        // Convert to RGB color space if needed
        let rgbColor = usingColorSpace(.deviceRGB) ?? self
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif

        let rgb = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255)
        return String(format: "#%06X", rgb)
    }

    /// Get RGBA components
    var rgba: (CGFloat, CGFloat, CGFloat, CGFloat) {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
        #elseif canImport(AppKit)
        let rgbColor = usingColorSpace(.deviceRGB) ?? self
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
        #endif
    }

    /// Get hex string representation
    var hexString: String {
        toHex()
    }

    // MARK: - System Colors (cross-platform)

    #if canImport(AppKit)
    static var systemBackground: NSColor {
        .controlBackgroundColor
    }

    static var secondarySystemBackground: NSColor {
        .controlColor
    }

    static var label: NSColor {
        .labelColor
    }

    static var secondaryLabel: NSColor {
        .secondaryLabelColor
    }

    static var systemGray: NSColor {
        .systemGray
    }

    static var systemGray2: NSColor {
        .systemGray.blended(withFraction: 0.2, of: .white) ?? .systemGray
    }

    static var systemYellow: NSColor {
        .systemYellow
    }

    static var systemBlue: NSColor {
        .systemBlue
    }
    #endif
}

// MARK: - Color to SwiftUI Color Bridge

extension Color {
    /// Initialize from PlatformColor
    init(platformColor: PlatformColor) {
        #if canImport(UIKit)
        self.init(uiColor: platformColor)
        #elseif canImport(AppKit)
        self.init(nsColor: platformColor)
        #endif
    }

    /// Convert SwiftUI Color to PlatformColor
    var platformColor: PlatformColor {
        #if canImport(UIKit)
        return UIColor(self)
        #elseif canImport(AppKit)
        return NSColor(self)
        #endif
    }
}

// MARK: - PlatformFont Extensions

extension PlatformFont {
    #if canImport(AppKit)
    /// Preferred font for text style (AppKit version)
    static func preferredFont(forTextStyle style: NSFont.TextStyle) -> NSFont {
        return .preferredFont(forTextStyle: style)
    }
    #endif
}

// MARK: - PlatformEdgeInsets Extensions

#if canImport(AppKit)
extension NSEdgeInsets {
    /// Initialize with uniform insets
    init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.init(top: top, left: left, bottom: bottom, right: right)
    }
}
#endif
