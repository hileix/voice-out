//
//  ContentView.swift
//  SpeakIt
//
//  Created by mac on 2026/3/21.
//  NOTE: This file is deprecated - MainView.swift is now used instead
//

import SwiftUI
import CoreData

// This view is kept for compatibility but is no longer used
// The app now uses MainView.swift as the main interface
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SpeechHistory.timestamp, ascending: false)],
        animation: .default)
    private var speechHistory: FetchedResults<SpeechHistory>

    var body: some View {
        NavigationView {
            List {
                ForEach(speechHistory) { history in
                    NavigationLink {
                        Text("Speech: \(history.text ?? "")")
                    } label: {
                        VStack(alignment: .leading) {
                            Text(history.text ?? "")
                                .lineLimit(1)
                            if let timestamp = history.timestamp {
                                Text(timestamp, formatter: itemFormatter)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newHistory = SpeechHistory(context: viewContext)
            newHistory.id = UUID()
            newHistory.text = "Sample speech"
            newHistory.timestamp = Date()
            newHistory.source = "manual"

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { speechHistory[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
