//
//  Persistence.swift
//  SpeakIt
//
//  Created by mac on 2026/3/21.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<10 {
            let newHistory = SpeechHistory(context: viewContext)
            newHistory.id = UUID()
            newHistory.text = "Sample speech history item \(i + 1)"
            newHistory.timestamp = Date().addingTimeInterval(-Double(i * 3600))
            newHistory.source = "manual"
            newHistory.voice = "com.apple.ttsbundle.Samantha-compact"
            newHistory.duration = 2.5
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SpeakIt")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Helper Methods

    /// Save speech history to CoreData
    func saveSpeechHistory(text: String, source: String, voice: String, duration: Double = 0.0) {
        let context = container.viewContext
        let newHistory = SpeechHistory(context: context)
        newHistory.id = UUID()
        newHistory.text = text
        newHistory.timestamp = Date()
        newHistory.source = source
        newHistory.voice = voice
        newHistory.duration = duration

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Error saving speech history: \(nsError), \(nsError.userInfo)")
        }
    }

    /// Fetch recent speech history
    func fetchRecentHistory(limit: Int = 10) -> [SpeechHistory] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<SpeechHistory> = SpeechHistory.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SpeechHistory.timestamp, ascending: false)]
        fetchRequest.fetchLimit = limit

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching speech history: \(error)")
            return []
        }
    }

    /// Delete all speech history
    func deleteAllHistory() {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SpeechHistory.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Error deleting speech history: \(error)")
        }
    }
}
