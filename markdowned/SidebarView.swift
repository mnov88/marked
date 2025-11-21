//
//  SidebarView.swift
//  markdowned
//
//  Sidebar navigation for Mac and iPad with categories
//

import SwiftUI

/// Sidebar item representing navigation destinations
enum SidebarItem: Hashable, Identifiable {
    case category(Category)
    case allDocuments
    case highlights
    case settings

    var id: String {
        switch self {
        case .category(let category):
            return "category-\(category.id.uuidString)"
        case .allDocuments:
            return "all-documents"
        case .highlights:
            return "highlights"
        case .settings:
            return "settings"
        }
    }

    var title: String {
        switch self {
        case .category(let category):
            return category.name
        case .allDocuments:
            return "All Documents"
        case .highlights:
            return "Highlights"
        case .settings:
            return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .category(let category):
            return category.icon
        case .allDocuments:
            return "doc.text"
        case .highlights:
            return "highlighter"
        case .settings:
            return "gear"
        }
    }
}

/// Sidebar view for Mac and iPad navigation
struct SidebarView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var selection: SidebarItem?
    @State private var userCategories: [Category] = [] // TODO: Load from database

    var body: some View {
        List(selection: $selection) {
            // Library Section
            Section("Library") {
                Label("All Documents", systemImage: "doc.text")
                    .tag(SidebarItem.allDocuments)

                Label("Highlights", systemImage: "highlighter")
                    .tag(SidebarItem.highlights)
            }

            // Categories Section (Placeholder for future)
            Section("Categories") {
                if userCategories.isEmpty {
                    Text("No categories yet")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                        .italic()
                } else {
                    ForEach(userCategories) { category in
                        Label {
                            Text(category.name)
                        } icon: {
                            Image(systemName: category.icon)
                                .foregroundStyle(Color(uiColor: category.color))
                        }
                        .tag(SidebarItem.category(category))
                    }
                }

                // TODO: Add category management
                // Button {
                //     // Add new category
                // } label: {
                //     Label("Add Category", systemImage: "plus")
                // }
            }

            // Settings Section
            Section {
                Label("Settings", systemImage: "gear")
                    .tag(SidebarItem.settings)
            }
        }
        .navigationTitle("Marked")
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        #endif
    }
}

#Preview {
    NavigationSplitView {
        SidebarView(selection: .constant(.allDocuments))
            .environmentObject(ThemeManager())
    } detail: {
        Text("Select an item")
    }
}
