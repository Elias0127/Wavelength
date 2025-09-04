import SwiftUI

struct JournalView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var journalViewModel: JournalViewModel
    @State private var selectedEntry: Entry?
    @State private var showFilters = false

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self._journalViewModel = StateObject(
            wrappedValue: JournalViewModel(appViewModel: appViewModel))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                journalBackground
                mainContent
            }
            .background(DesignTokens.Colors.surface)
            .navigationTitle("My Journal")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailModal(
                entry: entry,
                appViewModel: appViewModel
            )
        }
    }

    private var journalBackground: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(journalSpineGradient)
                .frame(width: 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, DesignTokens.Spacing.lg)

            Spacer()
        }
        .ignoresSafeArea()
    }

    private var journalSpineGradient: LinearGradient {
        LinearGradient(
            colors: [
                DesignTokens.Colors.border.opacity(0.3),
                DesignTokens.Colors.border.opacity(0.1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            journalHeader
            journalEntries
        }
    }

    private var journalHeader: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            searchBar
            filterControls
            expandableFilters
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignTokens.Colors.textSecondary)

            TextField("Search your journal...", text: $journalViewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .font(.system(size: 16, weight: .regular, design: .rounded))
        }
        .padding(DesignTokens.Spacing.md)
        .background(searchBarBackground)
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }

    private var searchBarBackground: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
            .fill(DesignTokens.Colors.card)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .stroke(DesignTokens.Colors.border.opacity(0.3), lineWidth: 1)
            )
    }

    private var filterControls: some View {
        HStack {
            sortPicker
            Spacer()
            filterToggle
            clearButton
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }

    private var sortPicker: some View {
        Picker("Sort Order", selection: $journalViewModel.sortOrder) {
            ForEach(JournalViewModel.SortOrder.allCases, id: \.self) { order in
                Text(order.displayName).tag(order)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }

    private var filterToggle: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showFilters.toggle()
            }
        }) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text("Filters")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(DesignTokens.Colors.primary)
        }
    }

    @ViewBuilder
    private var clearButton: some View {
        if !journalViewModel.searchText.isEmpty || !journalViewModel.selectedTags.isEmpty {
            Button("Clear") {
                journalViewModel.clearFilters()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(DesignTokens.Colors.danger)
        }
    }

    @ViewBuilder
    private var expandableFilters: some View {
        if showFilters && !journalViewModel.availableTags.isEmpty {
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
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    @ViewBuilder
    private var journalEntries: some View {
        if journalViewModel.filteredEntries.isEmpty {
            emptyState
        } else {
            entriesList
        }
    }

    private var emptyState: some View {
        EmptyState(
            icon: "book.closed",
            title: "Your journal is empty",
            message: "Start your first entry by tapping the Talk button on the Home screen.",
            actionTitle: "Start Journaling"
        ) {

        }
    }

    private var entriesList: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.lg) {
                ForEach(Array(groupedEntries.enumerated()), id: \.offset) { index, group in
                    dateGroup(date: group.0, entries: group.1)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.lg)
        }
    }

    private func dateGroup(date: Date, entries: [Entry]) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            dateHeader(date: date, count: entries.count)

            ForEach(entries) { entry in
                if entry.isAIGenerated {
                    AIConversationEntryCard(entry: entry) {
                        selectedEntry = entry
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                } else {
                    DiaryEntryCard(entry: entry) {
                        selectedEntry = entry
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
            }
        }
    }

    private func dateHeader(date: Date, count: Int) -> some View {
        HStack {
            Text(formatDateHeader(date))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(DesignTokens.Colors.textPrimary)

            Spacer()

            Text("\(count) \(count == 1 ? "entry" : "entries")")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }

    private var groupedEntries: [(Date, [Entry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: journalViewModel.filteredEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: date)?.contains(Date()) == true {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    JournalView(appViewModel: AppViewModel())
}
