import Foundation
import SwiftUI

@MainActor
class JournalViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedTags: Set<String> = []
    @Published var sortOrder: SortOrder = .newest
    @Published var selectedMode: JournalMode = .all

    enum SortOrder: String, CaseIterable {
        case newest = "newest"
        case oldest = "oldest"
        case feeling = "feeling"

        var displayName: String {
            switch self {
            case .newest:
                return "Newest First"
            case .oldest:
                return "Oldest First"
            case .feeling:
                return "By Feeling"
            }
        }
    }

    enum JournalMode: String, CaseIterable {
        case all = "all"
        case privateMode = "private"
        case connectedMode = "connected"

        var displayName: String {
            switch self {
            case .all:
                return "All Entries"
            case .privateMode:
                return "Private Journal"
            case .connectedMode:
                return "AI Conversations"
            }
        }

        var icon: String {
            switch self {
            case .all:
                return "book.closed"
            case .privateMode:
                return "person.circle"
            case .connectedMode:
                return "brain.head.profile"
            }
        }
    }

    private let appViewModel: AppViewModel

    var availableTags: [String] {
        let allTags = Set(appViewModel.entries.flatMap { $0.tags })
        return Array(allTags).sorted()
    }

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
    }

    var filteredEntries: [Entry] {
        var filtered = appViewModel.entries

        // Filter by mode
        switch selectedMode {
        case .all:
            break  // Show all entries
        case .privateMode:
            filtered = filtered.filter { !$0.isAIGenerated }
        case .connectedMode:
            filtered = filtered.filter { $0.isAIGenerated }
        }

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { entry in
                entry.title.localizedCaseInsensitiveContains(searchText)
                    || entry.transcript.localizedCaseInsensitiveContains(searchText)
                    || entry.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // Filter by tags
        if !selectedTags.isEmpty {
            filtered = filtered.filter { entry in
                !Set(entry.tags).isDisjoint(with: selectedTags)
            }
        }

        // Sort entries
        switch sortOrder {
        case .newest:
            filtered.sort { $0.date > $1.date }
        case .oldest:
            filtered.sort { $0.date < $1.date }
        case .feeling:
            filtered.sort { entry1, entry2 in
                let feelingOrder: [Feeling] = [.calm, .neutral, .tense]
                let index1 = feelingOrder.firstIndex(of: entry1.feeling) ?? 1
                let index2 = feelingOrder.firstIndex(of: entry2.feeling) ?? 1
                return index1 < index2
            }
        }

        return filtered
    }

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    func clearFilters() {
        searchText = ""
        selectedTags.removeAll()
        sortOrder = .newest
        selectedMode = .all
    }
}
