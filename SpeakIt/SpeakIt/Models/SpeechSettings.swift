//
//  SpeechSettings.swift
//  SpeakIt
//
//  Created by SpeakIt Migration
//

import Foundation
import AVFoundation

/// Speech settings model with UserDefaults persistence
class SpeechSettings: ObservableObject {
    static let shared = SpeechSettings()

    // App Group identifier for sharing between app and extension
    private static let appGroupIdentifier = "group.com.yourteam.speakit"
    private let defaults: UserDefaults

    // Keys for UserDefaults
    private enum Keys {
        static let voiceIdentifier = "voiceIdentifier"
        static let rate = "rate"
        static let pitch = "pitch"
        static let autoSpeakClipboard = "autoSpeakClipboard"
    }

    // MARK: - Published Properties

    @Published var voiceIdentifier: String? {
        didSet {
            defaults.set(voiceIdentifier, forKey: Keys.voiceIdentifier)
        }
    }

    @Published var rate: Float {
        didSet {
            defaults.set(rate, forKey: Keys.rate)
        }
    }

    @Published var pitch: Float {
        didSet {
            defaults.set(pitch, forKey: Keys.pitch)
        }
    }

    @Published var autoSpeakClipboard: Bool {
        didSet {
            defaults.set(autoSpeakClipboard, forKey: Keys.autoSpeakClipboard)
        }
    }

    // MARK: - Initialization

    private init() {
        // Use App Group defaults for sharing with Share Extension
        if let appGroupDefaults = UserDefaults(suiteName: SpeechSettings.appGroupIdentifier) {
            self.defaults = appGroupDefaults
        } else {
            // Fallback to standard defaults
            self.defaults = UserDefaults.standard
            print("Warning: Could not initialize App Group defaults. Using standard UserDefaults.")
        }

        // Load saved settings or use defaults
        self.voiceIdentifier = defaults.string(forKey: Keys.voiceIdentifier)
        self.rate = defaults.object(forKey: Keys.rate) as? Float ?? AVSpeechUtteranceDefaultSpeechRate
        self.pitch = defaults.object(forKey: Keys.pitch) as? Float ?? 1.0
        self.autoSpeakClipboard = defaults.bool(forKey: Keys.autoSpeakClipboard)
    }

    // MARK: - Helper Methods

    /// Get the current voice or default system voice
    var currentVoice: AVSpeechSynthesisVoice {
        if let identifier = voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            return voice
        }
        return AVSpeechSynthesisVoice(language: "en-US") ?? AVSpeechSynthesisVoice()
    }

    /// Reset all settings to defaults
    func resetToDefaults() {
        voiceIdentifier = nil
        rate = AVSpeechUtteranceDefaultSpeechRate
        pitch = 1.0
        autoSpeakClipboard = false
    }

    /// Get all available voices grouped by language
    static func availableVoices() -> [String: [AVSpeechSynthesisVoice]] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        return Dictionary(grouping: voices) { voice in
            voice.language
        }
    }

    /// Get all available voices as a flat array
    static func allVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices()
    }
}

// MARK: - Codable Support for Serialization
extension SpeechSettings {
    struct CodableSettings: Codable {
        let voiceIdentifier: String?
        let rate: Float
        let pitch: Float
        let autoSpeakClipboard: Bool
    }

    var codable: CodableSettings {
        CodableSettings(
            voiceIdentifier: voiceIdentifier,
            rate: rate,
            pitch: pitch,
            autoSpeakClipboard: autoSpeakClipboard
        )
    }

    func update(from codable: CodableSettings) {
        voiceIdentifier = codable.voiceIdentifier
        rate = codable.rate
        pitch = codable.pitch
        autoSpeakClipboard = codable.autoSpeakClipboard
    }
}
