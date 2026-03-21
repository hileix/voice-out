//
//  TTSService.swift
//  SpeakIt
//
//  Created by SpeakIt Migration
//

import Foundation
import AVFoundation

/// Singleton service for managing text-to-speech functionality
class TTSService: NSObject, ObservableObject {
    static let shared = TTSService()

    private let synthesizer = AVSpeechSynthesizer()

    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var currentText: String?

    private override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    /// Configure audio session for background playback
    private func configureAudioSession() {
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        #endif
        // macOS doesn't require audio session configuration
    }

    /// Speak the given text using current settings
    /// - Parameters:
    ///   - text: The text to speak
    ///   - settings: Speech settings (voice, rate, pitch)
    func speak(text: String, settings: SpeechSettings = SpeechSettings.shared) {
        guard !text.isEmpty else {
            print("❌ TTSService.speak: Text is empty")
            return
        }

        print("🎤 TTSService.speak called with text: \(text.prefix(50))...")

        // Stop any current speech
        if synthesizer.isSpeaking {
            print("⏹️ Stopping current speech")
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)

        // Apply settings
        if let voiceIdentifier = settings.voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
            print("🗣️ Using voice: \(voice.name)")
        } else {
            // Default to system voice
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            print("🗣️ Using default en-US voice")
        }

        utterance.rate = settings.rate
        utterance.pitchMultiplier = settings.pitch

        print("⚙️ Rate: \(settings.rate), Pitch: \(settings.pitch)")

        currentText = text

        print("▶️ Starting speech synthesis...")
        synthesizer.speak(utterance)
        print("✅ Speech synthesis initiated")
    }

    /// Pause current speech
    func pause() {
        guard synthesizer.isSpeaking, !isPaused else { return }
        synthesizer.pauseSpeaking(at: .word)
    }

    /// Resume paused speech
    func resume() {
        guard isPaused else { return }
        synthesizer.continueSpeaking()
    }

    /// Stop current speech
    func stop() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TTSService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.isPaused = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPaused = true
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPaused = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused = false
            self.currentText = nil
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused = false
            self.currentText = nil
        }
    }
}
