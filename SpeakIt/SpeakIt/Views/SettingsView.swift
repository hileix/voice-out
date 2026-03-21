//
//  SettingsView.swift
//  SpeakIt
//
//  Created by SpeakIt Migration
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SpeechSettings.shared
    @StateObject private var ttsService = TTSService.shared

    @State private var testText = "This is a test of the speech settings."

    var body: some View {
        NavigationView {
            Form {
                // Voice Selection
                Section {
                    Picker("Voice", selection: $settings.voiceIdentifier) {
                        Text("Default").tag(nil as String?)
                        ForEach(SpeechSettings.allVoices(), id: \.identifier) { voice in
                            Text("\(voice.name) (\(voice.language))")
                                .tag(voice.identifier as String?)
                        }
                    }
                } header: {
                    Text("Voice")
                } footer: {
                    Text("Select the voice for text-to-speech")
                }

                // Rate Control
                Section {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Rate")
                            Spacer()
                            Text(String(format: "%.2f", settings.rate))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.rate, in: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate)
                    }
                } header: {
                    Text("Speech Rate")
                } footer: {
                    Text("Adjust the speed of speech (slower ← → faster)")
                }

                // Pitch Control
                Section {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Pitch")
                            Spacer()
                            Text(String(format: "%.2f", settings.pitch))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.pitch, in: 0.5...2.0)
                    }
                } header: {
                    Text("Speech Pitch")
                } footer: {
                    Text("Adjust the pitch of speech (lower ← → higher)")
                }

                // Auto-speak Clipboard
                Section {
                    Toggle("Auto-speak Clipboard", isOn: $settings.autoSpeakClipboard)
                } header: {
                    Text("Clipboard")
                } footer: {
                    Text("Automatically speak text when copied to clipboard and app is opened")
                }

                // Test Speech
                Section {
                    Button(action: testSpeech) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("Test Speech")
                        }
                        .frame(maxWidth: .infinity)
                    }
                } footer: {
                    Text("Test current settings with sample text")
                }

                // Reset to Defaults
                Section {
                    Button(action: {
                        settings.resetToDefaults()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Defaults")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }

    private func testSpeech() {
        ttsService.speak(text: testText, settings: settings)
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
