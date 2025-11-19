//
//  SettingsView.swift
//  markdowned
//
//  Created by Milos Novovic on 17/11/2025.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingFontPicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Theme Selection") {
                    Picker("Theme", selection: Binding(
                        get: { themeManager.selectedThemeType },
                        set: { themeManager.selectedThemeType = $0 }
                    )) {
                        ForEach(themeManager.availableThemes, id: \.self) { theme in
                            Text(theme).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                if themeManager.selectedThemeType == "Custom" {
                    customThemeSection
                }
                
                layoutSection
                
                previewSection
                
                Section {
                    Button("Reset to Defaults") {
                        themeManager.resetToDefaults()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private var customThemeSection: some View {
        Section("Custom Theme") {
            // Font family
            Button {
                showingFontPicker = true
            } label: {
                HStack {
                    Text("Font")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(displayFontName(themeManager.customTheme.fontName))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
            }
            .sheet(isPresented: $showingFontPicker) {
                FontPickerView(selectedFont: Binding(
                    get: { themeManager.customTheme.fontName },
                    set: { 
                        var updated = themeManager.customTheme
                        updated.fontName = $0
                        themeManager.customTheme = updated
                    }
                ))
            }
            
            // Font size
            Stepper(
                value: Binding(
                    get: { Double(themeManager.customTheme.fontSize) },
                    set: {
                        var updated = themeManager.customTheme
                        updated.fontSize = CGFloat($0)
                        themeManager.customTheme = updated
                    }
                ),
                in: 12...24,
                step: 1
            ) {
                HStack {
                    Text("Font Size")
                    Spacer()
                    Text("\(Int(themeManager.customTheme.fontSize))pt")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Line height
            Stepper(
                value: Binding(
                    get: { Double(themeManager.customTheme.lineHeightMultiple) },
                    set: {
                        var updated = themeManager.customTheme
                        updated.lineHeightMultiple = CGFloat($0)
                        themeManager.customTheme = updated
                    }
                ),
                in: 1.0...2.0,
                step: 0.1
            ) {
                HStack {
                    Text("Line Height")
                    Spacer()
                    Text(String(format: "%.1f", themeManager.customTheme.lineHeightMultiple))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Background color
            Toggle("Use System Background", isOn: Binding(
                get: { themeManager.customTheme.useSystemBackground },
                set: {
                    var updated = themeManager.customTheme
                    updated.useSystemBackground = $0
                    themeManager.customTheme = updated
                }
            ))
            
            if !themeManager.customTheme.useSystemBackground {
                ColorPicker(
                    "Background Color",
                    selection: Binding(
                        get: { Color(UIColor(hex: themeManager.customTheme.backgroundColorHex) ?? .systemBackground) },
                        set: {
                            var updated = themeManager.customTheme
                            updated.backgroundColorHex = UIColor($0).hexString
                            themeManager.customTheme = updated
                        }
                    )
                )
            }
            
            // Text color
            Toggle("Use System Text Color", isOn: Binding(
                get: { themeManager.customTheme.useSystemTextColor },
                set: {
                    var updated = themeManager.customTheme
                    updated.useSystemTextColor = $0
                    themeManager.customTheme = updated
                }
            ))
            
            if !themeManager.customTheme.useSystemTextColor {
                ColorPicker(
                    "Text Color",
                    selection: Binding(
                        get: { Color(UIColor(hex: themeManager.customTheme.textColorHex) ?? .label) },
                        set: {
                            var updated = themeManager.customTheme
                            updated.textColorHex = UIColor($0).hexString
                            themeManager.customTheme = updated
                        }
                    )
                )
            }
        }
    }
    
    private var layoutSection: some View {
        Section("Layout") {
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
        }
    }
    
    private var previewSection: some View {
        Section("Preview") {
            ThemePreviewView(theme: themeManager.currentTheme)
                .frame(height: 200)
        }
    }
    
    private func displayFontName(_ fontName: String) -> String {
        if fontName == "System" {
            return "System"
        }
        // Try to get a nicer display name
        if let font = UIFont(name: fontName, size: 17) {
            return font.familyName
        }
        return fontName
    }
}

struct ThemePreviewView: UIViewRepresentable {
    let theme: Theme
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        let style = theme.toDHStyle()
        
        // Create attributed string with proper line height
        let text = """
        Sample Text
        
        The quick brown fox jumps over the lazy dog. This is a preview of how your text will appear with the selected theme.
        
        Article 1
        
        1. First paragraph of legal text for demonstration purposes.
        """
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = theme.lineHeightMultiple
        paragraphStyle.paragraphSpacing = style.paragraphSpacing
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: style.font,
            .foregroundColor: style.textColor,
            .paragraphStyle: paragraphStyle
        ]
        
        uiView.attributedText = NSAttributedString(string: text, attributes: attributes)
        uiView.backgroundColor = style.backgroundColor
    }
}

struct FontPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFont: String
    @State private var searchText = ""
    
    private var fontFamilies: [(displayName: String, fontName: String)] {
        var fonts: [(String, String)] = [("System", "System")]
        
        let families = UIFont.familyNames.sorted()
        for family in families {
            if let firstFont = UIFont.fontNames(forFamilyName: family).first {
                fonts.append((family, firstFont))
            }
        }
        
        return fonts
    }
    
    private var filteredFonts: [(displayName: String, fontName: String)] {
        if searchText.isEmpty {
            return fontFamilies
        }
        return fontFamilies.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredFonts, id: \.fontName) { font in
                    Button {
                        selectedFont = font.fontName
                        dismiss()
                    } label: {
                        HStack {
                            Text(font.displayName)
                                .font(font.fontName == "System" ? .body : Font.custom(font.fontName, size: 17))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedFont == font.fontName {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Font")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search fonts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}

