import Foundation
import SwiftUI


@MainActor
class WeeklyViewModel: ObservableObject {
    @Published var summary: WeeklySummary
    @Published var selectedTab: WeeklyTab = .insights
    
    enum WeeklyTab: String, CaseIterable {
        case insights = "insights"
        case trends = "trends"
        
        var displayName: String {
            switch self {
            case .insights:
                return "Insights"
            case .trends:
                return "Trends"
            }
        }
    }
    
    init(summary: WeeklySummary) {
        self.summary = summary
    }
    
    
    var weekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: summary.weekStart) ?? summary.weekStart
        return "\(formatter.string(from: summary.weekStart)) - \(formatter.string(from: endDate))"
    }
    
    var averageMood: Double {
        guard !summary.moodTrend.isEmpty else { return 0.5 }
        return summary.moodTrend.reduce(0, +) / Double(summary.moodTrend.count)
    }
    
    var moodDescription: String {
        switch averageMood {
        case 0.0..<0.3:
            return "Challenging week"
        case 0.3..<0.7:
            return "Mixed week"
        case 0.7...1.0:
            return "Positive week"
        default:
            return "Unknown"
        }
    }
    
    var topTags: [(String, Int)] {
        summary.tagFrequency.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }
    
    var hasData: Bool {
        !summary.wins.isEmpty || !summary.stressors.isEmpty || !summary.tryNext.isEmpty
    }
}
