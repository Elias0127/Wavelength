import Foundation
import CoreData
import SwiftUI


@MainActor
class DataService: ObservableObject {
    static let shared = DataService()
    
    @Published var entries: [Entry] = []
    @Published var mode: Mode = .privateMode
    @Published var hasCompletedOnboarding = false
    @Published var currentPrompt = ""
    
    private let coreDataManager = CoreDataManager.shared
    private var context: NSManagedObjectContext {
        coreDataManager.viewContext
    }
    
    
    private init() {
        loadData()
    }
    
    
    func loadData() {
        loadEntries()
        loadAppSettings()
    }
    
    private func loadEntries() {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.date, ascending: false)]
        
        do {
            let coreDataEntries = try context.fetch(request)
            entries = coreDataEntries.map { $0.toEntry() }
        } catch {
            print("Failed to load entries: \(error)")
            entries = []
        }
    }
    
    private func loadAppSettings() {
        let appSettings = AppSettings.getOrCreate(context: context)
        let state = appSettings.toAppState()
        
        mode = state.mode
        hasCompletedOnboarding = state.hasCompletedOnboarding
        currentPrompt = state.currentPrompt
    }
    
    
    func addEntry(_ entry: Entry) {
        let journalEntry = JournalEntry.createFromEntry(entry, context: context)
        
        do {
            try context.save()
            entries.insert(entry, at: 0) 
        } catch {
            print("Failed to save entry: \(error)")
        }
    }
    
    func updateEntry(id: UUID, mutate: (inout Entry) -> Void) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        
        var entry = entries[index]
        mutate(&entry)
        entries[index] = entry
        
        
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let journalEntry = results.first {
                journalEntry.updateFromEntry(entry)
                try context.save()
            }
        } catch {
            print("Failed to update entry: \(error)")
        }
    }
    
    func deleteEntry(id: UUID) {
        
        entries.removeAll { $0.id == id }
        
        
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            for journalEntry in results {
                context.delete(journalEntry)
            }
            try context.save()
        } catch {
            print("Failed to delete entry: \(error)")
        }
    }
    
    
    func updateMode(_ newMode: Mode) {
        mode = newMode
        saveAppSettings()
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        saveAppSettings()
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        saveAppSettings()
    }
    
    func refreshPrompt() {
        currentPrompt = MockEntries.randomPrompt()
        saveAppSettings()
    }
    
    private func saveAppSettings() {
        let appSettings = AppSettings.getOrCreate(context: context)
        appSettings.updateFromAppState(
            mode: mode,
            hasCompletedOnboarding: hasCompletedOnboarding,
            currentPrompt: currentPrompt
        )
        
        do {
            try context.save()
        } catch {
            print("Failed to save app settings: \(error)")
        }
    }
    
    
    func exportData() -> Data? {
        let exportData = ExportData(
            entries: entries,
            mode: mode,
            hasCompletedOnboarding: hasCompletedOnboarding,
            exportDate: Date()
        )
        
        do {
            return try JSONEncoder().encode(exportData)
        } catch {
            print("Failed to export data: \(error)")
            return nil
        }
    }
    
    func eraseAllData() {
        
        entries.removeAll()
        
        
        coreDataManager.deleteAllData()
        
        
        mode = .privateMode
        hasCompletedOnboarding = false
        currentPrompt = MockEntries.randomPrompt()
        
        
        saveAppSettings()
    }
    
    
    var latestEntry: Entry? {
        entries.first
    }
    
    var entriesByWeek: [Date: [Entry]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.dateInterval(of: .weekOfYear, for: entry.date)?.start ?? entry.date
        }
        return grouped
    }
    
    var currentWeekEntries: [Entry] {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        return entries.filter { entry in
            calendar.dateInterval(of: .weekOfYear, for: entry.date)?.start == weekStart
        }
    }
    
    var streak: Int {
        let calendar = Calendar.current
        let sortedEntries = entries.sorted(by: { $0.date > $1.date })
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for entry in sortedEntries {
            let entryDate = calendar.startOfDay(for: entry.date)
            if entryDate == currentDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if entryDate < currentDate {
                break
            }
        }
        
        return streak
    }
    
    func getWeeklySummary() -> WeeklySummary {
        let currentWeekEntries = self.currentWeekEntries
        
        
        let wins = extractWins(from: currentWeekEntries)
        let stressors = extractStressors(from: currentWeekEntries)
        let tryNext = generateTryNext(from: currentWeekEntries)
        
        
        let moodTrend = calculateMoodTrend(from: currentWeekEntries)
        
        
        let tagFrequency = calculateTagFrequency(from: currentWeekEntries)
        
        return WeeklySummary(
            weekStart: Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date(),
            wins: wins,
            stressors: stressors,
            tryNext: tryNext,
            moodTrend: moodTrend,
            tagFrequency: tagFrequency
        )
    }
    
    
    private func extractWins(from entries: [Entry]) -> [String] {
        
        let positiveKeywords = ["good", "great", "happy", "proud", "accomplished", "breakthrough", "success"]
        
        return entries.compactMap { entry in
            if entry.feeling == .calm && positiveKeywords.contains(where: { 
                entry.transcript.lowercased().contains($0) 
            }) {
                return entry.title
            }
            return nil
        }
    }
    
    private func extractStressors(from entries: [Entry]) -> [String] {
        
        let stressKeywords = ["anxious", "stressed", "worried", "overwhelmed", "tired", "difficult"]
        
        return entries.compactMap { entry in
            if entry.feeling == .tense && stressKeywords.contains(where: { 
                entry.transcript.lowercased().contains($0) 
            }) {
                return entry.title
            }
            return nil
        }
    }
    
    private func generateTryNext(from entries: [Entry]) -> [String] {
        
        var suggestions: [String] = []
        
        let allText = entries.map { $0.transcript }.joined(separator: " ").lowercased()
        
        if allText.contains("sleep") || allText.contains("tired") {
            suggestions.append("Try a 5-minute breathing exercise before bed")
        }
        
        if allText.contains("work") || allText.contains("busy") {
            suggestions.append("Set one small boundary at work this week")
        }
        
        if allText.contains("exercise") || allText.contains("walk") {
            suggestions.append("Maintain your exercise routine - it's helping!")
        }
        
        if suggestions.isEmpty {
            suggestions.append("Take 10 minutes each morning to plan your day")
        }
        
        return suggestions
    }
    
    private func calculateMoodTrend(from entries: [Entry]) -> [Double] {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        var dailyAverages: [Double] = []
        
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let dayEntries = entries.filter { entry in
                entry.date >= dayStart && entry.date < dayEnd
            }
            
            if dayEntries.isEmpty {
                dailyAverages.append(0.5) 
            } else {
                let average = dayEntries.map { $0.averageValence }.reduce(0, +) / Double(dayEntries.count)
                dailyAverages.append(average)
            }
        }
        
        return dailyAverages
    }
    
    private func calculateTagFrequency(from entries: [Entry]) -> [String: Int] {
        var frequency: [String: Int] = [:]
        
        for entry in entries {
            for tag in entry.tags {
                frequency[tag, default: 0] += 1
            }
        }
        
        return frequency
    }
}


struct ExportData: Codable {
    let entries: [Entry]
    let mode: Mode
    let hasCompletedOnboarding: Bool
    let exportDate: Date
}
