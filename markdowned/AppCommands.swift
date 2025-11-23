//
//  AppCommands.swift
//  markdowned
//
//  Menu bar commands and keyboard shortcuts for macOS and iPad (iOS 26+)
//

import SwiftUI

/// Menu commands for the application
/// iOS 26: These commands now also create menu bars on iPad
struct AppCommands: Commands {
    var body: some Commands {
        // MARK: - File Menu

        CommandGroup(replacing: .newItem) {
            Button("New Document from URL...") {
                // TODO: Post notification to open URL entry sheet
                NotificationCenter.default.post(name: .showURLEntry, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command])
        }

        CommandGroup(after: .importExport) {
            Button("Export Document...") {
                // TODO: Implement document export
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .disabled(true) // Placeholder

            Divider()

            Button("Export All Highlights...") {
                // TODO: Implement highlights export
            }
            .disabled(true) // Placeholder
        }

        // MARK: - Edit Menu

        CommandGroup(after: .pasteboard) {
            Menu("Highlight") {
                Button("Yellow") {
                    NotificationCenter.default.post(
                        name: .applyHighlight,
                        object: nil,
                        userInfo: ["color": HighlightShortcutColor.yellow]
                    )
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button("Green") {
                    NotificationCenter.default.post(
                        name: .applyHighlight,
                        object: nil,
                        userInfo: ["color": HighlightShortcutColor.green]
                    )
                }
                .keyboardShortcut("2", modifiers: [.command])

                Button("Blue") {
                    NotificationCenter.default.post(
                        name: .applyHighlight,
                        object: nil,
                        userInfo: ["color": HighlightShortcutColor.blue]
                    )
                }
                .keyboardShortcut("3", modifiers: [.command])

                Button("Pink") {
                    NotificationCenter.default.post(
                        name: .applyHighlight,
                        object: nil,
                        userInfo: ["color": HighlightShortcutColor.pink]
                    )
                }
                .keyboardShortcut("4", modifiers: [.command])

                Button("Purple") {
                    NotificationCenter.default.post(
                        name: .applyHighlight,
                        object: nil,
                        userInfo: ["color": HighlightShortcutColor.purple]
                    )
                }
                .keyboardShortcut("5", modifiers: [.command])

                Divider()

                Button("Remove Highlight") {
                    NotificationCenter.default.post(name: .removeHighlight, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: [.command])
            }
        }

        // MARK: - View Menu

        CommandGroup(after: .sidebar) {
            Button("Toggle Sidebar") {
                #if os(macOS)
                NSApp.keyWindow?.firstResponder?.tryToPerform(
                    #selector(NSSplitViewController.toggleSidebar(_:)),
                    with: nil
                )
                #endif
            }
            .keyboardShortcut("s", modifiers: [.command, .control])

            Divider()

            Menu("Appearance") {
                Button("Increase Font Size") {
                    NotificationCenter.default.post(name: .increaseFontSize, object: nil)
                }
                .keyboardShortcut("+", modifiers: [.command])

                Button("Decrease Font Size") {
                    NotificationCenter.default.post(name: .decreaseFontSize, object: nil)
                }
                .keyboardShortcut("-", modifiers: [.command])

                Button("Reset Font Size") {
                    NotificationCenter.default.post(name: .resetFontSize, object: nil)
                }
                .keyboardShortcut("0", modifiers: [.command])
            }
        }

        // MARK: - Document Menu (Custom)

        CommandMenu("Document") {
            Button("Show Document Info") {
                // TODO: Show document metadata
            }
            .keyboardShortcut("i", modifiers: [.command])
            .disabled(true) // Placeholder

            Button("Reload from URL") {
                // TODO: Reload document from source URL
            }
            .keyboardShortcut("r", modifiers: [.command])
            .disabled(true) // Placeholder

            Divider()

            Menu("Add to Category") {
                // TODO: Dynamically populate with categories
                Button("Create New Category...") {
                    // TODO: Show category creation dialog
                }
            }
            .disabled(true) // Placeholder

            Divider()

            Button("Delete Document") {
                // TODO: Delete current document
            }
            .keyboardShortcut(.delete, modifiers: [.command, .shift])
            .disabled(true) // Placeholder
        }

        // MARK: - Navigation Menu (Custom)

        CommandMenu("Go") {
            Button("All Documents") {
                NotificationCenter.default.post(
                    name: .navigateToSection,
                    object: nil,
                    userInfo: ["section": NavigationSection.documents]
                )
            }
            .keyboardShortcut("1", modifiers: [.command, .shift])

            Button("Highlights") {
                NotificationCenter.default.post(
                    name: .navigateToSection,
                    object: nil,
                    userInfo: ["section": NavigationSection.highlights]
                )
            }
            .keyboardShortcut("2", modifiers: [.command, .shift])

            Button("Compositions") {
                NotificationCenter.default.post(
                    name: .navigateToSection,
                    object: nil,
                    userInfo: ["section": NavigationSection.compositions]
                )
            }
            .keyboardShortcut("3", modifiers: [.command, .shift])

            Button("Settings") {
                NotificationCenter.default.post(
                    name: .navigateToSection,
                    object: nil,
                    userInfo: ["section": NavigationSection.settings]
                )
            }
            .keyboardShortcut(",", modifiers: [.command])
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    // Document actions
    static let showURLEntry = Notification.Name("showURLEntry")

    // Highlight actions (userInfo: ["color": PlatformColor])
    static let applyHighlight = Notification.Name("applyHighlight")
    static let removeHighlight = Notification.Name("removeHighlight")

    // Navigation (userInfo: ["section": NavigationSection])
    static let navigateToSection = Notification.Name("navigateToSection")

    // Font size
    static let increaseFontSize = Notification.Name("increaseFontSize")
    static let decreaseFontSize = Notification.Name("decreaseFontSize")
    static let resetFontSize = Notification.Name("resetFontSize")
}

// MARK: - Navigation Sections

enum NavigationSection: String {
    case documents
    case highlights
    case compositions
    case settings
}

// MARK: - Highlight Colors for Shortcuts

enum HighlightShortcutColor {
    static let yellow = PlatformColor.systemYellow
    static let green = PlatformColor.systemGreen
    static let blue = PlatformColor.systemBlue
    static let pink = PlatformColor.systemPink
    static let purple = PlatformColor.systemPurple
}
