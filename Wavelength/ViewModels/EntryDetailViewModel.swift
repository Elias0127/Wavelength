import Foundation
import SwiftUI


@MainActor
class EntryDetailViewModel: ObservableObject {
    @Published var entry: Entry
    @Published var showDeleteConfirmation = false
    
    private let onUpdate: (Entry) -> Void
    private let onDelete: (UUID) -> Void
    
    init(entry: Entry, onUpdate: @escaping (Entry) -> Void, onDelete: @escaping (UUID) -> Void) {
        self.entry = entry
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }
    
    
    func toggleFavorite() {
        entry.favorite.toggle()
        onUpdate(entry)
    }
    
    func deleteEntry() {
        onDelete(entry.id)
    }
    
    func confirmDelete() {
        showDeleteConfirmation = true
    }
    
    
    var hasCounselorReply: Bool {
        entry.counselorReply != nil && !entry.counselorReply!.isEmpty
    }
    
    var hasValenceData: Bool {
        !entry.valenceSeries.isEmpty
    }
    
    var averageValence: Double {
        entry.averageValence
    }
    
    var valenceDescription: String {
        switch averageValence {
        case 0.0..<0.3:
            return "Low energy"
        case 0.3..<0.7:
            return "Balanced"
        case 0.7...1.0:
            return "High energy"
        default:
            return "Unknown"
        }
    }
}
