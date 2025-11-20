# macOS Native Version - Migration Guide

This document describes the changes made to support a native macOS version of the Markdowned app.

## Overview

The app has been updated to support both iOS and macOS using conditional compilation. On iOS, it uses UIKit-based components and a tab-based navigation. On macOS, it uses AppKit-based components and a sidebar navigation pattern.

## Key Changes

### 1. Platform Abstraction Layer

**New File: `PlatformTypes.swift`**
- Provides type aliases for cross-platform compatibility:
  - `PlatformColor` → UIColor (iOS) / NSColor (macOS)
  - `PlatformFont` → UIFont (iOS) / NSFont (macOS)
  - `PlatformImage` → UIImage (iOS) / NSImage (macOS)
  - `PlatformEdgeInsets` → UIEdgeInsets (iOS) / NSEdgeInsets (macOS)
- Extensions for color conversion (hex strings)
- Platform-specific system colors (.platformSystemBackground, .platformLabel, .platformLink)

### 2. Text View Components

**New File: `DHTextViewMac.swift`**
- NSTextView wrapper for macOS (equivalent to DHTextView for iOS)
- Supports text highlighting with click-to-remove functionality
- Context menu for adding/removing highlights
- Link handling for custom URL schemes
- Smooth scrolling to highlight ranges

**Updated: `DHTextView.swift`**
- Wrapped in `#if canImport(UIKit) && !targetEnvironment(macCatalyst)` to only compile on iOS
- Updated to use PlatformColor instead of UIColor

### 3. Core Components Updated

**Updated: `DHTextHighlight.swift`**
- Changed color type from UIColor to PlatformColor
- Updated DHStyle to use platform-specific defaults
- Added conditional compilation for font and color initialization

**Updated: `DHComposer.swift`**
- Uses PlatformColor for link colors
- Works with both UIKit and AppKit attributed strings

**Updated: `Theme.swift`**
- Updated toDHStyle() to handle both UIFont/NSFont
- Uses platform-specific color conversions
- Supports both UIKit and AppKit edge insets

**Updated: `Utilities.swift`**
- Extended PlatformColor with rgba comparison helper
- Works with both UIColor and NSColor

**Updated: `DHViewModel.swift`**
- Uses PlatformColor in add() method

### 4. View Updates

**Updated: `DocHighlightingView.swift`**
- Added @ViewBuilder textView property that conditionally uses:
  - DHTextView on iOS
  - DHTextViewMac on macOS
- Updated background color to use Color(platformColor:)

**Updated: `SettingsView.swift`**
- Platform-specific font family enumeration:
  - UIFont.familyNames on iOS
  - NSFontManager.shared.availableFontFamilies on macOS
- Separate ThemePreviewView implementations:
  - UIViewRepresentable on iOS
  - NSViewRepresentable on macOS
- ColorPicker updated to use PlatformColor

**Updated: `markdownedApp.swift`**
- Separate root views for iOS and macOS:
  - **iOS**: TabView with Documents, Highlights, Settings tabs
  - **macOS**: NavigationSplitView with sidebar and detail view
- macOS-specific menu commands:
  - Preferences (Cmd+,)
  - Import from URL (Cmd+I)

### 5. Navigation Patterns

**iOS (TabView)**
- Bottom tab bar with 3 sections
- Standard iOS navigation patterns
- Sheets for modal presentations

**macOS (NavigationSplitView)**
- Left sidebar with navigation links
- Main detail area showing selected section
- Native macOS window management
- Keyboard shortcuts via menu commands

## Project Configuration Required

To complete the macOS migration, the following steps need to be done in Xcode:

### 1. Add New Files to Project

Add these files to the Xcode project:
- `PlatformTypes.swift`
- `DHTextViewMac.swift`
- `MACOS_MIGRATION.md` (this file)

### 2. Update Build Settings

In the Xcode project settings for the "markdowned" target:

1. Update **Supported Destinations**:
   - Add "Mac" to the list (currently only has iPhone, iPad, Mac Catalyst, Vision Pro)

2. Update **SUPPORTED_PLATFORMS**:
   - Change from: `"iphoneos iphonesimulator xros xrsimulator"`
   - To: `"iphoneos iphonesimulator macosx xros xrsimulator"`

3. Verify **Deployment Targets**:
   - iOS: 26.0 (already set)
   - macOS: 26.0 (already set)
   - Keep Mac Catalyst enabled if desired

### 3. Update Info.plist (if needed)

Ensure the Info.plist supports both platforms. May need to add macOS-specific keys.

### 4. App Sandbox Entitlements

The app already has network access enabled. Verify these entitlements work on macOS:
- Network (Outgoing/Incoming Connections)
- File Access (Downloads, Pictures, Music, Movies folders)
- User Selected Files

## Architecture Benefits

1. **Shared Business Logic**: All document processing, highlighting, theme management is shared
2. **Platform-Appropriate UI**: Each platform gets its native navigation and interaction patterns
3. **Type Safety**: Compile-time enforcement of platform-specific code paths
4. **Maintainability**: Single codebase with clear platform abstractions

## Testing Checklist

- [ ] iOS: TabView navigation works
- [ ] iOS: Text highlighting works (tap and hold for menu)
- [ ] iOS: Highlight removal works (tap highlight → alert)
- [ ] macOS: Sidebar navigation works
- [ ] macOS: Text highlighting works (right-click for menu)
- [ ] macOS: Highlight removal works (click highlight → alert)
- [ ] macOS: Keyboard shortcuts work (Cmd+I for import)
- [ ] Both: Theme customization works
- [ ] Both: Font selection works
- [ ] Both: URL import works
- [ ] Both: EU case database search works
- [ ] Both: Highlights persist across sessions
- [ ] Both: Page layout toggle works

## Known Differences

### Interaction Patterns

**iOS**:
- Long-press on text to show highlight menu
- Tap on highlight to remove it (shows action sheet)
- Sheet presentations for modal views

**macOS**:
- Right-click on text to show highlight menu
- Click on highlight to remove it (shows alert dialog)
- Standard macOS window management

### Navigation

**iOS**:
- Bottom tab bar
- Pull-to-refresh where applicable
- Navigation bar with back button

**macOS**:
- Sidebar navigation
- Standard macOS toolbar
- Menu bar commands

## Future Enhancements

Potential improvements for the macOS version:

1. **Document Management**:
   - File > Open... to open documents from disk
   - File > Save... to save documents
   - Recent documents menu

2. **Export Features**:
   - Export highlights to PDF with annotations
   - Export to HTML with highlighted sections

3. **Multiple Windows**:
   - Open documents in separate windows
   - Window management via Window menu

4. **Toolbar Customization**:
   - Customizable toolbar with highlight color buttons
   - Quick access to theme switching

5. **Touch Bar Support** (if applicable):
   - Highlight colors
   - Theme switcher

6. **Keyboard Shortcuts**:
   - Cmd+1, Cmd+2, etc. for highlight colors
   - Cmd+F for find in document
   - Cmd+G for find next

7. **macOS-specific Features**:
   - Services menu integration
   - Quick Look plugin for previews
   - Drag and drop from Finder

## Developer Notes

- All platform-specific code is wrapped in `#if os(macOS)` or `#if canImport(UIKit/AppKit)`
- PlatformTypes.swift provides the abstraction layer
- New platform-specific features should follow this pattern
- Always test on both platforms when making changes to shared code
