import SwiftUI

// MARK: - Journal View
struct JournalView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var journalViewModel: JournalViewModel
    @State private var selectedEntry: Entry?
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self._journalViewModel = StateObject(wrappedValue: JournalViewModel(appViewModel: appViewModel))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filters
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        TextField("Search entries...", text: $journalViewModel.searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .fill(DesignTokens.Colors.card)
                    )
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    // Tag filters
                    if !journalViewModel.availableTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                ForEach(journalViewModel.availableTags, id: \.self) { tag in
                                    TagChip(
                                        text: tag,
                                        isSelected: journalViewModel.selectedTags.contains(tag)
                                    ) {
                                        journalViewModel.toggleTag(tag)
                                    }
                                }
                            }
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                        }
                    }
                    
                    // Sort options
                    HStack {
                        Text("Sort by:")
                            .captionText()
                        
                        Picker("Sort Order", selection: $journalViewModel.sortOrder) {
                            ForEach(JournalViewModel.SortOrder.allCases, id: \.self) { order in
                                Text(order.displayName).tag(order)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Spacer()
                        
                        if !journalViewModel.searchText.isEmpty || !journalViewModel.selectedTags.isEmpty {
                            Button("Clear") {
                                journalViewModel.clearFilters()
                            }
                            .captionText()
                            .foregroundColor(DesignTokens.Colors.primary)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.surface)
                
                // Entries list
                if journalViewModel.filteredEntries.isEmpty {
                    EmptyState(
                        icon: "magnifyingglass",
                        title: "No entries found",
                        message: "Try adjusting your search or filters to find what you're looking for."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: DesignTokens.Spacing.lg) {
                            ForEach(journalViewModel.filteredEntries) { entry in
                                EntryCard(entry: entry) {
                                    selectedEntry = entry
                                }
                                .padding(.horizontal, DesignTokens.Spacing.lg)
                            }
                        }
                        .padding(.vertical, DesignTokens.Spacing.lg)
                    }
                }
            }
            .background(DesignTokens.Colors.surface)
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationDestination(item: $selectedEntry) { entry in
            EntryDetailView(
                entry: entry,
                appViewModel: appViewModel
            )
        }

    }
}

// MARK: - Preview
#Preview {
    JournalView(appViewModel: AppViewModel())
}
