# Plan: DHTextView Reusable Package

## Goal
Extract the UITextView highlighting system into a standalone Swift Package that can be reused across projects with different data models and persistence layers.

---

## Current State Analysis

### Components to Package (Already Loosely Coupled)
| File | Purpose | Reusability |
|------|---------|-------------|
| `DHTextHighlight.swift` | Models (DHTextHighlight, DHLinkSpan, DHIndentSpan, DHHeadingSpan, DHStyle, DHConfig) | ✅ Ready |
| `DHComposer.swift` | Static attributed string composition | ✅ Ready |
| `DHTextView.swift` | UIViewRepresentable wrapping UITextView | ✅ Ready |
| `CrossPlatform.swift` | Platform type aliases (UIColor/NSColor, etc.) | ✅ Ready |

### Components Needing Abstraction
| File | Issue | Solution |
|------|-------|----------|
| `DHViewModel.swift` | Hardcoded `HighlightsManager.shared` singleton | Introduce `HighlightStore` protocol |
| `DocHighlightingView.swift` | Uses DHViewModel + ThemeManager EnvironmentObject | Keep in app, or create generic wrapper |

---

## Package Design

### Package Name
`DHTextView` (or `HighlightedTextView`)

### Package Structure
```
Sources/DHTextView/
├── Models/
│   ├── DHTextHighlight.swift      # Highlight model (id, range, color)
│   ├── DHSpans.swift              # DHLinkSpan, DHIndentSpan, DHHeadingSpan
│   └── DHStyle.swift              # Styling configuration
├── Configuration/
│   └── DHConfig.swift             # Config with pluggable detectors
├── Composition/
│   └── DHComposer.swift           # Static composition function
├── Views/
│   └── DHTextView.swift           # UIViewRepresentable
├── Protocols/
│   └── HighlightStore.swift       # NEW: Storage abstraction
└── Platform/
    └── CrossPlatform.swift        # UIKit/AppKit type aliases
```

### Key Abstraction: `HighlightStore` Protocol

```swift
/// Protocol for highlight persistence - implement this to connect your data layer
@MainActor
public protocol HighlightStore: ObservableObject {
    /// Current highlights for the document
    var highlights: [DHTextHighlight] { get }

    /// Add a new highlight
    func add(range: NSRange, color: PlatformColor, in text: NSAttributedString)

    /// Remove highlights intersecting a range
    func remove(intersecting range: NSRange)

    /// Remove a specific highlight by ID
    func remove(id: UUID)

    /// Get a specific highlight
    func highlight(id: UUID) -> DHTextHighlight?
}
```

### Updated DHTextView Interface

```swift
public struct DHTextView<Store: HighlightStore>: UIViewRepresentable {
    // Inputs
    public let attributedText: NSAttributedString
    public let style: DHStyle
    @ObservedObject var store: Store

    // Callbacks
    public var onTapLink: ((URL) -> Void)?
    public var onTapHighlight: ((DHTextHighlight) -> Void)?

    // Scroll control
    @Binding public var scrollTarget: NSRange?

    // Layout options
    public var availableWidth: CGFloat?
    public var usePageLayout: Bool = false
}
```

---

## Implementation Steps

### Phase 1: Create Package Structure
1. Create `Packages/DHTextView` directory
2. Add `Package.swift` manifest
3. Set up source directory structure

### Phase 2: Extract Core Models
1. Move `DHTextHighlight`, `DHLinkSpan`, `DHIndentSpan`, `DHHeadingSpan` → `Models/`
2. Move `DHStyle` → `Models/`
3. Move `DHConfig` → `Configuration/`
4. Add `public` access modifiers

### Phase 3: Create HighlightStore Protocol
1. Define `HighlightStore` protocol in `Protocols/`
2. Update `DHTextView` to accept generic `Store: HighlightStore`
3. Remove hardcoded callback closures, use store methods directly

### Phase 4: Extract Composition & Views
1. Move `DHComposer.swift` → `Composition/`
2. Move `DHTextView.swift` → `Views/`
3. Move `CrossPlatform.swift` → `Platform/`
4. Add `public` access modifiers to all public API

### Phase 5: Update Main App
1. Add local package dependency to Xcode project
2. Create app-specific `HighlightStore` implementation that wraps `HighlightsManager`
3. Update `DocHighlightingView` to use the package
4. Remove duplicated files from main target

### Phase 6: Clean Up Default Detectors
1. Keep EU legal document detectors as **examples** in package
2. Document how to provide custom detectors
3. Consider moving app-specific patterns to main app

---

## API Design Decisions

### 1. Detection Rules (Already Pluggable)
```swift
// Users provide their own detectors
let config = DHConfig(
    linkDetector: { text in /* custom pattern matching */ },
    indentationComputer: { text in /* custom indentation */ },
    headingDetector: { text in /* custom heading detection */ }
)
```

### 2. Color Palette
Package provides default highlight colors, but users can customize:
```swift
public extension DHTextHighlight {
    static let defaultColors: [PlatformColor] = [
        .systemYellow, .systemGreen, .systemBlue, .systemPink, .systemOrange
    ]
}
```

### 3. Convenience Initializers
Provide simple initializers for common cases:
```swift
// Simple usage with inline store
DHTextView(text: attributedString, store: myStore)

// Full customization
DHTextView(
    attributedText: attributedString,
    style: customStyle,
    store: myStore,
    onTapLink: { url in ... }
)
```

---

## Usage Example (After Packaging)

```swift
import DHTextView

// 1. Implement HighlightStore for your data layer
@MainActor
final class MyHighlightStore: HighlightStore {
    @Published var highlights: [DHTextHighlight] = []

    func add(range: NSRange, color: PlatformColor, in text: NSAttributedString) {
        let highlight = DHTextHighlight(range: range, color: color)
        highlights.append(highlight)
        // Save to your database...
    }

    func remove(intersecting range: NSRange) {
        highlights.removeAll { NSIntersectionRange($0.range, range).length > 0 }
    }

    func remove(id: UUID) {
        highlights.removeAll { $0.id == id }
    }

    func highlight(id: UUID) -> DHTextHighlight? {
        highlights.first { $0.id == id }
    }
}

// 2. Use in SwiftUI
struct DocumentView: View {
    let content: NSAttributedString
    @StateObject private var store = MyHighlightStore()

    var body: some View {
        DHTextView(attributedText: content, store: store)
    }
}
```

---

## Files Remaining in Main App

After extraction, these stay in the app:
- `DocHighlightingView.swift` - App-specific toolbar/sheets integration
- `DHViewModel.swift` - Becomes the app's `HighlightStore` implementation
- `HighlightsManager.swift` - App's persistence layer (GRDB)
- `DBHighlight.swift` - App's database model
- `TextHighlight.swift` - App-specific UI components (DHHighlightList)

---

## Open Questions

1. **Package name**: `DHTextView` vs `HighlightedTextView` vs `TextHighlighter`?
2. **macOS support**: Should we include NSTextView wrapper in v1?
3. **Composition API**: Keep as static function or make it a builder pattern?
4. **Default detectors**: Include EU legal patterns as examples or remove entirely?

---

## Success Criteria

- [ ] Package compiles independently with no app dependencies
- [ ] Main app works identically after migration
- [ ] New project can use package with custom `HighlightStore`
- [ ] All public API is documented
- [ ] Unit tests for `DHComposer` and model serialization
