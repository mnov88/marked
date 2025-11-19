//
//  markdownedApp.swift
//  markdowned
//
//  Created by Milos Novovic on 05/11/2025.
//

import SwiftUI

@main
struct markdownedApp: App {
    @State private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                MockDocList()
                    .tabItem {
                        Label("Documents", systemImage: "doc.text")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .environment(themeManager)
        }
    }
}
