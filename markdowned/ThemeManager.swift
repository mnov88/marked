//
//  ThemeManager.swift
//  markdowned
//
//  Created by Milos Novovic on 17/11/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ThemeManager: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let selectedThemeTypeKey = "selectedThemeType"
    private let customThemeKey = "customTheme"
    private let usePageLayoutKey = "usePageLayout"

    // Debouncing support
    private var saveThemeTypeTask: Task<Void, Never>?
    private var saveCustomThemeTask: Task<Void, Never>?
    private var savePageLayoutTask: Task<Void, Never>?
    private let saveDebounceDuration: Duration = .milliseconds(300)

    @Published var selectedThemeType: String {
        didSet {
            debouncedSaveThemeType()
        }
    }

    @Published var customTheme: Theme {
        didSet {
            debouncedSaveCustomTheme()
        }
    }

    @Published var usePageLayout: Bool {
        didSet {
            debouncedSavePageLayout()
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

    // MARK: - Debounced Save Methods

    private func debouncedSaveThemeType() {
        saveThemeTypeTask?.cancel()
        let themeType = selectedThemeType
        saveThemeTypeTask = Task { @MainActor in
            do {
                try await Task.sleep(for: saveDebounceDuration)
                guard !Task.isCancelled else { return }
                userDefaults.set(themeType, forKey: selectedThemeTypeKey)
            } catch {
                if !(error is CancellationError) {
                    print("Failed to save theme type: \(error)")
                }
            }
        }
    }

    private func debouncedSaveCustomTheme() {
        saveCustomThemeTask?.cancel()
        let theme = customTheme
        saveCustomThemeTask = Task { @MainActor in
            do {
                try await Task.sleep(for: saveDebounceDuration)
                guard !Task.isCancelled else { return }
                if let encoded = try? JSONEncoder().encode(theme) {
                    userDefaults.set(encoded, forKey: customThemeKey)
                }
            } catch {
                if !(error is CancellationError) {
                    print("Failed to save custom theme: \(error)")
                }
            }
        }
    }

    private func debouncedSavePageLayout() {
        savePageLayoutTask?.cancel()
        let layout = usePageLayout
        savePageLayoutTask = Task { @MainActor in
            do {
                try await Task.sleep(for: saveDebounceDuration)
                guard !Task.isCancelled else { return }
                userDefaults.set(layout, forKey: usePageLayoutKey)
            } catch {
                if !(error is CancellationError) {
                    print("Failed to save page layout: \(error)")
                }
            }
        }
    }

    /// Force immediate save (e.g., on app termination)
    func saveImmediately() {
        saveThemeTypeTask?.cancel()
        saveCustomThemeTask?.cancel()
        savePageLayoutTask?.cancel()

        userDefaults.set(selectedThemeType, forKey: selectedThemeTypeKey)
        userDefaults.set(usePageLayout, forKey: usePageLayoutKey)
        if let encoded = try? JSONEncoder().encode(customTheme) {
            userDefaults.set(encoded, forKey: customThemeKey)
        }
    }

    deinit {
        saveThemeTypeTask?.cancel()
        saveCustomThemeTask?.cancel()
        savePageLayoutTask?.cancel()
    }
}

