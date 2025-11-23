//
//  ContentView.swift
//  markdowned
//
//  Platform-adaptive root view that chooses navigation pattern based on device
//

import SwiftUI

/// Root content view that adapts navigation to platform
struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Group {
            #if os(macOS)
            // macOS: Always use NavigationSplitView with liquid glass sidebar
            MainNavigationView()
            #else
            // iOS/iPadOS: Use size class to determine layout
            if horizontalSizeClass == .regular {
                // iPad or large iPhone: Use NavigationSplitView
                MainNavigationView()
            } else {
                // iPhone compact: Use traditional TabView
                CompactTabView()
            }
            #endif
        }
        // MARK: - Keyboard Shortcut Handlers
        .onReceive(NotificationCenter.default.publisher(for: .increaseFontSize)) { _ in
            themeManager.increaseFontSize()
        }
        .onReceive(NotificationCenter.default.publisher(for: .decreaseFontSize)) { _ in
            themeManager.decreaseFontSize()
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetFontSize)) { _ in
            themeManager.resetFontSize()
        }
    }
}

/// Compact TabView for iPhone
struct CompactTabView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedTab: NavigationSection = .documents

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DocumentsListView()
            }
            .tabItem {
                Label("Documents", systemImage: "doc.text")
            }
            .tag(NavigationSection.documents)

            AllHighlightsView()
                .tabItem {
                    Label("Highlights", systemImage: "highlighter")
                }
                .tag(NavigationSection.highlights)

            CompositionsListView()
                .tabItem {
                    Label("Assembly", systemImage: "doc.on.doc")
                }
                .tag(NavigationSection.compositions)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(NavigationSection.settings)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToSection)) { notification in
            if let section = notification.userInfo?["section"] as? NavigationSection {
                withAnimation {
                    selectedTab = section
                }
            }
        }
    }
}

#Preview("Mac/iPad") {
    ContentView()
        .environmentObject(ThemeManager())
        .previewInterfaceOrientation(.landscapeLeft)
}

#Preview("iPhone") {
    ContentView()
        .environmentObject(ThemeManager())
        .environment(\.horizontalSizeClass, .compact)
}
