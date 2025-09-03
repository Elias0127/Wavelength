import Foundation
import SwiftUI

// MARK: - Global App State
@MainActor
class AppViewModel: ObservableObject {
    @Published var mode: Mode = .privateMode
    @Published var entries: [Entry] = MockEntries.seed
    @Published var hasCompletedOnboarding = false
    @Published var currentPrompt = MockEntries.randomPrompt()
    
    // MARK: - Computed Properties
    var latestEntry: Entry? {
        entries.sorted(by: { $0.date > $1.date }).first
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
        // Calculate current streak based on consecutive days with entries
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
    
    // MARK: - Actions
    func toggleMode() {
        mode = mode == .privateMode ? .connected : .privateMode
    }
    
    func addEntry(_ entry: Entry) {
        entries.append(entry)
        // TODO: persist with Core Data/SQLite + Keychain for keys
    }
    
    func updateEntry(id: UUID, mutate: (inout Entry) -> Void) {
        if let index = entries.firstIndex(where: { $0.id == id }) {
            mutate(&entries[index])
            // TODO: persist with Core Data/SQLite + Keychain for keys
        }
    }
    
    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        // TODO: persist with Core Data/SQLite + Keychain for keys
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        // TODO: persist onboarding state
    }
    
    func refreshPrompt() {
        currentPrompt = MockEntries.randomPrompt()
    }
    
    func exportData() {
        // TODO: export JSON via FileManager/share sheet
        print("Export data functionality would be implemented here")
    }
    
    func eraseAllData() {
        entries.removeAll()
        print("Secure erase functionality would be implemented here")
    }
    
    func getWeeklySummary() -> WeeklySummary {
        return MockEntries.weeklySummary
    }
}
