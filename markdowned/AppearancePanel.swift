//
//  AppearancePanel.swift
//  markdowned
//
//  Created by Claude on 21/11/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A Kindle/Apple Books-style appearance panel for quick theme and typography adjustments
struct AppearancePanel: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingFontPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Theme picker circles
                    themePickerSection

                    Divider()

                    typographySection

                    Divider()

                    // Line spacing control
                    lineSpacingSection

                    Divider()

                    colorSection

                    Divider()

                    layoutSection

                    Divider()

                    previewSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingFontPicker) {
            FontPickerView(selectedFont: Binding(
                get: { activeTheme.fontName },
                set: { setFontName($0) }
            ))
        }
    }

    // MARK: - Theme Picker

    private var themePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ForEach(Theme.allPresets, id: \.0) { name, theme in
                    ThemeCircleButton(
                        name: name,
                        theme: theme,
                        isSelected: themeManager.selectedThemeType == name,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                themeManager.selectedThemeType = name
                            }
                        }
                    )
                }

                // Custom theme option
                ThemeCircleButton(
                    name: "Custom",
                    theme: themeManager.customTheme,
                    isSelected: themeManager.selectedThemeType == "Custom",
                    isCustom: true,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeManager.selectedThemeType = "Custom"
                        }
                    }
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Typography

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            header("Typography")

            VStack(alignment: .leading, spacing: 10) {
                Button {
                    showingFontPicker = true
                } label: {
                    HStack {
                        Text("Font")
                        Spacer()
                        Text(displayFontName(activeTheme.fontName))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                fontSizeSection
            }
        }
    }

    // MARK: - Font Size

    private var fontSizeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Text Size")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                // Decrease button
                Button {
                    adjustFontSize(by: -1)
                } label: {
                    Text("A")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(currentFontSize <= 12)

                // Slider
                Slider(
                    value: Binding(
                        get: { Double(currentFontSize) },
                        set: { setFontSize(CGFloat($0)) }
                    ),
                    in: 12...28,
                    step: 1
                )
                .tint(.primary)

                // Increase button
                Button {
                    adjustFontSize(by: 1)
                } label: {
                    Text("A")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(currentFontSize >= 28)
            }
        }
    }

    // MARK: - Line Spacing

    private var lineSpacingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            header("Line Spacing")

            HStack(spacing: 12) {
                ForEach(LineSpacingOption.allCases) { option in
                    LineSpacingButton(
                        option: option,
                        isSelected: isLineSpacingSelected(option),
                        action: { setLineSpacing(option) }
                    )
                }
            }
        }
    }

    // MARK: - Colors

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            header("Colors")

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Use System Background", isOn: Binding(
                    get: { activeTheme.useSystemBackground },
                    set: { setUseSystemBackground($0) }
                ))

                if !activeTheme.useSystemBackground {
                    ColorPicker(
                        "Background",
                        selection: Binding(
                            get: { Color(platformColor: PlatformColor(hex: activeTheme.backgroundColorHex) ?? .systemBackground) },
                            set: { setBackgroundColor($0) }
                        )
                    )
                }

                Toggle("Use System Text Color", isOn: Binding(
                    get: { activeTheme.useSystemTextColor },
                    set: { setUseSystemTextColor($0) }
                ))

                if !activeTheme.useSystemTextColor {
                    ColorPicker(
                        "Text",
                        selection: Binding(
                            get: { Color(platformColor: PlatformColor(hex: activeTheme.textColorHex) ?? .label) },
                            set: { setTextColor($0) }
                        )
                    )
                }
            }
        }
    }

    // MARK: - Layout

    private var marginsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Margins")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(DHStyle.HorizontalMargin.allCases, id: \.self) { margin in
                    MarginButton(
                        margin: margin,
                        isSelected: currentMargin == margin,
                        action: { setMargin(margin) }
                    )
                }
            }
        }
    }

    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            header("Layout")

            Toggle(isOn: Binding(
                get: { themeManager.usePageLayout },
                set: { themeManager.usePageLayout = $0 }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Page-like Appearance")
                    Text("Constrains text width on large screens")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            marginsSection
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            header("Preview")
            ThemePreviewView(theme: themeManager.currentTheme)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 1)
                )
        }
    }

    // MARK: - Helpers

    private var activeTheme: Theme {
        if themeManager.selectedThemeType == "Custom" {
            return themeManager.customTheme
        }
        return themeManager.currentTheme
    }

    private var currentFontSize: CGFloat {
        if themeManager.selectedThemeType == "Custom" {
            return themeManager.customTheme.fontSize
        }
        return themeManager.currentTheme.fontSize
    }

    private var currentMargin: DHStyle.HorizontalMargin {
        if themeManager.selectedThemeType == "Custom" {
            return themeManager.customTheme.horizontalMargin
        }
        return themeManager.currentTheme.horizontalMargin
    }

    private func header(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
    }

    private func modifyTheme(_ update: (inout Theme) -> Void) {
        if themeManager.selectedThemeType == "Custom" {
            var updated = themeManager.customTheme
            update(&updated)
            themeManager.customTheme = updated
        } else {
            var custom = themeManager.currentTheme
            update(&custom)
            themeManager.customTheme = custom
            themeManager.selectedThemeType = "Custom"
        }
    }

    private func setFontName(_ name: String) {
        modifyTheme { $0.fontName = name }
    }

    private func adjustFontSize(by delta: CGFloat) {
        let newSize = max(12, min(28, currentFontSize + delta))
        setFontSize(newSize)
    }

    private func setFontSize(_ size: CGFloat) {
        if themeManager.selectedThemeType == "Custom" {
            var updated = themeManager.customTheme
            updated.fontSize = size
            themeManager.customTheme = updated
        } else {
            // Switch to custom theme with current settings but new font size
            var custom = themeManager.currentTheme
            custom.fontSize = size
            themeManager.customTheme = custom
            themeManager.selectedThemeType = "Custom"
        }
    }

    private func isLineSpacingSelected(_ option: LineSpacingOption) -> Bool {
        let currentLineHeight: CGFloat
        if themeManager.selectedThemeType == "Custom" {
            currentLineHeight = themeManager.customTheme.lineHeightMultiple
        } else {
            currentLineHeight = themeManager.currentTheme.lineHeightMultiple
        }
        return option.range.contains(currentLineHeight)
    }

    private func setLineSpacing(_ option: LineSpacingOption) {
        if themeManager.selectedThemeType == "Custom" {
            var updated = themeManager.customTheme
            updated.lineHeightMultiple = option.value
            themeManager.customTheme = updated
        } else {
            var custom = themeManager.currentTheme
            custom.lineHeightMultiple = option.value
            themeManager.customTheme = custom
            themeManager.selectedThemeType = "Custom"
        }
    }

    private func setMargin(_ margin: DHStyle.HorizontalMargin) {
        if themeManager.selectedThemeType == "Custom" {
            var updated = themeManager.customTheme
            updated.horizontalMargin = margin
            themeManager.customTheme = updated
        } else {
            var custom = themeManager.currentTheme
            custom.horizontalMargin = margin
            themeManager.customTheme = custom
            themeManager.selectedThemeType = "Custom"
        }
    }

    private func setUseSystemBackground(_ useSystem: Bool) {
        modifyTheme { $0.useSystemBackground = useSystem }
    }

    private func setBackgroundColor(_ color: Color) {
        modifyTheme { $0.backgroundColorHex = color.platformColor.hexString }
    }

    private func setUseSystemTextColor(_ useSystem: Bool) {
        modifyTheme { $0.useSystemTextColor = useSystem }
    }

    private func setTextColor(_ color: Color) {
        modifyTheme { $0.textColorHex = color.platformColor.hexString }
    }

    private func displayFontName(_ fontName: String) -> String {
        if fontName == "System" {
            return "System"
        }
        #if canImport(UIKit)
        if let font = UIFont(name: fontName, size: 17) {
            return font.familyName
        }
        #elseif canImport(AppKit)
        if let font = NSFont(name: fontName, size: 17) {
            return font.familyName
        }
        #endif
        return fontName
    }
}

// MARK: - Line Spacing Option

enum LineSpacingOption: String, CaseIterable, Identifiable {
    case compact = "Compact"
    case normal = "Normal"
    case relaxed = "Relaxed"

    var id: String { rawValue }

    var value: CGFloat {
        switch self {
        case .compact: return 1.1
        case .normal: return 1.3
        case .relaxed: return 1.6
        }
    }

    var range: ClosedRange<CGFloat> {
        switch self {
        case .compact: return 0.9...1.2
        case .normal: return 1.2...1.45
        case .relaxed: return 1.45...2.0
        }
    }

    var icon: String {
        switch self {
        case .compact: return "text.alignleft"
        case .normal: return "text.alignleft"
        case .relaxed: return "text.alignleft"
        }
    }
}

// MARK: - Theme Circle Button

struct ThemeCircleButton: View {
    let name: String
    let theme: Theme
    let isSelected: Bool
    var isCustom: Bool = false
    let action: () -> Void

    private var backgroundColor: Color {
        if theme.useSystemBackground {
            return Color(.systemBackground)
        }
        return Color(platformColor: PlatformColor(hex: theme.backgroundColorHex) ?? .systemBackground)
    }

    private var textColor: Color {
        if theme.useSystemTextColor {
            return Color(.label)
        }
        return Color(platformColor: PlatformColor(hex: theme.textColorHex) ?? .label)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .strokeBorder(isSelected ? Color.accentColor : Color(.separator), lineWidth: isSelected ? 2.5 : 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                    if isCustom {
                        // Show gradient for custom theme
                        Image(systemName: "paintpalette")
                            .font(.system(size: 16))
                            .foregroundStyle(textColor)
                    } else {
                        Text("Aa")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(textColor)
                    }
                }

                Text(name)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Line Spacing Button

struct LineSpacingButton: View {
    let option: LineSpacingOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Visual representation of line spacing
                VStack(spacing: lineSpacing) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.primary.opacity(0.6))
                            .frame(height: 2)
                    }
                }
                .frame(width: 32, height: 24)
                .padding(10)
                .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )

                Text(option.rawValue)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var lineSpacing: CGFloat {
        switch option {
        case .compact: return 3
        case .normal: return 5
        case .relaxed: return 7
        }
    }
}

// MARK: - Margin Button

struct MarginButton: View {
    let margin: DHStyle.HorizontalMargin
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Visual representation of margins
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: marginWidth)
                    VStack(spacing: 3) {
                        ForEach(0..<4) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.primary.opacity(0.6))
                                .frame(height: 2)
                        }
                    }
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: marginWidth)
                }
                .frame(width: 44, height: 28)
                .padding(8)
                .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )

                Text(margin.rawValue)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var marginWidth: CGFloat {
        switch margin {
        case .extraNarrow: return 2
        case .narrow: return 4
        case .medium: return 6
        case .wide: return 9
        case .extraWide: return 12
        }
    }
}

// MARK: - Preview

#Preview {
    AppearancePanel()
        .environmentObject(ThemeManager())
}
