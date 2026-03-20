# Voice Out - Native macOS Swift Migration Design

**Date**: 2026-03-20
**Status**: Approved
**Author**: Claude & User

## Overview

This document specifies the migration of Voice Out from an Electron-based application to a native macOS application built with Swift and SwiftUI. The migration will preserve all existing functionality while leveraging native macOS APIs for better performance, smaller app size, and deeper system integration.

## Goals

1. **Feature Parity**: Maintain all functionality from the Electron version
2. **Native Experience**: Deliver a native macOS app that feels like a first-class citizen
3. **Clean Migration**: Create a parallel Swift project alongside the existing Electron app
4. **Maintainability**: Build a well-structured codebase that's easy to extend

## Current State

The existing Electron app (`voice-out`) provides:
- Global keyboard shortcut monitoring (default: Ctrl+S)
- Text selection capture via AppleScript on macOS
- Text-to-speech using the `say` command-line tool
- React-based UI with settings for customizing shortcuts
- Cross-platform support (though primarily used on macOS)

**Key Dependencies**:
- `@xitanggg/node-selection` - for text selection
- `say` - for text-to-speech
- Electron + React + Vite

## Design Decisions

### Application Type
**Choice**: Traditional window-based macOS app (not menu bar app)
- Has a main window with dock icon
- Similar presentation to current Electron version
- Easier migration for existing users

### UI Framework
**Choice**: SwiftUI
- Modern, declarative UI framework
- Less code than AppKit
- Automatic dark/light mode support
- Minimum macOS 11.0 (Big Sur) requirement

### Migration Strategy
**Choice**: Clean parallel migration
- New project in `voice-out-swift/` directory
- Both apps coexist during development
- Can reference Electron version while building
- Easy comparison and testing

## Project Structure

```
voice-out-swift/
├── VoiceOut.xcodeproj          # Xcode project file
├── VoiceOut/
│   ├── VoiceOutApp.swift       # App entry point (@main)
│   ├── Models/
│   │   └── ShortcutModel.swift # Data model for keyboard shortcuts
│   ├── Services/
│   │   ├── ShortcutManager.swift      # Global shortcut registration
│   │   ├── TextSelectionService.swift # Text selection capture
│   │   ├── TTSService.swift           # Text-to-speech wrapper
│   │   └── PermissionsManager.swift   # Accessibility permissions
│   ├── Views/
│   │   ├── MainView.swift             # Main app window (like App.tsx)
│   │   └── SettingsView.swift         # Settings UI (like Settings.tsx)
│   ├── ViewModels/
│   │   └── SettingsViewModel.swift    # Settings business logic
│   └── Resources/
│       └── Assets.xcassets            # Icons and images
├── Info.plist                  # App metadata & permissions
└── VoiceOut.entitlements       # Sandbox & security entitlements
```

**Location**: `/Users/mac/project/my/voice-out-swift/`

## Architecture

### Component Overview

**VoiceOutApp** (App Entry Point)
- SwiftUI App lifecycle
- Window configuration
- App-level state management

**ShortcutModel** (Data Model)
- Represents keyboard shortcuts
- Codable for UserDefaults persistence
- Properties: key (String), modifiers (control, shift, alt, meta booleans)

**ShortcutManager** (Service)
- Registers/unregisters global shortcuts using Carbon API
- Wraps `RegisterEventHotKey` for Swift
- Validates shortcuts to prevent system conflicts
- Notifies when shortcut is triggered

**TextSelectionService** (Service)
- Captures selected text from any application
- Primary: macOS Accessibility API
- Fallback: AppleScript if Accessibility fails
- 200ms delay after trigger (matches Electron behavior)
- Returns selected text as String

**TTSService** (Service)
- Wraps `NSSpeechSynthesizer` for text-to-speech
- Async/await API for modern Swift
- Handles speech interruption and errors
- Uses system default voice (extensible for voice selection)

**PermissionsManager** (Service)
- Checks Accessibility permission status
- Requests permissions when needed
- Provides deep link to System Settings
- Observable for UI updates

**MainView** (SwiftUI View)
- Main application interface
- Shows current shortcut
- Navigation to Settings
- Displays permission warnings
- Window size: ~600x400

**SettingsView** (SwiftUI View)
- Shortcut recorder control
- "Press shortcut keys..." recording mode
- Reset to default button
- Back to main navigation
- Real-time validation

**SettingsViewModel** (ViewModel)
- Business logic for settings
- Bridges UI and services
- Handles shortcut persistence via UserDefaults
- @Published properties for SwiftUI binding

### Data Flow

```
User presses global shortcut
  ↓
ShortcutManager detects trigger
  ↓
TextSelectionService captures selected text (via Accessibility API)
  ↓
TTSService speaks the text (via NSSpeechSynthesizer)
```

```
User changes shortcut in Settings
  ↓
SettingsView captures key combination
  ↓
SettingsViewModel validates and saves to UserDefaults
  ↓
ShortcutManager re-registers new shortcut
  ↓
MainView updates display
```

### Key Differences from Electron

| Electron Version | Swift Version |
|-----------------|---------------|
| Main/Renderer IPC processes | Single unified app |
| AppleScript for text selection | Accessibility API (+ AppleScript fallback) |
| `say` command-line tool | NSSpeechSynthesizer |
| Electron Store | UserDefaults |
| globalShortcut API | Carbon RegisterEventHotKey |
| React components | SwiftUI views |
| ~200MB app bundle | ~5-10MB app bundle |

## User Interface Design

### MainView
- **Layout**: Vertical stack with centered content
- **Content**:
  - App title: "Voice Out"
  - Description: "Speak selected text with customizable shortcuts"
  - Current shortcut display: "Press Ctrl + S to speak selected text"
  - Settings button
- **Permissions Banner**: Shows when Accessibility not granted with "Open System Settings" button
- **Style**: Native macOS appearance, automatic dark/light mode

### SettingsView
- **Layout**: Form-style settings panel
- **Shortcut Recorder**:
  - Clickable field showing current shortcut
  - Recording mode: "Press shortcut keys..."
  - Visual feedback: border/background color change
  - Validates: requires at least one modifier key
  - Ignores: solo modifier keys (Ctrl, Shift, Alt, Cmd alone)
- **Buttons**:
  - "Reset to Default" - restores Ctrl+S
  - "Back to Main" - navigation
- **Real-time Updates**: Changes apply immediately

### Permission Prompts
- Inline alert view with clear messaging
- "Open System Settings" button with deep link
- Instructions: "Voice Out needs Accessibility permission to read selected text"

### Visual Style
- SF Symbols for icons
- System colors and typography
- Standard macOS spacing (8pt, 16pt grid)
- Subtle transitions between views
- Keyboard navigation support

## Core Features

### Global Keyboard Shortcuts

**Implementation**:
- Use Carbon's `RegisterEventHotKey` API
- Wrap in Swift-friendly interface
- Monitor for key events in background

**Default Shortcut**: Ctrl+S

**Customization**:
- User can record any modifier + key combination
- Requires at least one modifier (Ctrl, Shift, Alt, Cmd)
- Validates against system shortcuts
- Persists to UserDefaults

**Edge Cases**:
- Conflict with system shortcuts → show error, keep previous shortcut
- Invalid combinations → reject and show validation message
- App restart → reload from UserDefaults

### Text Selection Capture

**Primary Method**: Accessibility API
```swift
AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute, &focusedElement)
AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute, &selectedText)
```

**Fallback Method**: AppleScript
```applescript
tell application "System Events"
  set selectedText to value of attribute "AXSelectedText" of focused element
end tell
```

**Timing**: 200ms delay after shortcut trigger (ensures selection is ready)

**Validation**:
- Skip empty selections
- Skip whitespace-only selections
- Handle special characters and emojis
- Timeout after 500ms

**Permission Requirements**:
- Accessibility permission must be granted
- PermissionsManager handles checking and requesting

### Text-to-Speech

**Implementation**: `NSSpeechSynthesizer`
```swift
let synthesizer = NSSpeechSynthesizer()
synthesizer.startSpeaking(text)
```

**Features**:
- Uses system default voice
- Async/await interface
- Can interrupt previous speech
- Error handling for failed synthesis

**Future Extensions** (not in initial version):
- Voice selection
- Speech rate control
- Pitch adjustment

### Settings Persistence

**Storage**: UserDefaults
```swift
UserDefaults.standard.set(encodedShortcut, forKey: "globalShortcut")
```

**Data Model**: ShortcutModel (Codable)
```swift
struct ShortcutModel: Codable {
    var key: String
    var modifiers: Modifiers

    struct Modifiers: Codable {
        var control: Bool
        var shift: Bool
        var alt: Bool
        var meta: Bool
    }
}
```

**Synchronization**:
- @Published properties in ViewModel
- Automatic UI updates via SwiftUI
- Persistence on every change
- Load on app launch

### Permissions Management

**Required Permission**: Accessibility

**Check Status**:
```swift
AXIsProcessTrusted()
```

**Request Permission**:
```swift
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
AXIsProcessTrustedWithOptions(options as CFDictionary)
```

**Deep Link to Settings**:
```swift
NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
```

**UI Integration**:
- Show banner when permission not granted
- Update UI automatically when permission state changes
- Disable shortcut functionality until granted

## Error Handling

### Permission Errors
- **Scenario**: Accessibility permission denied
- **Handling**:
  - Display persistent banner in UI
  - Disable shortcut registration
  - Show "Open System Settings" button
  - Log error for debugging

### Shortcut Registration Failures
- **Scenario**: Shortcut conflicts with system shortcuts
- **Handling**:
  - Show alert: "This shortcut is already in use by the system"
  - Revert to previous working shortcut
  - Don't save invalid shortcut to UserDefaults
  - Log conflict details

### Text Selection Edge Cases
- **Empty/whitespace selection**: Don't speak, log debug message
- **Very long text**: Log warning, still attempt to speak
- **Special characters/emojis**: Handle gracefully, speak as UTF-8
- **Timeout (>500ms)**: Abort selection, log timeout error

### TTS Failures
- **Scenario**: NSSpeechSynthesizer initialization fails
- **Handling**:
  - Log error with details
  - Show user-friendly alert
  - Don't crash app
  - Continue allowing shortcut changes

- **Scenario**: Speech interrupted or stopped mid-speech
- **Handling**:
  - Clean up resources
  - Reset synthesizer state
  - Ready for next trigger

### App Lifecycle
- **App quit**: Unregister all shortcuts cleanly
- **Before terminate**: Persist settings to UserDefaults
- **macOS sleep/wake**: Re-register shortcuts after wake
- **System restart**: Load settings and re-initialize

### Data Validation
- **Corrupted UserDefaults**: Fallback to default shortcut (Ctrl+S)
- **Invalid shortcut model**: Use type-safe defaults
- **Missing keys**: Apply sensible defaults

## Testing Strategy

### Manual Testing Approach
Primary testing will be manual due to heavy system integration (global shortcuts, accessibility, TTS).

### Core Functionality Tests
- [ ] Default shortcut (Ctrl+S) works on app launch
- [ ] Text selection from Safari, TextEdit, Notes, VS Code
- [ ] TTS speaks selected text correctly
- [ ] Custom shortcut configuration
- [ ] Settings persist across app restarts
- [ ] Shortcut changes apply immediately

### Permission Flow Tests
- [ ] Fresh install shows permission prompt
- [ ] "Open System Settings" deep link works
- [ ] App detects permission granted/revoked
- [ ] UI updates on permission state change

### Settings UI Tests
- [ ] Shortcut recorder activation
- [ ] Key combination capture
- [ ] Shortcut display formatting (e.g., "Ctrl + Shift + S")
- [ ] "Reset to Default" button
- [ ] Navigation between Main and Settings
- [ ] Settings persistence across restarts

### Edge Case Tests
- [ ] Empty selection (should not speak)
- [ ] Whitespace-only selection (should not speak)
- [ ] Very long text selection (should speak)
- [ ] Rapid shortcut triggering
- [ ] Change shortcut while TTS is speaking

### System Integration Tests
- [ ] App behavior after macOS sleep/wake
- [ ] Shortcut works across multiple displays
- [ ] Different keyboard layouts
- [ ] Respects system dark/light mode
- [ ] App quit and restart cycles

### Compatibility Testing
- [ ] macOS 11 (Big Sur) - minimum version
- [ ] Latest macOS (Sonoma/Sequoia)
- [ ] Intel Macs
- [ ] Apple Silicon Macs

## Acceptance Criteria

1. All features from Electron version work in Swift version
2. No crashes during normal operation
3. Permissions are properly requested and handled
4. Settings persist correctly across app restarts
5. App feels native and responsive
6. Follows macOS Human Interface Guidelines
7. App bundle size < 15MB
8. Clean Xcode project with no warnings
9. Code is well-documented and maintainable

## Out of Scope

The following features are intentionally excluded from the initial migration:

- Cross-platform support (Windows, Linux)
- Custom voice selection
- Speech rate/pitch controls
- Menu bar mode
- Auto-updates (can be added later)
- Sandboxing (initial version will request necessary entitlements)
- App Store distribution (can be configured later)

## Future Enhancements

Potential features to consider after successful migration:

1. **Enhanced TTS Controls**: Voice selection, rate, pitch
2. **Menu Bar Mode**: Optional menu bar-only mode
3. **History**: Track recently spoken text
4. **Multiple Shortcuts**: Different shortcuts for different actions
5. **App Store Distribution**: Sandbox and notarize for App Store
6. **Auto-Updates**: Sparkle framework integration
7. **Localization**: Multi-language support
8. **Accessibility Features**: VoiceOver support, high contrast mode

## Migration Timeline

**Phase 1: Project Setup**
- Create Xcode project
- Configure build settings and entitlements
- Set up project structure

**Phase 2: Core Services**
- Implement ShortcutManager
- Implement TextSelectionService
- Implement TTSService
- Implement PermissionsManager

**Phase 3: Data Models & Persistence**
- Create ShortcutModel
- Implement UserDefaults persistence
- Create SettingsViewModel

**Phase 4: User Interface**
- Build MainView
- Build SettingsView
- Implement navigation
- Add permission prompts

**Phase 5: Testing & Refinement**
- Manual testing across all scenarios
- Bug fixes and polish
- Performance optimization

**Phase 6: Documentation**
- Update README for Swift version
- Add build instructions
- Document architecture

## Success Metrics

- Swift app launches in < 2 seconds
- Text selection capture works 99%+ of the time
- No memory leaks during extended use
- CPU usage < 1% when idle
- App bundle size < 15MB
- Positive user feedback on native feel

## References

- Current Electron source: `/Users/mac/project/my/voice-out/src/`
- macOS Accessibility API: https://developer.apple.com/documentation/applicationservices/axuielement
- Carbon Event Manager: https://developer.apple.com/documentation/carbon/event_manager
- NSSpeechSynthesizer: https://developer.apple.com/documentation/appkit/nsspeechsynthesizer
- SwiftUI: https://developer.apple.com/documentation/swiftui
