import Foundation

// MARK: - Journal Entry Model
struct Entry: Identifiable, Equatable, Hashable {
    let id: UUID
    var date: Date
    var title: String
    var transcript: String
    var counselorReply: String?
    var tags: [String]
    var feeling: Feeling
    var valenceSeries: [Double] // 0...1 for mini chart
    var mode: Mode
    var favorite: Bool
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        title: String,
        transcript: String,
        counselorReply: String? = nil,
        tags: [String] = [],
        feeling: Feeling = .neutral,
        valenceSeries: [Double] = [],
        mode: Mode = .privateMode,
        favorite: Bool = false
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.transcript = transcript
        self.counselorReply = counselorReply
        self.tags = tags
        self.feeling = feeling
        self.valenceSeries = valenceSeries
        self.mode = mode
        self.favorite = favorite
    }
    
    // MARK: - Computed Properties
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
    
    var averageValence: Double {
        guard !valenceSeries.isEmpty else { return 0.5 }
        return valenceSeries.reduce(0, +) / Double(valenceSeries.count)
    }
}

// MARK: - Weekly Summary Model
struct WeeklySummary: Identifiable {
    let id = UUID()
    let weekStart: Date
    let wins: [String]
    let stressors: [String]
    let tryNext: [String]
    let moodTrend: [Double]
    let tagFrequency: [String: Int]
    
    init(
        weekStart: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
        wins: [String] = [],
        stressors: [String] = [],
        tryNext: [String] = [],
        moodTrend: [Double] = [],
        tagFrequency: [String: Int] = [:]
    ) {
        self.weekStart = weekStart
        self.wins = wins
        self.stressors = stressors
        self.tryNext = tryNext
        self.moodTrend = moodTrend
        self.tagFrequency = tagFrequency
    }
}
