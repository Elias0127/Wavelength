import Foundation
import SwiftUI


@MainActor
class AppViewModel: ObservableObject {
    @Published var mode: Mode = .privateMode
    @Published var entries: [Entry] = []
    @Published var hasCompletedOnboarding = false
    @Published var currentPrompt = ""
    
    private let dataService = DataService.shared
    
    
    init() {
        
        syncWithDataService()
    }
    
    private func syncWithDataService() {
        mode = dataService.mode
        entries = dataService.entries
        hasCompletedOnboarding = dataService.hasCompletedOnboarding
        currentPrompt = dataService.currentPrompt
    }
    
    
    var latestEntry: Entry? {
        dataService.latestEntry
    }
    
    var entriesByWeek: [Date: [Entry]] {
        dataService.entriesByWeek
    }
    
    var currentWeekEntries: [Entry] {
        dataService.currentWeekEntries
    }
    
    var streak: Int {
        dataService.streak
    }
    
    
    func toggleMode() {
        let newMode = mode == .privateMode ? Mode.connected : Mode.privateMode
        dataService.updateMode(newMode)
        mode = newMode
    }
    
    func addEntry(_ entry: Entry) {
        dataService.addEntry(entry)
        entries = dataService.entries
    }
    
    func updateEntry(id: UUID, mutate: (inout Entry) -> Void) {
        dataService.updateEntry(id: id, mutate: mutate)
        entries = dataService.entries
    }
    
    func deleteEntry(id: UUID) {
        dataService.deleteEntry(id: id)
        entries = dataService.entries
    }
    
    func completeOnboarding() {
        dataService.completeOnboarding()
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        dataService.resetOnboarding()
        hasCompletedOnboarding = false
    }
    
    func refreshPrompt() {
        dataService.refreshPrompt()
        currentPrompt = dataService.currentPrompt
    }
    
    func exportData() -> Data? {
        return dataService.exportData()
    }
    
    func eraseAllData() {
        dataService.eraseAllData()
        syncWithDataService()
    }
    
    func getWeeklySummary() -> WeeklySummary {
        return dataService.getWeeklySummary()
    }
}
