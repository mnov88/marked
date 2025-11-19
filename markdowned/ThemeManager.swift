//
//  ThemeManager.swift
//  markdowned
//
//  Created by Milos Novovic on 17/11/2025.
//

import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
final class ThemeManager {
    private let userDefaults = UserDefaults.standard
    private let selectedThemeTypeKey = "selectedThemeType"
    private let customThemeKey = "customTheme"
    private let usePageLayoutKey = "usePageLayout"
    
    var selectedThemeType: String {
        didSet {
            userDefaults.set(selectedThemeType, forKey: selectedThemeTypeKey)
        }
    }
    
    var customTheme: Theme {
        didSet {
            if let encoded = try? JSONEncoder().encode(customTheme) {
                userDefaults.set(encoded, forKey: customThemeKey)
            }
        }
    }
    
    var usePageLayout: Bool {
        didSet {
            userDefaults.set(usePageLayout, forKey: usePageLayoutKey)
        }
    }
    
    var currentTheme: Theme {
        var theme: Theme
        if selectedThemeType == "Custom" {
            theme = customTheme
        } else {
            theme = Theme.allPresets.first { $0.0 == selectedThemeType }?.1 ?? .light
        }
        
        // Apply global page layout setting
        var modifiedTheme = theme
        modifiedTheme.usePageLayout = usePageLayout
        return modifiedTheme
    }
    
    init() {
        // Load selected theme type
        self.selectedThemeType = userDefaults.string(forKey: selectedThemeTypeKey) ?? "System"
        
        // Load custom theme
        if let data = userDefaults.data(forKey: customThemeKey),
           let decoded = try? JSONDecoder().decode(Theme.self, from: data) {
            self.customTheme = decoded
        } else {
            self.customTheme = .system
        }
        
        // Load page layout preference
        self.usePageLayout = userDefaults.bool(forKey: usePageLayoutKey)
    }
    
    func resetToDefaults() {
        selectedThemeType = "System"
        customTheme = .system
        usePageLayout = false
    }
    
    var availableThemes: [String] {
        Theme.allPresets.map { $0.0 } + ["Custom"]
    }
}

