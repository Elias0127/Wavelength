import SwiftUI


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
                    
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Text("Your Week in Reflection")
                            .h1()
                            .multilineTextAlignment(.center)
                        
                        Text(weeklyViewModel.weekRange)
                            .captionText()
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    
                    Picker("View", selection: $selectedTab) {
                        ForEach(WeeklyViewModel.WeeklyTab.allCases, id: \.self) { tab in
                            Text(tab.displayName).tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    
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
    
    
    private var insightsContent: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            if weeklyViewModel.hasData {
                
                VStack(spacing: DesignTokens.Spacing.lg) {
                    
                    InsightCard(
                        title: "Wins",
                        icon: "checkmark.circle.fill",
                        color: DesignTokens.Colors.success,
                        items: weeklyViewModel.summary.wins
                    )
                    
                    
                    InsightCard(
                        title: "Stressors",
                        icon: "exclamationmark.triangle.fill",
                        color: DesignTokens.Colors.warning,
                        items: weeklyViewModel.summary.stressors
                    )
                    
                    
                    InsightCard(
                        title: "Try Next",
                        icon: "lightbulb.fill",
                        color: DesignTokens.Colors.primary,
                        items: weeklyViewModel.summary.tryNext
                    )
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                
                
                Button(action: {
                    
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
                    
                }
            }
        }
    }
    
    
    private var trendsContent: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            
            MoodTrendChart(
                data: weeklyViewModel.summary.moodTrend,
                labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            )
            .cardBackground()
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            
            TagFrequencyChart(
                tagFrequency: weeklyViewModel.summary.tagFrequency,
                maxItems: 6
            )
            .cardBackground()
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                Text("Weekly Insights")
                    .h2()
                
                VStack(spacing: DesignTokens.Spacing.md) {
                    InsightRow(
                        icon: "calendar",
                        title: "Most Active Day",
                        value: "Wednesday",
                        color: DesignTokens.Colors.primary
                    )
                    
                    InsightRow(
                        icon: "clock",
                        title: "Peak Journaling Time",
                        value: "7:30 PM",
                        color: DesignTokens.Colors.success
                    )
                    
                    InsightRow(
                        icon: "heart.fill",
                        title: "Average Session",
                        value: "2.3 minutes",
                        color: DesignTokens.Colors.warning
                    )
                }
            }
            .cardBackground()
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
    }
}


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


struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .medium))
            }
            
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            
            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.surface)
        )
    }
}


#Preview {
    WeeklyView(appViewModel: AppViewModel())
}
