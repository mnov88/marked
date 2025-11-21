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
}

/// Compact TabView for iPhone
struct CompactTabView: View {
    @EnvironmentObject private var themeManager: ThemeManager

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
