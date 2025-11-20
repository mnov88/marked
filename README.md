# markdowned

A native iOS document reader and highlighter with advanced theming, URL import, and EU legal case search. Built with SwiftUI and UIKit.

## Features

### 📄 Document Management
- **SQLite-backed documents** via GRDB with default seed content
- **URL import**: Fetch HTML from any URL, convert to plain text
- **EU legal case search**: Built-in database of ~4MB CSV with searchable case records
- **Document list**: View all loaded documents with navigation

### 🖍️ Text Highlighting
- **Interactive text selection** with long-press menu
- **5 highlight colors**: Yellow, Green, Blue, Pink, Purple (semi-transparent overlays)
- **Highlight list**: View, navigate to, and delete highlights
- **Smooth scrolling**: Animated scroll-to-highlight with 0.3s ease-in-out
- **Persistent per-document**: Highlights maintained with document model

### 🎨 Advanced Theming
- **6 preset themes**: System (adaptive), Light, Dark, Sepia, High Contrast, Custom
- **System appearance**: Automatic light/dark mode adaptation using `.systemBackground` and `.label`
- **Custom theme builder**:
  - Font picker with all system fonts (100+)
  - Font size adjustment (12-24pt)
  - Line height control (1.0-2.0x)
  - System or custom background color
  - System or custom text color
- **Live preview**: See all theme changes in real-time
- **UserDefaults persistence**: All theme settings saved automatically

### 📐 Layout Options
- **Page-like appearance**: Optional constrained width (800pt max) with centered text
- **Responsive design**: Adapts to iPhone, iPad, and Mac Catalyst
- **Smooth scrolling**: All text rendered in native UITextView for optimal performance

### 🔗 Smart Content Loading
- **HTML to plain text**: Native NSAttributedString HTML parsing
- **Post-processing**: Regex-based cleanup of orphaned list markers
- **Paragraph spacing**: Automatic standardization for readability
- **Title extraction**: Intelligent title parsing from HTML `<title>` tags
- **Custom User-Agent**: Proper HTTP headers for reliable content fetching
- **Redirect handling**: Automatic following of HTTP redirects

### 🔍 EU Legal Case Search
- **4MB CSV database**: Thousands of EU legal cases included in app bundle
- **Searchable fields**: Case number, title, CELEX identifier
- **Direct loading**: Tap search result to fetch and display full case text
- **Publications.europa.eu integration**: Automatic URL construction from CELEX IDs
- **Optimized loading**: CSV parsed once on first view, cached for instant navigation

## Architecture

### Core Components

**DocHighlightingView** - Main document viewer
- Displays attributed text with highlights overlaid
- Manages highlight creation/deletion
- Handles link detection and tapping
- Provides highlight list sheet

**DHTextView** - UITextView bridge (UIViewRepresentable)
- Native UITextView for optimal text rendering
- Edit menu customization for highlight creation
- Smooth animated scrolling to highlights
- Page layout support with width constraints

**DHComposer** - Attributed string composition
- Combines base content, links, indentation, and highlights
- Applies paragraph styles (line height, spacing, alignment)
- Overlays semi-transparent highlight backgrounds
- Efficient re-composition on state changes

**ThemeManager** - Theme state management (@Observable)
- Current theme selection (preset or custom)
- Custom theme configuration
- Page layout preference
- UserDefaults persistence

### Data Models

**Document** (In-memory)
```swift
struct Document: Identifiable {
    let id: UUID
    let title: String
    let content: Content  // .plain(String) or .attributed(NSAttributedString)
    let sourceURL: URL?
}
```

**DHTextHighlight**
```swift
struct DHTextHighlight: Identifiable {
    let id: UUID
    let range: NSRange
    let color: UIColor
}
```

**Theme**
```swift
struct Theme: Codable {
    var fontName: String
    var fontSize: CGFloat
    var backgroundColorHex: String
    var textColorHex: String
    var lineHeightMultiple: CGFloat
    var usePageLayout: Bool
    var useSystemBackground: Bool
    var useSystemTextColor: Bool
}
```

**Case** (EU Legal Cases)
```swift
struct Case: Identifiable {
    let caseNumber: String
    let caseTitle: String
    let judgmentCELEX: String
    // ... additional metadata
}
```

### Services

**ContentLoader** - URL fetching and HTML conversion
- Fetches content via URLSession with proper headers
- Parses HTML to NSAttributedString natively
- Post-processes text for clean formatting
- Extracts titles from HTML

**CaseDataParser** - CSV parsing
- Loads EU legal case database from bundle
- Parses CSV into structured Case objects
- Optimized for one-time loading

### UI Components

**MockDocList** - Document list with search
- Tab-based interface (Documents / Settings)
- Searchable case database with live filtering
- URL entry sheet for web imports
- Navigation to document reader

**SettingsView** - Theme customization
- Theme picker (System, presets, custom)
- Font selection with system font browser
- Color pickers with system color toggles
- Line height and page layout controls
- Live theme preview

**URLEntryView** - URL import sheet
- URL text field with validation
- Loading indicator during fetch
- Error handling with alerts
- Default URL pre-filled

**FontPickerView** - System font browser
- All system fonts with live preview
- Searchable font list
- Each font displayed in its own typeface

## Technical Details

### Text Rendering Pipeline

1. **Content Input**: Plain string or NSAttributedString
2. **Link Detection**: Regex-based article reference detection (`Article \d+`)
3. **Indentation**: Multi-level list indentation based on markers
4. **Composition**: Combine base content + links + indents in DHComposer
5. **Highlighting**: Overlay semi-transparent backgrounds on character ranges
6. **Display**: Render in UITextView with theme styling

### Highlight System

Highlights are stored in SQLite as character ranges (NSRange) with colors:
- **Creation**: Long-press text → Select "Highlight [Color]" from menu
- **Storage**: Persisted per-document via GRDB; mirrored in-memory for UI responsiveness
- **Rendering**: Semi-transparent (0.25 alpha) background color overlay
- **Navigation**: Tap in highlight list → Smooth scroll to range
- **Deletion**: Swipe-to-delete in highlight list or "Remove Highlight" menu

### Theme System

**DHStyle** (UI Configuration)
```swift
struct DHStyle {
    var font: UIFont
    var textColor: UIColor
    var backgroundColor: UIColor
    var lineHeightMultiple: CGFloat
    var paragraphSpacing: CGFloat
    var contentInsets: UIEdgeInsets
}
```

Themes convert to DHStyle for rendering. System colors use iOS semantic colors:
- `.systemBackground` → Adapts to light/dark mode automatically
- `.label` → Primary text color that adapts

### Page Layout Implementation

When enabled:
```swift
HStack {
    Spacer()
    DHTextView(...).frame(maxWidth: 800)
    Spacer()
}
```

Constrains text width to 800pt, centers with spacers. Scrollbar appears next to text container.

### URL Import Flow

1. User enters URL in URLEntryView
2. ContentLoader.loadContent() fetches HTML with custom headers
3. HTML converted to NSAttributedString via NSAttributedString(data:options:)
4. Plain text extracted and post-processed
5. Title extracted from `<title>` tag
6. Document created and added to list

### Post-Processing

Cleans up HTML conversion artifacts:
- Merges orphaned list markers (numbers, letters, bullets on separate lines)
- Standardizes paragraph spacing (double newline between paragraphs)
- ~30 regex patterns for comprehensive cleanup

## Requirements

- **iOS 17.0+** (uses @Observable macro)
- **Xcode 15.0+**
- **Swift 5.9+**
- **Mac Catalyst compatible** (Stepper instead of Slider for font size)

## Dependencies

Managed via Swift Package Manager (Package.swift):

- **GRDB** - SQLite persistence for documents and highlights
- **Ink** - Markdown parsing (currently not used, legacy dependency)
- **SwiftSoup** - HTML parsing (currently not used, legacy dependency)  
- **Markdown** - Apple's swift-markdown (currently not used, legacy dependency)
- **ZIPFoundation** - ZIP handling (currently not used, legacy dependency)

**Note**: GRDB is active for persistence; the other listed packages are currently unused placeholders and can be removed when convenient.

## Project Structure

```
markdowned/
├── markdownedApp.swift          # App entry point with TabView
├── DocHighlightingView.swift    # Main document viewer
├── DHTextView.swift             # UITextView wrapper
├── DHTextHighlight.swift        # Highlight, link, indent models + DHConfig
├── DHViewModel.swift            # Highlight state management
├── DHComposer.swift             # Attributed string composition
├── TextHighlight.swift          # MockDocList + highlight list UI
├── Utilities.swift              # UIColor extensions, lorem generator
├── TestStrings.swift            # Mock document content
├── Document.swift               # Document model
├── ContentLoader.swift          # URL fetching + HTML conversion
├── URLEntryView.swift           # URL import UI
├── Case.swift                   # EU legal case model
├── CaseDataParser.swift         # CSV parsing
├── Theme.swift                  # Theme model + presets
├── ThemeManager.swift           # Theme state + UserDefaults
├── SettingsView.swift           # Settings UI + font picker
├── allcases.csv                 # EU legal cases database (~4MB)
├── Info.plist                   # App Transport Security config
├── Assets.xcassets/             # App icons and colors
└── Readme.md                    # This file
```

## Installation

1. **Clone the repository**:
```bash
git clone <repository-url>
cd markdowned
```

2. **Open in Xcode**:
```bash
open markdowned.xcodeproj
```

3. **Build and run** (⌘R)

Dependencies resolve automatically via Swift Package Manager.

## Usage

### Viewing Documents

1. Launch app → **Documents** tab
2. Tap any mock document to view
3. Scroll to read
4. Long-press text → Select highlight color to create highlight
5. Tap **Highlights** button → View/navigate/delete highlights

### Importing from URL

1. **Documents** tab → Tap **+** button
2. Enter URL (default: GDPR regulation)
3. Tap **Load Content**
4. Content fetches, converts, and displays

### Searching EU Legal Cases

1. **Documents** tab → Use search bar
2. Type case number, title, or CELEX ID
3. Tap search result
4. Case loads from publications.europa.eu

### Customizing Themes

1. **Settings** tab
2. **Theme Selection**: Choose preset or Custom
3. **Custom Theme** (if selected):
   - Tap **Font** → Browse all system fonts
   - **Font Size**: Stepper to adjust 12-24pt
   - **Line Height**: Stepper to adjust 1.0-2.0x
   - **Background/Text Colors**: Toggle system colors or pick custom
4. **Layout**:
   - Enable **Page-like Appearance** for centered 800pt width
5. Changes apply immediately to all documents

### Theme Presets

- **System**: Adapts to iOS light/dark mode automatically
- **Light**: White background, black text
- **Dark**: Dark gray background, white text
- **Sepia**: Warm beige background, brown text
- **High Contrast**: Black background, yellow text (18pt)

## Performance Optimizations

- **CSV loading**: Parsed once on first appearance, cached in memory
- **Highlight rendering**: Semi-transparent overlays, no text duplication
- **Theme switching**: Instant re-render with cached attributed strings
- **Smooth scrolling**: UIView.animate for 0.3s scroll-to-highlight
- **Text layout**: Native UITextView with optimized text container sizing

## Known Limitations

- **Local-only persistence**: SQLite is sandboxed; no sync/backup yet
- **No editing**: Read-only document viewer
- **HTTP only for publications.europa.eu**: App Transport Security exception required
- **Case search**: Requires allcases.csv in bundle (~4MB)
- **System fonts**: Font picker only shows fonts available on current device

## Future Enhancements

### High Priority
- **CoreData/SwiftData**: Persistent storage for documents and highlights
- **Document editing**: Rich text editor with markdown support
- **Export**: PDF/HTML export with highlights preserved
- **iCloud sync**: Cross-device document synchronization
- **Search**: Full-text search within documents

### Nice to Have
- **Folders/Tags**: Document organization
- **Annotations**: Notes attached to highlights
- **Sharing**: Share documents and highlights
- **Dark mode themes**: More theme variants
- **Font rendering**: Support for custom font files
- **Backup/Restore**: Import/export app data

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Follow existing SwiftUI/UIKit patterns
4. Test on iPhone and iPad
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open Pull Request

## License

[Add your license here]

## Acknowledgments

- Built with **SwiftUI** and **UIKit**
- EU legal case data from **publications.europa.eu**
- Inspired by document annotation tools like PDF Expert and Liquid Text

---

**Platform**: iOS 17+ • iPhone • iPad • Mac Catalyst
