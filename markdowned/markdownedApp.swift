//
//  markdownedApp.swift
//  markdowned
//
//  Created by Milos Novovic on 05/11/2025.
//

import SwiftUI

@main
struct markdownedApp: App {
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            TabView {
                MockDocList()
                    .tabItem {
                        Label("Documents", systemImage: "doc.text")
                    }

                AllHighlightsView()
                    .tabItem {
                        Label("Highlights", systemImage: "highlighter")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .environmentObject(themeManager)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Save all pending data when app is backgrounded or inactive
            if newPhase == .background || newPhase == .inactive {
                Task { @MainActor in
                    themeManager.saveImmediately()
                    HighlightsManager.shared.saveImmediately()
                }
            }
        }
    }
}
