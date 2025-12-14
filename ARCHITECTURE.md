# Marked - Architecture Documentation

## Overview

Marked is a cross-platform document reader and highlighting application built with SwiftUI, targeting iOS 26, iPadOS 26, and macOS 26. The app uses platform-adaptive navigation to provide native experiences on each platform.

## Platform Support

- **iOS 26+** (iPhone): Compact TabView navigation
- **iPadOS 26+** (iPad): NavigationSplitView with liquid glass sidebar
- **macOS 26+** (Mac): NavigationSplitView with menu bar, toolbars, and keyboard shortcuts
- **visionOS 26+**: Full support (uses iPad layout)

## Navigation Architecture (iOS 26)

### Liquid Glass Sidebar (New in iOS 26)

The app uses the new **liquid glass sidebar** feature introduced in iOS 26/iPadOS 26/macOS 26:
- Sidebar floats above content with beautiful glass refraction effect
- Automatic with Xcode 26 compilation (no special modifiers needed)
- Provides a more immersive and modern appearance

### Platform-Adaptive Navigation

```
ContentView (Root)
├── macOS → MainNavigationView (always)
└── iOS/iPadOS → Adaptive based on size class
    ├── Regular (iPad) → MainNavigationView (NavigationSplitView)
    └── Compact (iPhone) → CompactTabView (TabView)
```

**Key Components:**
1. **ContentView** - Platform detection and routing
2. **MainNavigationView** - NavigationSplitView for Mac/iPad
3. **SidebarView** - Sidebar content (categories, documents, highlights, settings)
4. **DocumentsListView** - Document list with search and case loading
5. **CompactTabView** - Traditional tab-based navigation for iPhone

## Data Models

### Document & Highlights

- **Document** - Main content container (plain text or attributed string)
- **DBDocument** - GRDB-persisted document with SQLite storage
- **DHTextHighlight** - In-memory highlight with color and range
- **DBHighlight** - GRDB-persisted highlight

### Categories (NEW)

```swift
struct Category {
    let id: UUID
    var name: String
    var color: UIColor
    var icon: String
    var sortOrder: Int
}
```

**Default Categories:**
- All Documents (shows all)
- Highlights (dedicated highlight browser)
- Uncategorized (documents without categories)

## Database Schema (GRDB/SQLite)

### Current Tables

```sql
-- Documents
CREATE TABLE document (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    contentType TEXT NOT NULL,
    contentData BLOB NOT NULL,
    sourceURL TEXT,
    createdAt DATETIME NOT NULL,
    modifiedAt DATETIME NOT NULL
);

-- Highlights
CREATE TABLE highlight (
    id TEXT PRIMARY KEY,
    documentId TEXT NOT NULL REFERENCES document(id) ON DELETE CASCADE,
    location INTEGER NOT NULL,
    length INTEGER NOT NULL,
    colorHex TEXT NOT NULL,
    createdAt DATETIME NOT NULL
);
```

### Planned Tables (TODO)

```sql
-- Categories
CREATE TABLE category (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    colorHex TEXT NOT NULL,
    icon TEXT NOT NULL,
    sortOrder INTEGER NOT NULL,
    createdAt DATETIME NOT NULL
);

-- Document-Category Junction
CREATE TABLE document_category (
    documentId TEXT NOT NULL REFERENCES document(id) ON DELETE CASCADE,
    categoryId TEXT NOT NULL REFERENCES category(id) ON DELETE CASCADE,
    addedAt DATETIME NOT NULL,
    PRIMARY KEY (documentId, categoryId)
);
```

## iOS 26 / macOS 26 Features

### Implemented

✅ **NavigationSplitView with liquid glass sidebar**
- Automatic glass effect on Mac and iPad
- Three-column capable layout
- Adaptive column visibility

✅ **Unified Search**
- Placed on NavigationSplitView for app-wide scope
- Appears in top trailing corner on iPad (iOS 26 behavior)

✅ **Menu Bar Commands** (Mac + iPad in iOS 26)
- File menu (New, Export)
- Edit menu (Highlight colors, Remove)
- View menu (Sidebar, Appearance)
- Custom Document and Go menus

✅ **Keyboard Shortcuts**
- ⌘N - New document from URL
- ⌘1-5 - Apply highlight colors
- ⌘⌃S - Toggle sidebar
- ⌘+/- - Font size adjustment
- See `AppCommands.swift` for complete list

### Planned (Placeholders)

🔲 **backgroundExtensionEffect** - For immersive document reading
🔲 **glassEffect customization** - Fine-tune glass appearance
🔲 **Enhanced toolbar** - Context-aware toolbar items
🔲 **Document categories** - Full CRUD operations
🔲 **Category filtering** - Filter documents by category
🔲 **Drag & drop** - Organize documents into categories
🔲 **Export features** - PDF, HTML, Markdown export
🔲 **Command palette** - Quick action search (⌘K)

## File Structure

```
markdowned/
├── App
│   ├── markdownedApp.swift          # App entry point
│   ├── ContentView.swift             # Platform-adaptive root
│   ├── AppCommands.swift             # Menu bar commands
│
├── Navigation
│   ├── MainNavigationView.swift     # NavigationSplitView (Mac/iPad)
│   ├── SidebarView.swift             # Sidebar content
│   ├── DocumentsListView.swift      # (embedded in MainNavigationView)
│
├── Models
│   ├── Document.swift                # Document model
│   ├── DBDocument.swift              # Database document
│   ├── DHTextHighlight.swift         # Highlight model
│   ├── DBHighlight.swift             # Database highlight
│   ├── Category.swift                # Category model (NEW)
│   ├── Theme.swift                   # Theme configuration
│
├── Views
│   ├── DocHighlightingView.swift    # Document reader
│   ├── DHTextView.swift              # UITextView wrapper
│   ├── AllHighlightsView.swift       # Highlights browser
│   ├── SettingsView.swift            # App settings
│   ├── URLEntryView.swift            # URL input sheet
│
├── Managers
│   ├── DatabaseManager.swift         # GRDB singleton
│   ├── DocumentsManager.swift        # Document CRUD
│   ├── HighlightsManager.swift       # Highlight CRUD
│   ├── ThemeManager.swift            # Theme management
│
└── Utilities
    ├── DHComposer.swift               # Attributed string composition
    ├── DHViewModel.swift              # Highlight view model
    ├── ContentLoader.swift            # URL content fetching + HTML-to-text cleanup (list merge, heading promotion)
    ├── Utilities.swift                # Helpers
```

## Architecture Patterns

### Singleton Managers (@MainActor)

All managers are singletons running on the main actor:
- `DatabaseManager.shared` - Database connection and migrations
- `DocumentsManager.shared` - Document persistence and observation
- `HighlightsManager.shared` - Highlight persistence and observation
- `ThemeManager` - Theme state (injected via @EnvironmentObject)

### Reactive Updates (Combine + GRDB)

```
User Action → Manager Method → GRDB Write
                                    ↓
                            ValueObservation
                                    ↓
                            @Published property
                                    ↓
                            SwiftUI View Update
```

### Hybrid SwiftUI/UIKit

- **SwiftUI**: App structure, navigation, forms, settings
- **UIKit**: Advanced text rendering via UITextView
  - `DHTextView` (UIViewRepresentable wrapper)
  - Highlight context menus
  - Text selection and interaction

## Future Expansion Areas

### 1. Document Categories (High Priority)

**Implementation Steps:**
1. Add `DBCategory` and `DBDocumentCategory` models
2. Create database migration in `DatabaseManager`
3. Create `CategoriesManager` for CRUD operations
4. Update `SidebarView` to show categories
5. Add category selection/filtering in `DocumentsListView`
6. Implement drag-drop for document organization

**UI Components:**
- Category creation sheet
- Category color/icon picker
- Category management view in Settings
- Drag-and-drop handlers

### 2. Export Features

**Formats:**
- PDF (with highlights preserved)
- HTML (with highlight colors)
- Markdown (plain text)
- JSON (structured data with highlights)

**Export Scopes:**
- Single document
- All documents in category
- All highlights
- Selected highlights

### 3. Enhanced Mac Features

**Native Mac UI:**
- Touch Bar support (highlight palette)
- Share extension
- Quick Look preview
- Spotlight integration
- Services menu integration

### 4. Collaboration Features

**Potential Future:**
- iCloud sync for documents and highlights
- Shared categories
- Highlight comments/notes
- Document versioning

### 5. Advanced Text Features

**Text Analysis:**
- Word frequency
- Reading time estimation
- Text statistics
- Custom link types (legal citations, case law, etc.)

## Performance Considerations

### iOS 26 Improvements

- **6x faster list loading** (100,000+ items)
- **16x faster list updates**
- Improved UI scheduling for smoother scrolling
- Better frame preparation at high refresh rates

### Current Optimizations

- GRDB ValueObservation for reactive updates
- Lazy loading of document content
- Efficient attributed string composition
- Text container reuse in UITextView

## Testing Strategy

### Platform Testing

1. **iPhone (Compact)** - TabView navigation, compact UI
2. **iPad (Regular)** - NavigationSplitView, sidebar, multitasking
3. **Mac** - Window management, menu bar, keyboard shortcuts
4. **visionOS** - Spatial navigation (future)

### Test Cases

- [ ] Navigation between all sections
- [ ] Document creation from URL
- [ ] Highlight creation/deletion
- [ ] Theme switching
- [ ] Search functionality
- [ ] Keyboard shortcuts (Mac)
- [ ] Menu bar commands (Mac/iPad)
- [ ] Size class transitions (iPad)
- [ ] Database migrations
- [ ] Large document performance (10MB+)

## Development Roadmap

### Phase 1: Foundation ✅ (Current)
- [x] NavigationSplitView architecture
- [x] Platform-adaptive layouts
- [x] Menu bar commands structure
- [x] Keyboard shortcuts placeholders
- [x] Category data model

### Phase 2: Categories (Next)
- [ ] Database migration for categories
- [ ] CategoriesManager implementation
- [ ] Category CRUD UI
- [ ] Document-category association
- [ ] Category filtering

### Phase 3: Polish
- [ ] Export functionality
- [ ] Advanced keyboard shortcuts
- [ ] Touch Bar support (Mac)
- [ ] Enhanced search
- [ ] Document metadata editing

### Phase 4: Advanced Features
- [ ] iCloud sync
- [ ] Highlight comments
- [ ] Text analysis
- [ ] Custom themes
- [ ] Plugin system

## Contributing

When adding new features:

1. **Follow platform patterns** - Use size classes, adapt to Mac/iPad/iPhone
2. **Use TODO comments** - Mark placeholder features with `// TODO:`
3. **Update this document** - Keep architecture docs current
4. **Test across platforms** - Verify on iPhone, iPad, and Mac
5. **Use modern APIs** - Leverage iOS 26/macOS 26 features when appropriate

## Resources

- [WWDC 2025: What's New in SwiftUI](https://developer.apple.com/videos/play/wwdc2025/256/)
- [Build a SwiftUI App with the New Design](https://developer.apple.com/videos/play/wwdc2025/323/)
- [NavigationSplitView Documentation](https://developer.apple.com/documentation/swiftui/navigationsplitview)
- [GRDB Documentation](https://github.com/groue/GRDB.swift)
