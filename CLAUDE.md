# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
# Build and run in Xcode (primary method)
open markdowned.xcodeproj
# Then press ⌘R to build and run

# Run tests (Swift Testing framework)
# In Xcode: ⌘U or Product → Test
# Tests are in markdownedTests/markdownedTests.swift
```

## Project Overview

**Markdowned** is a native iOS/iPadOS/macOS document reader and highlighter built with SwiftUI and UIKit. It uses GRDB for SQLite persistence and targets iOS 17+/iOS 26+ with platform-adaptive navigation.

### Key Capabilities
- Document management with SQLite-backed storage (GRDB)
- Text highlighting with 5 colors, persisted per-document
- URL import with HTML-to-plain-text conversion
- EU legal case search from bundled CSV (~4MB)
- Advanced theming with system/custom colors and fonts
- Full-text search via FTS5
- Compositions (collections of highlights)

## Architecture

### Data Flow Pattern
```
User Action → Manager Method → GRDB Write
                                    ↓
                            ValueObservation
                                    ↓
                            @Published property
                                    ↓
                            SwiftUI View Update
```

### Singleton Managers (@MainActor)
All managers are singletons running on the main actor:
- `DatabaseManager.shared` - Connection, migrations, read/write access
- `DocumentsManager.shared` - Document CRUD and observation
- `HighlightsManager.shared` - Highlight CRUD and observation
- `CategoriesManager.shared` - Category CRUD
- `CompositionsManager.shared` - Composition/fragment CRUD
- `ThemeManager` - Theme state (injected via @EnvironmentObject)

### Platform-Adaptive Navigation
```
ContentView (Root)
├── macOS → MainNavigationView (NavigationSplitView)
└── iOS/iPadOS → Adaptive based on size class
    ├── Regular (iPad) → MainNavigationView
    └── Compact (iPhone) → CompactTabView (TabView)
```

### Hybrid SwiftUI/UIKit
- **SwiftUI**: App structure, navigation, forms, settings
- **UIKit**: Text rendering via `DHTextView` (UIViewRepresentable wrapping UITextView)
  - Handles highlight context menus, text selection, smooth scrolling

### Text Rendering Pipeline
1. Content Input (plain string or NSAttributedString)
2. Link Detection (regex-based article references)
3. Heading Detection (`DHConfig.defaultHeadings` with regex patterns)
4. Indentation (multi-level list markers)
5. Composition in `DHComposer` (combines base + links + indents + headings)
6. Highlight overlay (semi-transparent backgrounds)
7. Display in UITextView with theme styling

### Database Schema (GRDB)
Key tables: `document`, `highlight`, `category`, `documentCategory`, `composition`, `compositionFragment`, `document_fts` (FTS5 virtual table)

Migrations are in `DatabaseManager.registerMigrations()`. In DEBUG mode, `eraseDatabaseOnSchemaChange = true` auto-resets on schema changes.

## Key Files

| File | Purpose |
|------|---------|
| `DatabaseManager.swift` | GRDB singleton, migrations, db access |
| `DocHighlightingView.swift` | Main document viewer |
| `DHTextView.swift` | UITextView wrapper (UIViewRepresentable) |
| `DHComposer.swift` | Attributed string composition |
| `DHTextHighlight.swift` | Highlight/link/indent models + DHConfig |
| `ContentLoader.swift` | URL fetching, HTML→text conversion, post-processing |
| `MainNavigationView.swift` | NavigationSplitView for Mac/iPad |
| `ContentView.swift` | Platform-adaptive root routing |
| `AppCommands.swift` | Menu bar commands and keyboard shortcuts |

## Dependencies (Package.swift)

- **GRDB** - SQLite persistence (actively used)
- Ink, SwiftSoup, ZIPFoundation - Legacy/unused, can be removed

## Conventions

- All managers use `@MainActor` and singleton pattern
- GRDB ValueObservation for reactive UI updates
- Highlights stored as NSRange (location, length) with hex color
- Theme settings persisted in UserDefaults
- Post-processing regex patterns for HTML cleanup in `ContentLoader.postProcessText`
- Heading detection patterns in `DHConfig.defaultHeadings` (matches EU legal document formats)
