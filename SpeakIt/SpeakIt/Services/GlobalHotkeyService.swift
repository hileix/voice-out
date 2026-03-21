//
//  GlobalHotkeyService.swift
//  SpeakIt
//
//  Created by SpeakIt Migration
//

import Foundation
import AppKit
import Carbon

/// Service for registering and handling global hotkeys (system-wide keyboard shortcuts)
class GlobalHotkeyService: ObservableObject {
    static let shared = GlobalHotkeyService()

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?

    // Hotkey configuration (Ctrl+S by default)
    private let hotkeyKeyCode: UInt32 = 1 // 'S' key code
    private let hotkeyModifiers: UInt32 = UInt32(controlKey) // Ctrl key

    var onHotkeyTriggered: (() -> Void)?

    private init() {
        setupGlobalHotkey()
    }

    deinit {
        unregisterHotkey()
    }

    /// Register the global hotkey
    private func setupGlobalHotkey() {
        // Check if we have accessibility permissions
        guard AXIsProcessTrusted() else {
            print("Accessibility permissions not granted. Cannot register global hotkey.")
            requestAccessibilityPermissions()
            return
        }

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // Install event handler
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }

            let service = Unmanaged<GlobalHotkeyService>.fromOpaque(userData).takeUnretainedValue()
            service.handleHotkeyPress()

            return noErr
        }, 1, &eventSpec, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)

        // Register the hotkey
        let hotKeyID = EventHotKeyID(signature: OSType(0x48544B59), id: 1) // 'HTKY' signature
        RegisterEventHotKey(hotkeyKeyCode, hotkeyModifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        print("Global hotkey registered: Ctrl+S")
    }

    /// Unregister the global hotkey
    private func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    /// Handle hotkey press event
    private func handleHotkeyPress() {
        print("Global hotkey triggered: Ctrl+S")

        // Trigger the callback
        DispatchQueue.main.async {
            self.onHotkeyTriggered?()
        }
    }

    /// Request accessibility permissions
    func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessibilityEnabled {
            print("Requesting accessibility permissions...")

            // Show alert to guide user
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "SpeakIt needs accessibility permission to monitor global keyboard shortcuts. Please grant permission in System Preferences > Security & Privacy > Privacy > Accessibility."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Preferences")
                alert.addButton(withTitle: "Later")

                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
        }
    }

    /// Check if accessibility permissions are granted
    func hasAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Simulate Cmd+C to copy selected text
    func copySelectedText() {
        guard hasAccessibilityPermissions() else {
            print("Cannot copy selected text: accessibility permissions not granted")
            return
        }

        // Create and post Cmd+C keyboard event
        let source = CGEventSource(stateID: .combinedSessionState)

        // Key down: Command key
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = .maskCommand

        // Key down: C key
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        cDown?.flags = .maskCommand

        // Key up: C key
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cUp?.flags = .maskCommand

        // Key up: Command key
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

        // Post events
        let location = CGEventTapLocation.cghidEventTap
        cmdDown?.post(tap: location)
        cDown?.post(tap: location)
        cUp?.post(tap: location)
        cmdUp?.post(tap: location)

        print("Simulated Cmd+C to copy selected text")
    }
}
