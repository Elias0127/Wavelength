import CoreData
import Foundation

extension JournalEntry {

    func toEntry() -> Entry {
        return Entry(
            id: self.id ?? UUID(),
            date: self.date ?? Date(),
            title: self.title ?? "",
            transcript: self.transcript ?? "",
            counselorReply: self.counselorReply,
            tags: self.tags ?? [],
            feeling: Feeling(rawValue: self.feeling ?? "neutral") ?? .neutral,
            valenceSeries: self.valenceSeries ?? [],
            mode: Mode(rawValue: self.mode ?? "private") ?? .privateMode,
            favorite: self.favorite,
            isAIGenerated: false,  
            originalConversationTurns: nil,  
            emotionalState: nil  
        )
    }

    func updateFromEntry(_ entry: Entry) {
        self.id = entry.id
        self.date = entry.date
        self.title = entry.title
        self.transcript = entry.transcript
        self.counselorReply = entry.counselorReply
        self.tags = entry.tags
        self.feeling = entry.feeling.rawValue
        self.valenceSeries = entry.valenceSeries
        self.mode = entry.mode.rawValue
        self.favorite = entry.favorite
        
        
    }

    static func createFromEntry(_ entry: Entry, context: NSManagedObjectContext) -> JournalEntry {
        let journalEntry = JournalEntry(context: context)
        journalEntry.updateFromEntry(entry)
        return journalEntry
    }
}

extension AppSettings {

    func toAppState() -> (mode: Mode, hasCompletedOnboarding: Bool, currentPrompt: String) {
        return (
            mode: Mode(rawValue: self.mode ?? "private") ?? .privateMode,
            hasCompletedOnboarding: self.hasCompletedOnboarding,
            currentPrompt: self.currentPrompt ?? MockEntries.randomPrompt()
        )
    }

    func updateFromAppState(mode: Mode, hasCompletedOnboarding: Bool, currentPrompt: String) {
        self.mode = mode.rawValue
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.currentPrompt = currentPrompt
    }

    static func getOrCreate(context: NSManagedObjectContext) -> AppSettings {
        let request: NSFetchRequest<AppSettings> = AppSettings.fetchRequest()

        do {
            let results = try context.fetch(request)
            if let existing = results.first {
                return existing
            }
        } catch {
            print("Failed to fetch AppSettings: \(error)")
        }

        let appSettings = AppSettings(context: context)
        appSettings.id = UUID()
        appSettings.mode = Mode.privateMode.rawValue
        appSettings.hasCompletedOnboarding = false
        appSettings.currentPrompt = MockEntries.randomPrompt()

        return appSettings
    }
}
