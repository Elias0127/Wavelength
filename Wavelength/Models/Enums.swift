import Foundation

// MARK: - App Mode
enum Mode: String, CaseIterable, Identifiable, Codable {
    case privateMode = "private"
    case connected = "connected"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .privateMode:
            return "Private Mode"
        case .connected:
            return "Connected Mode"
        }
    }
    
    var description: String {
        switch self {
        case .privateMode:
            return "Nothing leaves your device"
        case .connected:
            return "Tone-aware empathy (opt-in)"
        }
    }
    
    var icon: String {
        switch self {
        case .privateMode:
            return "lock.fill"
        case .connected:
            return "globe"
        }
    }
}

// MARK: - Feeling
enum Feeling: String, CaseIterable, Identifiable, Codable {
    case calm = "calm"
    case tense = "tense"
    case neutral = "neutral"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .calm:
            return "Calm"
        case .tense:
            return "Tense"
        case .neutral:
            return "Neutral"
        }
    }
    
    var color: String {
        switch self {
        case .calm:
            return "#33D6A6"
        case .tense:
            return "#FF6B6B"
        case .neutral:
            return "#A8B0BF"
        }
    }
}

// MARK: - Tab Selection
enum TabSelection: String, CaseIterable {
    case home = "house.fill"
    case journal = "book.fill"
    case weekly = "chart.line.uptrend.xyaxis"
    case settings = "gearshape.fill"
    
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .journal:
            return "Journal"
        case .weekly:
            return "Weekly"
        case .settings:
            return "Settings"
        }
    }
}
