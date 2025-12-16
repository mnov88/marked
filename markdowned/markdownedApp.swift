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
    private let coordinator = NavigationCoordinator.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environment(coordinator)
                .onOpenURL { url in
                    _ = coordinator.handleDeepLink(url)
                }
        }
        #if os(macOS)
        // iOS 26: Menu bar commands now also work on iPad
        .commands {
            AppCommands()
        }
        #endif
    }
}
