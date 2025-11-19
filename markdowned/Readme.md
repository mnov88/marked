#  DocHighlighter


SwiftUI + UITextView component for large legal-style documents with:

* tappable “Article N” links using a safe custom URL scheme
* multi-level indentation for numbered, lettered, roman, and bullet lists
* interactive text highlights via the system edit menu
* skimmable sidebar list of highlights with jump-to

iOS 18+, Swift 5.10. TextKit 1 APIs through `UITextView`.

---

## Contents

* [Why this exists](#why-this-exists)
* [Requirements](#requirements)
* [Installation](#installation)
* [Quick start](#quick-start)
* [Public API](#public-api)

  * [`DocHighlightingView`](#dochighlightingview)
  * [`DHConfig` and rules](#dhconfig-and-rules)
  * [`DHStyle`](#dhstyle)
  * [Models](#models)
* [Customization examples](#customization-examples)

  * [Link detection for multiple locales](#link-detection-for-multiple-locales)
  * [Custom indentation levels](#custom-indentation-levels)
  * [Styling and layout](#styling-and-layout)
  * [Handling link taps](#handling-link-taps)
  * [Changing the highlight palette or menu](#changing-the-highlight-palette-or-menu)
* [Performance](#performance)
* [Accessibility](#accessibility)
* [Internationalization](#internationalization)
* [Testing suggestions](#testing-suggestions)
* [Troubleshooting](#troubleshooting)
* [Versioning and stability](#versioning-and-stability)
* [License](#license)

---

## Why this exists

Legal and regulatory texts are long and hierarchical. This component renders them efficiently, creates safe in-text links like “Article 5,” indents list levels, and lets users mark and revisit passages.

---

## Requirements

* iOS 18 or later
* Swift 5.10+
* SwiftUI

---

## Installation

### Swift Package Manager

1. In Xcode: **File → Add Package Dependencies…**
2. Enter your repo URL.
3. Add the **DocHighlighter** product to your app target.

---

## Quick start

```swift
import SwiftUI

struct ContentView: View {
    private let text = """
    Article 3

    1. Providers shall...
    (a) Conditions apply.
    (i) Sub-point.
    • Bullet one.
    See Article 2.
    """

    var body: some View {
        DocHighlightingView(string: text,
                            config: DHConfig()) { url in
            // Custom URL scheme: dh://article/<n>
            guard url.scheme == "dh", url.host == "article",
                  let n = Int(url.lastPathComponent) else { return }
            // Navigate to your Article screen
            print("Open article:", n)
        }
        .navigationTitle("Document")
    }
}
```

What users get:

* tap “Article n” to trigger your `onLinkTap`
* select text to add or remove a highlight
* open the bottom toolbar → **Highlights** to skim and jump

---

## Public API

### `DocHighlightingView`

```swift
DocHighlightingView(
    string: String,
    config: DHConfig = DHConfig(),
    onLinkTap: @escaping (URL) -> Void = { _ in }
)

DocHighlightingView(
    attributedString: NSAttributedString,
    config: DHConfig = DHConfig(),
    onLinkTap: @escaping (URL) -> Void = { _ in }
)
```

* `string` or `attributedString`: immutable base content
* `config`: styling and rule providers
* `onLinkTap`: receives URLs for `.link` ranges, using `dh://article/<n>` by default

> Note: Initial programmatic highlights are not exposed yet. Users add highlights via the selection menu. See [Versioning and stability](#versioning-and-stability).

---

### `DHConfig` and rules

```swift
struct DHConfig {
    var style: DHStyle = .init()
    var enableLinks: Bool = true
    var enableIndentation: Bool = true

    var linkDetector: ((NSString) -> [DHLinkSpan])? = DHConfig.defaultArticleLinks
    var indentationComputer: ((NSString) -> [DHIndentSpan])? = DHConfig.defaultIndentation
}
```

* `linkDetector`: map the plain text to `[DHLinkSpan]` ranges with custom URLs
* `indentationComputer`: map paragraphs to `[DHIndentSpan]` with head/tail indents
* Both are computed once from the base text and cached for performance

---

### `DHStyle`

```swift
struct DHStyle {
    var font: UIFont = .preferredFont(forTextStyle: .body)
    var textColor: UIColor = .label
    var backgroundColor: UIColor = .systemBackground
    var lineHeightMultiple: CGFloat = 1.2
    var paragraphSpacing: CGFloat = 4
    var alignment: NSTextAlignment = .left
    var contentInsets: UIEdgeInsets = .init(top: 24, left: 16, bottom: 24, right: 16)
    var lineBreakStrategy: NSParagraphStyle.LineBreakStrategy = [.hangulWordPriority, .pushOut]
}
```

Applied as a base paragraph style across the document. Existing attributes in an attributed input are retained unless overwritten by the base style.

---

### Models

```swift
struct DHTextHighlight: Identifiable, Equatable {
    let id: UUID
    let range: NSRange
    let color: UIColor
}

struct DHLinkSpan: Identifiable, Equatable {
    let id: UUID
    let range: NSRange
    let url: URL // use .link with a custom scheme
}

struct DHIndentSpan: Identifiable, Equatable {
    let id: UUID
    let range: NSRange
    let headIndent: CGFloat
    let tailIndent: CGFloat
    let firstLineHeadIndent: CGFloat
}
```

---

## Customization examples

### Link detection for multiple locales

Add “Art.” and localized forms, and preserve default behavior:

```swift
var cfg = DHConfig()
cfg.linkDetector = { s in
    var spans: [DHLinkSpan] = []

    func matches(_ pattern: String) -> [DHLinkSpan] {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return [] }
        let full = NSRange(location: 0, length: s.length)
        return re.matches(in: s as String, range: full).compactMap { m in
            let n = (s.substring(with: m.range(at: 1)) as NSString).integerValue
            guard let url = URL(string: "dh://article/\(n)") else { return nil }
            return DHLinkSpan(id: UUID(), range: m.range, url: url)
        }
    }

    spans += matches(#"\bArticle\s+(\d+)\b"#)   // English
    spans += matches(#"\bArt\.\s*(\d+)\b"#)     // Abbrev.
    spans += matches(#"\bČlanak\s+(\d+)\b"#)    // Example locale

    // Optional: de-duplicate overlapping ranges
    spans.sort { $0.range.location < $1.range.location }
    return spans
}
```

### Custom indentation levels

Support `(1)` style numeric sublevels:

```swift
cfg.indentationComputer = { s in
    var spans: [DHIndentSpan] = []
    let base: CGFloat = 20

    let reLevel0 = try? NSRegularExpression(pattern: #"^\s*\d+\."#, options: [.anchorsMatchLines])
    let reLevel1 = try? NSRegularExpression(pattern: #"^\s*\([a-zA-Z]\)"#, options: [.anchorsMatchLines])
    let reLevel2 = try? NSRegularExpression(pattern: #"^\s*\([ivxlcdmIVXLCDM]+\)"#, options: [.anchorsMatchLines])
    let reLevel3 = try? NSRegularExpression(pattern: #"^\s*\(\d+\)"#, options: [.anchorsMatchLines])
    let reBullet = try? NSRegularExpression(pattern: #"^\s*[•\-\–\—]"#, options: [.anchorsMatchLines])

    for pr in s.paragraphRanges() {
        let p = s.substring(with: pr)
        let level: Int =
            reLevel0?.firstMatch(in: p, range: NSRange(location: 0, length: (p as NSString).length)) != nil ? 0 :
            reLevel1?.firstMatch(in: p, range: NSRange(location: 0, length: (p as NSString).length)) != nil ? 1 :
            reLevel2?.firstMatch(in: p, range: NSRange(location: 0, length: (p as NSString).length)) != nil ? 2 :
            reLevel3?.firstMatch(in: p, range: NSRange(location: 0, length: (p as NSString).length)) != nil ? 3 :
            reBullet?.firstMatch(in: p, range: NSRange(location: 0, length: (p as NSString).length)) != nil ? 3 : 0

        let indent = CGFloat(level + 1) * base
        spans.append(DHIndentSpan(id: UUID(),
                                  range: pr,
                                  headIndent: indent,
                                  tailIndent: -indent,
                                  firstLineHeadIndent: indent))
    }
    return spans
}
```

### Styling and layout

```swift
var style = DHStyle()
style.font = .preferredFont(forTextStyle: .title3)       // larger base
style.textColor = .label
style.lineHeightMultiple = 1.25
style.paragraphSpacing = 6
style.contentInsets = .init(top: 24, left: 20, bottom: 40, right: 20)

var cfg = DHConfig()
cfg.style = style

DocHighlightingView(string: largeText, config: cfg) { url in /* ... */ }
```

### Handling link taps

The default detector emits `dh://article/<n>`. Example router:

```swift
DocHighlightingView(string: text) { url in
    guard url.scheme == "dh" else { return }
    switch url.host {
    case "article":
        if let n = Int(url.lastPathComponent) {
            // navigate to Article n
        }
    case "case":
        // e.g. dh://case/C-123_20
        let id = url.lastPathComponent
        // open case screen
    default:
        break
    }
}
```

Emit other link types by customizing `linkDetector` to set different hosts or paths.

### Changing the highlight palette or menu

The component shows a context menu for selected text. To change colors or add actions, edit the palette in `DHTextView.Coordinator.textView(_:editMenuForTextIn:)`.

Example: add an “Export quote” item:

```swift
// Inside editMenuForTextIn ...
let export = UIAction(title: "Export Quote", image: UIImage(systemName: "square.and.arrow.up")) { [weak textView] _ in
    guard let tv = textView else { return }
    let ns = tv.text as NSString
    let quoted = ns.substring(with: range)
    // share or copy
    UIPasteboard.general.string = "“\(quoted)”"
}
// Append to items
items.append(export)
return UIMenu(children: items)
```

---

## Performance

* The base text is immutable. Link and indentation spans are computed once and cached.
* The bridge avoids reassigning `attributedText` if contents have not changed. This preserves scroll position and reduces layout churn.
* For very large inputs, prefer `DocHighlightingView(attributedString:)` with minimal pre-applied attributes to reduce the delta.
* Highlights only add a background attribute, which is cheap and does not interfere with link underlines.
* Test with large lorem via `LoremGen.approximateCharacters(_:)`.

---

## Accessibility

* Uses Dynamic Type via `.preferredFont`. System colors adapt to light and dark modes.
* Links use the documented `.link` attribute so VoiceOver announces them as links.
* Highlight colors should be adjusted to meet contrast where needed. Replace palette entries if your theme requires higher contrast.
* Consider adding “Jump to next highlight” affordances in your chrome for keyboard users on iPad.

---

## Internationalization

* The default link detector matches “Article <n>”. Replace `linkDetector` with patterns for your locales, abbreviations, and plurals.
* Indentation rules are regex-based and independent of language. Extend the patterns to match your list markers.

---

## Testing suggestions

* Range currency: verify `DHHighlightList` renders correct snippets with emoji and combining marks.
* Overlaps: link ranges that overlap highlight ranges keep the link underline.
* Layout: dynamic type sizes, small screens, RTL alignment if applicable.
* Large docs: measure time to first render and scroll performance.
* Tap affordance: ensure single-tap activates your router and long-press still shows system menus.

---

## Troubleshooting

**Taps do nothing**
Ensure your `onLinkTap` checks the `dh` scheme and returns `false` in the delegate to suppress default navigation. This is already handled inside the component.

**Links underline the wrong text**
Check your `linkDetector` ranges. Return UTF-16 based `NSRange` values into the original `NSString`.

**Highlights appear but the list is empty**
Highlights are per-session state in the view model. Persist them externally if needed and re-apply by extending the API. See next section.

---

## Versioning and stability

* Public surface: `DocHighlightingView`, `DHConfig`, `DHStyle`, models.
* Not yet public: programmatic highlight injection, external scroll-to APIs. If you need these, expose a `Binding<[DHTextHighlight]>` and a `Binding<NSRange?>` in your fork, or open an issue.

---

## License

Choose a license that fits your project, e.g. MIT or Apache-2.0. Include it at the repo root as `LICENSE`.

---

### Appendix: Demo preview

The repo includes a simple preview with three mock documents that exercise headings, lists, and links. Use it to validate styling and interaction before wiring into navigation.
