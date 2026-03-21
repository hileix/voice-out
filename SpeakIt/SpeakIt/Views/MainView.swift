//
//  MainView.swift
//  SpeakIt
//
//  Created by SpeakIt Migration
//

import SwiftUI
import CoreData

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var ttsService = TTSService.shared
    @StateObject private var settings = SpeechSettings.shared

    @State private var inputText: String = ""
    @State private var lastSpokenText: String?
    @State private var showingSettings = false

    // Fetch last speech history item
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SpeechHistory.timestamp, ascending: false)],
        animation: .default
    )
    private var speechHistory: FetchedResults<SpeechHistory>

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text("SpeakIt")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                // Text Input Area
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter text to speak:")
                        .font(.headline)

                    TextEditor(text: $inputText)
                        .frame(minHeight: 150)
                        .padding(8)
                        #if os(iOS)
                        .background(Color(.systemGray6))
                        #else
                        .background(Color(NSColor.controlBackgroundColor))
                        #endif
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                #if os(iOS)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                                #else
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                #endif
                        )
                }
                .padding(.horizontal)

                // Speak Button
                Button(action: speakText) {
                    HStack {
                        Image(systemName: ttsService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        Text(ttsService.isSpeaking ? "Speaking..." : "Speak Text")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputText.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(inputText.isEmpty || ttsService.isSpeaking)
                .padding(.horizontal)

                // Control Buttons
                if ttsService.isSpeaking {
                    HStack(spacing: 20) {
                        Button(action: {
                            if ttsService.isPaused {
                                ttsService.resume()
                            } else {
                                ttsService.pause()
                            }
                        }) {
                            HStack {
                                Image(systemName: ttsService.isPaused ? "play.fill" : "pause.fill")
                                Text(ttsService.isPaused ? "Resume" : "Pause")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.orange)
                            .cornerRadius(8)
                        }

                        Button(action: {
                            ttsService.stop()
                        }) {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("Stop")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }

                // Last Spoken Text
                if let lastHistory = speechHistory.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Spoken:")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(lastHistory.text ?? "")
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            #if os(iOS)
                            .background(Color(.systemGray6))
                            #else
                            .background(Color(NSColor.controlBackgroundColor))
                            #endif
                            .cornerRadius(8)

                        Text("Spoken \(timeAgo(from: lastHistory.timestamp ?? Date()))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Actions

    private func speakText() {
        guard !inputText.isEmpty else { return }

        // Speak the text
        ttsService.speak(text: inputText, settings: settings)

        // Save to history
        saveSpeechHistory(text: inputText, source: "manual")

        // Update last spoken text
        lastSpokenText = inputText
    }

    private func saveSpeechHistory(text: String, source: String) {
        let newHistory = SpeechHistory(context: viewContext)
        newHistory.id = UUID()
        newHistory.text = text
        newHistory.timestamp = Date()
        newHistory.source = source
        newHistory.voice = settings.currentVoice.identifier

        do {
            try viewContext.save()
        } catch {
            print("Error saving speech history: \(error)")
        }
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}

// MARK: - Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
