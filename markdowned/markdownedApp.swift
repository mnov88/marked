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

    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            MacOSRootView()
                .environmentObject(themeManager)
            #else
            IOSRootView()
                .environmentObject(themeManager)
            #endif
        }
        #if os(macOS)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Preferences...") {
                    // macOS Settings will be handled via NavigationSplitView
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Import from URL...") {
                    // Trigger URL import
                }
                .keyboardShortcut("i", modifiers: .command)
            }
        }
        #endif
    }
}

// MARK: - iOS Root View

#if !os(macOS)
struct IOSRootView: View {
    var body: some View {
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
    }
}
#endif

// MARK: - macOS Root View

#if os(macOS)
struct MacOSRootView: View {
    @State private var selectedSection: SidebarSection? = .documents

    enum SidebarSection: Hashable {
        case documents
        case highlights
        case settings
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedSection) {
                NavigationLink(value: SidebarSection.documents) {
                    Label("Documents", systemImage: "doc.text")
                }

                NavigationLink(value: SidebarSection.highlights) {
                    Label("Highlights", systemImage: "highlighter")
                }

                Divider()

                NavigationLink(value: SidebarSection.settings) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } detail: {
            // Detail view
            switch selectedSection {
            case .documents:
                MockDocList()
            case .highlights:
                AllHighlightsView()
            case .settings:
                SettingsView()
            case .none:
                Text("Select a section from the sidebar")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
#endif
