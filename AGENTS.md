# Repository Guidelines

## Project Structure & Module Organization
- App code lives in `markdowned/` (SwiftUI/UIKit). Entry point `markdownedApp.swift`; core viewer/composer layers in `DocHighlightingView.swift`, `DHTextView.swift`, `DHComposer.swift`, and models such as `Document.swift`, `DHTextHighlight.swift`, `Theme.swift`.
- Data and assets: `allcases.csv` (EU case index), `Assets.xcassets`, `Info.plist`.
- Persistence design notes: `GRDB_PERSISTENCE_IMPLEMENTATION.md`.
- Tests: unit tests in `markdownedTests/`; UI tests in `markdownedUITests/`; shared fixtures in `TestStrings.swift`.
- Optional dataset tooling lives in `metadata-extraction-external/` (Python scripts and logs); avoid bundling outputs unless needed.
- SQLite persistence lives in `marked.sqlite` under the app sandbox; schema and migrations are defined in `DatabaseManager.swift` (GRDB).

## Build, Test, and Development Commands
- Open in Xcode: `open markdowned.xcodeproj` → select the `markdowned` scheme → run (⌘R) against an iPhone 15 simulator on iOS 18+.
- CLI build: `xcodebuild -project markdowned.xcodeproj -scheme markdowned -destination 'platform=iOS Simulator,name=iPhone 15' build`.
- CLI tests: `xcodebuild -project markdowned.xcodeproj -scheme markdowned -destination 'platform=iOS Simulator,name=iPhone 15' test`.
- Dependency resolution is handled by Xcode/SPM; rerun with `xcodebuild -resolvePackageDependencies` if a cache is stale.

## Persistence (GRDB)
- Use GRDB “Codable Records”: declare `Codable + FetchableRecord + PersistableRecord` with explicit `CodingKeys`; avoid manual `init(row:)` unless needed.
- Access the database only via `DatabaseQueue` in `DatabaseManager`; do not mark records `@unchecked Sendable` or import GRDB with `@preconcurrency`.
- Prefer `ValueObservation.publisher(in: dbQueue, scheduling: .immediate)` for UI-bound streams; keep writes wrapped in `db.write { ... }` and propagate errors instead of swallowing them.
- Don’t add global conformances to Foundation types (e.g., `UUID: Identifiable`); use wrappers where needed.

## Coding Style & Naming Conventions
- Swift 5.9, iOS 17 @Observable APIs; prefer structs and value semantics.
- 4-space indentation; keep imports minimal; prefer Swift concurrency for network or file I/O.
- Views end with `View`, view models with `ViewModel`, managers with `Manager`, data models singular (`Document`, `Case`).
- Keep UI-composition logic in `DHComposer`/`DocHighlightingView`; avoid re-implementing layout logic in views.
- Use Xcode’s built-in formatter; no repository lint tool is configured.

## Highlighting & Text Interaction (iOS 18+)
- No custom gesture recognizers on `UITextView`; use delegate hooks only.
- Menu for selected text is built in `DHTextView.Coordinator.textView(_:editMenuForTextIn:suggestedActions:)` and must return `nil` for zero-length ranges to avoid selection artifacts.
- Highlights are tagged with `.textItemTag` and handled through `primaryActionForTextItem`/`menuConfigurationForTextItem`; taps show a menu (remove/copy) instead of auto-deleting.
- Links still use `.link` and are forwarded to `onTapLink`; fallback delegate `shouldInteractWith URL` remains for legacy support.

## Testing Guidelines
- Unit tests use the `Testing` framework (`@Test` with `#expect`). Place new specs in `markdownedTests/`; prefer focused methods like `testHighlightRenderingPreservesRanges`.
- UI flows belong in `markdownedUITests/`; gate new screens with at least a launch-and-navigate smoke test.
- Reuse strings from `TestStrings.swift` or lightweight fixtures; avoid loading the full `allcases.csv` in unit tests.
- Run `xcodebuild ... test` before opening a PR; add regression coverage when touching highlighting, theme persistence, or document loading.

## Commit & Pull Request Guidelines
- Commit history favors short, imperative summaries (`Add comprehensive GRDB persistence`, `Fix tap gesture interference`). Match that style; keep body lines at 72 chars if present.
- Each PR should include: a concise description, linked issue (if any), simulator/device targets tested, and screenshots for UI changes.
- Note any data file changes (especially `allcases.csv`) and new dependencies. Call out known limitations or follow-up tasks in the PR description.
