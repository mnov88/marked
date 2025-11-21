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
                    // TODO: Apply yellow highlight to selection
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button("Green") {
                    // TODO: Apply green highlight to selection
                }
                .keyboardShortcut("2", modifiers: [.command])

                Button("Blue") {
                    // TODO: Apply blue highlight to selection
                }
                .keyboardShortcut("3", modifiers: [.command])

                Button("Pink") {
                    // TODO: Apply pink highlight to selection
                }
                .keyboardShortcut("4", modifiers: [.command])

                Button("Purple") {
                    // TODO: Apply purple highlight to selection
                }
                .keyboardShortcut("5", modifiers: [.command])

                Divider()

                Button("Remove Highlight") {
                    // TODO: Remove highlight from selection
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
                    // TODO: Increase theme font size
                }
                .keyboardShortcut("+", modifiers: [.command])

                Button("Decrease Font Size") {
                    // TODO: Decrease theme font size
                }
                .keyboardShortcut("-", modifiers: [.command])

                Button("Reset Font Size") {
                    // TODO: Reset theme font size to default
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
                // TODO: Navigate to all documents
            }
            .keyboardShortcut("1", modifiers: [.command, .shift])

            Button("Highlights") {
                // TODO: Navigate to highlights view
            }
            .keyboardShortcut("2", modifiers: [.command, .shift])

            Button("Settings") {
                // TODO: Navigate to settings
            }
            .keyboardShortcut(",", modifiers: [.command])

            Divider()

            Button("Next Document") {
                // TODO: Navigate to next document in list
            }
            .keyboardShortcut(.downArrow, modifiers: [.command, .option])
            .disabled(true) // Placeholder

            Button("Previous Document") {
                // TODO: Navigate to previous document in list
            }
            .keyboardShortcut(.upArrow, modifiers: [.command, .option])
            .disabled(true) // Placeholder
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showURLEntry = Notification.Name("showURLEntry")
    static let applyHighlight = Notification.Name("applyHighlight")
    static let removeHighlight = Notification.Name("removeHighlight")
    static let navigateToSection = Notification.Name("navigateToSection")
}
