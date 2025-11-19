# Markdowned

A native iOS markdown document viewer with rich rendering and theming support. Built entirely with SwiftUI and SwiftData.

**Current Status:** Core viewing and theming functionality is working. Advanced features (URL import, highlighting, export) are implemented in code but not yet connected to the UI.

## Features

### Currently Implemented
- **📄 File Import**: Import markdown/text files from device
- **🎨 Theming System**: 5 built-in themes with live theme switching
- **📖 Markdown Rendering**: Rich markdown display with Apple's swift-markdown
- **💾 SwiftData Storage**: Persistent local storage
- **🗑️ Document Management**: List, view, delete documents

### Implemented in Code, Not in UI Yet
- **🔗 URL Import**: `URLImportService` can fetch and convert web pages to markdown
- **📋 Paste Import**: `DocumentService` supports pasting markdown content
- **🖍️ Text Highlighting**: Full highlight system exists but no UI to create/manage highlights
- **📤 Export**: HTML and PDF generation ready but no export buttons
- **📊 Statistics**: Word count, reading time calculations available but not displayed

## Architecture

This app follows clean architecture principles with a clear separation of concerns:

### Data Layer

**Models** (SwiftData)
- `Document`: Core document model with metadata (name, content, size, source, dates)
- `Highlight`: Text highlight annotations with color, range, and text
- `Theme`: Theme configuration (fonts, colors, spacing)
- `HighlightColor`: Color definitions (sun, mint, lavender, coral)

**Repositories** (Repository Pattern)
- `DocumentRepository`: Data access for documents (CRUD, search, filtering)
- `HighlightRepository`: Data access for highlights (CRUD, grouping, validation)

### Business Logic Layer

**Services**
- `DocumentService`: Document operations (import, validation, duplicate detection)
- `HighlightService`: Highlight management (create, navigation, batch operations)
- `URLImportService`: URL fetching, HTML cleaning, HTML-to-Markdown conversion
- `ExportService`: HTML and PDF export with theming

### Presentation Layer

**ViewModels**
- `DocumentViewModel`: Document reading state, rendering, highlights, exports
- `DocumentListViewModel`: Document list state and operations

**Renderers**
- `MarkdownRenderer`: Converts markdown to NSAttributedString using Apple's swift-markdown
- `HTMLBuilder`: Generates HTML with embedded CSS for exports
- `PDFGenerator`: Creates PDFs with proper pagination and styling

### Extensions
- `Color+Extensions.swift`: UIColor/Color conversion helpers
- `Date+Extensions.swift`: Date formatting utilities
- `String+Extensions.swift`: String manipulation (sanitization, markdown extensions)

## Technical Details

### Markdown Parsing

Uses **Ink** markdown parser by John Sundell for fast and flexible markdown parsing. 

**Rendering Pipeline:**
1. Markdown → HTML (via Ink's `MarkdownParser`)
2. HTML + Theme CSS → Styled HTML document
3. Styled HTML → `NSAttributedString` (via `NSAttributedString(data:options:)`)
4. Apply highlights as background colors on character ranges

This approach provides excellent theme control through CSS while maintaining native iOS rendering performance.

Supported markdown features (via Ink):
- Headings (H1-H6)
- Emphasis (bold, italic, strikethrough)
- Links and images (including reference-style)
- Inline and block code
- Lists (ordered and unordered, nested)
- Blockquotes
- Horizontal rules
- Tables
- Inline HTML

### HTML Import

Uses **SwiftSoup** for HTML parsing when importing from URLs:
1. Fetches HTML content with custom User-Agent
2. Extracts title from multiple sources (title tag, Open Graph, h1)
3. Cleans HTML (removes scripts, styles, navigation elements)
4. Extracts main content (tries `<main>`, `<article>`, `[role=main]`, then `<body>`)
5. Converts HTML to markdown with custom element converter

### Document Storage

Documents have a 10MB size limit and include:
- `id`: Unique identifier (UUID)
- `name`: Filename with markdown extension
- `content`: Raw markdown text
- `size`: Byte count
- `source`: Import source ("upload", "url", "paste", "icloud")
- `sourceUrl`: Original URL (if from web)
- `createdAt`: Creation timestamp
- `modifiedAt`: Last modification timestamp
- `highlights`: Related highlight annotations (cascade delete)

### Highlight System

Highlights store character offsets (`rangeStart`, `rangeEnd`) for text selection:
- 4 predefined colors with specific RGBA values
- Text extraction for display
- Overlap detection and validation
- Navigation (next/previous highlight)
- Batch operations (merge adjacent, update colors)
- Export support for HTML/PDF

### Theme System

Themes define complete styling:
- Font family and size
- Line height and spacing
- Text, background, link colors
- Heading scale factor
- Code font and background color
- CSS generation for HTML export

5 preset themes available:
- **Professional**: Georgia serif, traditional
- **Modern**: System font, sky blue
- **Minimal**: Large base size, neutral grays
- **Academic**: Times New Roman, double-spaced
- **Creative**: Purple accent, large headings

Custom themes can be created and saved via UserDefaults.

### Export Features

**HTML Export:**
- Embedded CSS from theme
- Highlight markup with class-based styling
- Document metadata in footer
- Print-friendly styles
- Multi-document export with separators

**PDF Export:**
- Page sizes: A4, Letter, Legal
- Automatic pagination with CTFramesetter
- Headers with document title
- Footers with page numbers
- Multi-document support with separator pages
- 2cm margins (56.7 points)

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Dependencies

Managed via Swift Package Manager:

- **Ink**: Fast and flexible markdown parser by John Sundell
- **SwiftSoup**: HTML parsing and cleaning for URL imports
- **ZIPFoundation**: Listed in Package.swift but NOT currently used in the code

## Project Structure

All files are in a flat structure in the `markdowned/` directory:

```
markdowned/
├── Assets.xcassets/                # App icons and colors
├── Color+Extensions.swift          # Color utilities
├── Date+Extensions.swift           # Date formatting
├── Document.swift                  # Document model + validation
├── DocumentListViewModel.swift     # List view model
├── DocumentRepository.swift        # Document data access
├── DocumentService.swift           # Document business logic
├── DocumentViewModel.swift         # Document detail view model
├── Highlight.swift                 # Highlight model + helpers
├── HighlightColor.swift            # Color definitions
├── HighlightRepository.swift       # Highlight data access
├── HighlightService.swift          # Highlight operations
├── HTMLBuilder.swift               # HTML generation + export
├── MarkdownRenderer.swift          # Markdown → AttributedString
├── MarkdownStudioApp.swift         # Main app + AppState + ContentView
├── markdownedApp.swift             # Original simple app entry point
├── Package.swift                   # (empty file)
├── PDFGenerator.swift              # PDF creation
├── String+Extensions.swift         # String helpers
├── Theme.swift                     # Theme config + presets
└── URLImportService.swift          # URL fetching + conversion
```

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd markdowned
```

2. Open in Xcode:
```bash
open markdowned.xcodeproj
```

3. Dependencies are managed automatically via Swift Package Manager
4. Build and run (⌘R)

## Usage

### Importing Documents

**Currently in UI:**
1. Tap + button → "Import Options"
2. Only "Import Files" is implemented in the UI
3. Choose markdown/text files (.txt, .md, .markdown)
4. Files are validated and imported

**Available in Code but NOT in UI:**
- URL import functionality exists in `URLImportService` but no UI button
- Paste import exists in `DocumentService.importFromPaste()` but no UI
- iCloud source type is defined but no import UI

**Note:** The underlying services support URL fetching, HTML-to-markdown conversion, and paste import, but these features are not connected to the user interface yet.

### Viewing Documents

1. Select document from list (sorted by creation date, newest first)
2. Document renders with selected theme
3. Scroll to read rendered markdown
4. Tap theme button in toolbar to select from 5 preset themes
5. Theme changes apply immediately and re-render the document

### Highlighting Text

**Currently:** Highlights are fetched from the database and rendered if they exist, but there is NO UI for creating, editing, or managing highlights yet.

**Available in Code:**
- `HighlightService` with full CRUD operations
- `DocumentViewModel` with highlight creation/deletion methods  
- Color selection and navigation logic
- 4 highlight colors defined (Sun, Mint, Lavender, Coral)

**Not Yet Implemented in UI:**
- Text selection to create highlights
- Color picker for highlights
- Highlight list view
- Edit/delete highlight controls
- Navigation between highlights

### Exporting

**Currently:** NO export UI is implemented.

**Available in Code:**
- `ExportService` with HTML and PDF generation
- `HTMLBuilder` creates complete HTML documents with embedded CSS
- `PDFGenerator` creates paginated PDFs (A4/Letter/Legal page sizes)
- Multi-document export support
- All highlights are included in exports

**Not Yet Implemented in UI:**
- Export menu/buttons
- Share sheet integration
- Page size selection
- File save dialog

## Architecture Patterns

- **Repository Pattern**: Abstracts data access from business logic
- **Service Layer**: Encapsulates business rules and operations
- **MVVM**: ViewModels manage state and coordinate between services and views
- **Dependency Injection**: Services receive repository protocols, not implementations
- **Protocol-Oriented**: Repositories use protocols for testability
- **SwiftData**: Modern data persistence with `@Model` macro
- **Observation Framework**: State management with `@Observable` macro (iOS 17+)

## Error Handling

Custom error types for each layer:
- `DocumentError`: Invalid name, empty content, file too large, access denied, invalid format
- `HighlightError`: Invalid range, text extraction failed, update failed
- `URLImportError`: Invalid URL, fetch failed, decoding failed, parsing failed, conversion failed
- `ExportError`: PDF generation failed, HTML generation failed, save failed

## Performance Considerations

- Markdown rendering is optimized with visitor pattern over AST
- Highlights use character offsets for efficient range operations
- Documents are lazy-loaded via SwiftData fetch descriptors
- PDF generation uses CoreText's CTFramesetter for efficient pagination
- HTML export minimizes DOM manipulation

## Future Enhancements

### High Priority (Code exists, needs UI)
- Connect URL import UI to existing `URLImportService`
- Add paste import button for `DocumentService.importFromPaste()`
- Build highlight creation/management UI for existing `HighlightService`
- Add export menu to use existing `ExportService`
- Display statistics (word count, reading time) that are already calculated

### New Features to Build
- Document editing capabilities (currently read-only)
- iCloud sync
- Search within document content
- Tags and folders organization
- Markdown preview while editing
- Dark mode theme variants
- Accessibility improvements
- Collaborative features

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow existing code style and patterns
4. Write tests for new functionality
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

[Add your license here]

## Acknowledgments

- Built with SwiftUI and SwiftData
- Markdown parsing by [Ink](https://github.com/JohnSundell/Ink) by John Sundell
- HTML parsing by [SwiftSoup](https://github.com/scinfu/SwiftSoup)
- ZIP compression by [ZIPFoundation](https://github.com/weichsel/ZIPFoundation)
- Inspired by modern document readers and annotation tools

---

**Note**: This app is iOS-only and uses the latest SwiftUI/SwiftData features requiring iOS 17+. For web counterpart or older iOS versions, additional implementation would be required.
