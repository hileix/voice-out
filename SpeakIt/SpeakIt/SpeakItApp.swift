//
//  SpeakItApp.swift
//  SpeakIt
//
//  Created by mac on 2026/3/21.
//

import SwiftUI

@main
struct SpeakItApp: App {
    let persistenceController = PersistenceController.shared

    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        #if os(macOS)
        // macOS: Menu bar app with global hotkey support
        Settings {
            EmptyView()
        }
        #else
        // iOS: Standard window-based app
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        #endif
    }
}

#if os(macOS)
/// App delegate for handling macOS-specific functionality
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    private let hotkeyService = GlobalHotkeyService.shared
    private let clipboardMonitor = ClipboardMonitor.shared
    private let ttsService = TTSService.shared
    private let settings = SpeechSettings.shared
    private let persistenceController = PersistenceController.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 SpeakIt applicationDidFinishLaunching")
        setupMenuBar()
        setupHotkeyHandler()
        checkAccessibilityPermissions()

        print("✅ SpeakIt started. Press Ctrl+S to speak selected text.")
    }

    /// Setup menu bar icon and menu
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "speaker.wave.2.fill", accessibilityDescription: "SpeakIt")
            button.action = #selector(statusItemClicked)
            button.target = self
        }

        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "SpeakIt", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Speak Clipboard", action: #selector(speakClipboard), keyEquivalent: "c"))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))

        menu.addItem(NSMenuItem.separator())

        let hotkeyItem = NSMenuItem(title: "Hotkey: Ctrl+S", action: nil, keyEquivalent: "")
        hotkeyItem.isEnabled = false
        menu.addItem(hotkeyItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit SpeakIt", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    /// Setup global hotkey handler
    private func setupHotkeyHandler() {
        hotkeyService.onHotkeyTriggered = { [weak self] in
            self?.handleGlobalHotkey()
        }
    }

    /// Check and request accessibility permissions
    private func checkAccessibilityPermissions() {
        if !hotkeyService.hasAccessibilityPermissions() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.hotkeyService.requestAccessibilityPermissions()
            }
        }
    }

    /// Handle global hotkey press (Ctrl+S)
    @objc private func handleGlobalHotkey() {
        print("Ctrl+S pressed - capturing selected text")

        // Step 1: Simulate Cmd+C to copy selected text
        hotkeyService.copySelectedText()

        // Step 2: Wait a bit for clipboard to update, then read and speak
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let text = self.clipboardMonitor.readClipboardText(), !text.isEmpty {
                print("✅ Text captured from clipboard: \(text.prefix(50))...")
                print("📢 Starting speech synthesis...")

                // Speak the text
                self.ttsService.speak(text: text, settings: self.settings)

                // Visual feedback
                self.showTemporaryNotification(text: "Speaking: \(text.prefix(30))...")

                // Save to history
                self.saveSpeechHistory(text: text, source: "hotkey")
            } else {
                print("❌ No text found in clipboard")
                self.showTemporaryNotification(text: "No text selected")
            }
        }
    }

    /// Speak current clipboard content
    @objc private func speakClipboard() {
        if let text = clipboardMonitor.readClipboardText(), !text.isEmpty {
            ttsService.speak(text: text, settings: settings)
            saveSpeechHistory(text: text, source: "manual")
        } else {
            showAlert(title: "No Text", message: "Clipboard is empty or doesn't contain text.")
        }
    }

    /// Open settings window
    @objc private func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
                .frame(width: 500, height: 600)

            let hostingController = NSHostingController(rootView: settingsView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "SpeakIt Settings"
            window.styleMask = [.titled, .closable, .resizable]
            window.setContentSize(NSSize(width: 500, height: 600))
            window.center()

            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Menu bar icon clicked
    @objc private func statusItemClicked() {
        // Menu will show automatically
    }

    /// Quit application
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    /// Save speech history to CoreData
    private func saveSpeechHistory(text: String, source: String) {
        persistenceController.saveSpeechHistory(
            text: text,
            source: source,
            voice: settings.currentVoice.identifier,
            duration: 0.0
        )
    }

    /// Show alert dialog
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    /// Show temporary notification
    private func showTemporaryNotification(text: String) {
        let notification = NSUserNotification()
        notification.title = "SpeakIt"
        notification.informativeText = text
        notification.soundName = nil

        NSUserNotificationCenter.default.deliver(notification)

        // Remove after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NSUserNotificationCenter.default.removeDeliveredNotification(notification)
        }
    }
}
#endif

