import SwiftUI

// MARK: - Weekly View
struct WeeklyView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var weeklyViewModel: WeeklyViewModel
    @State private var selectedTab: WeeklyViewModel.WeeklyTab = .insights
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self._weeklyViewModel = StateObject(wrappedValue: WeeklyViewModel(summary: appViewModel.getWeeklySummary()))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    // Header
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Text("Your Week in Reflection")
                            .h1()
                            .multilineTextAlignment(.center)
                        
                        Text(weeklyViewModel.weekRange)
                            .captionText()
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    // Tab selector
                    Picker("View", selection: $selectedTab) {
                        ForEach(WeeklyViewModel.WeeklyTab.allCases, id: \.self) { tab in
                            Text(tab.displayName).tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    // Content based on selected tab
                    switch selectedTab {
                    case .insights:
                        insightsContent
                    case .trends:
                        trendsContent
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.surface)
            .navigationTitle("Weekly")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Insights Content
    private var insightsContent: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            if weeklyViewModel.hasData {
                // Three main cards
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Wins card
                    InsightCard(
                        title: "Wins",
                        icon: "checkmark.circle.fill",
                        color: DesignTokens.Colors.success,
                        items: weeklyViewModel.summary.wins
                    )
                    
                    // Stressors card
                    InsightCard(
                        title: "Stressors",
                        icon: "exclamationmark.triangle.fill",
                        color: DesignTokens.Colors.warning,
                        items: weeklyViewModel.summary.stressors
                    )
                    
                    // Try Next card
                    InsightCard(
                        title: "Try Next",
                        icon: "lightbulb.fill",
                        color: DesignTokens.Colors.primary,
                        items: weeklyViewModel.summary.tryNext
                    )
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                
                // CTA
                Button(action: {
                    // TODO: Switch to Journal tab
                }) {
                    Text("See Example Entries")
                        .primaryButton()
                }
                .padding(.horizontal, DesignTokens.Spacing.xxxl)
            } else {
                EmptyState(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No insights yet",
                    message: "Keep journaling to see your weekly insights and patterns.",
                    actionTitle: "Start Journaling"
                ) {
                    // TODO: Switch to Home tab
                }
            }
        }
    }
    
    // MARK: - Trends Content
    private var trendsContent: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Mood trend chart
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                Text("Mood Trend")
                    .h2()
                
                VStack(spacing: DesignTokens.Spacing.md) {
                    // Chart placeholder
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(DesignTokens.Colors.card)
                        .frame(height: 120)
                        .overlay(
                            VStack {
                                Text("📈")
                                    .font(.system(size: 32))
                                Text("Mood trend visualization")
                                    .captionText()
                            }
                        )
                    
                    // Summary
                    HStack {
                        Text("Average: \(weeklyViewModel.moodDescription)")
                            .captionText()
                        
                        Spacer()
                        
                        Text("\(Int(weeklyViewModel.averageMood * 100))% positive")
                            .captionText()
                            .foregroundColor(DesignTokens.Colors.success)
                    }
                }
            }
            .cardBackground()
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            // Tag frequency
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                Text("Most Common Topics")
                    .h2()
                
                VStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(weeklyViewModel.topTags, id: \.0) { tag, count in
                        HStack {
                            Text(tag.capitalized)
                                .bodyText()
                            
                            Spacer()
                            
                            Text("\(count)")
                                .captionText()
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            // Bar visualization
                            RoundedRectangle(cornerRadius: 2)
                                .fill(DesignTokens.Colors.primary)
                                .frame(width: CGFloat(count) * 20, height: 4)
                        }
                    }
                }
            }
            .cardBackground()
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let title: String
    let icon: String
    let color: Color
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                
                Text(title)
                    .h2()
                
                Spacer()
            }
            
            if items.isEmpty {
                Text("No \(title.lowercased()) this week")
                    .bodyText()
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                            Text("•")
                                .foregroundColor(color)
                            
                            Text(item)
                                .bodyText()
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .cardBackground()
    }
}

// MARK: - Preview
#Preview {
    WeeklyView(appViewModel: AppViewModel())
}
