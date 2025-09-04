import Foundation

// MARK: - App Mode
enum Mode: String, CaseIterable, Identifiable, Codable {
    case privateMode = "private"
    case connected = "connected"
    case connectedMode = "connectedMode"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .privateMode:
            return "Private Mode"
        case .connected:
            return "Connected Mode"
        case .connectedMode:
            return "AI Conversation"
        }
    }

    var description: String {
        switch self {
        case .privateMode:
            return "Nothing leaves your device"
        case .connected:
            return "Tone-aware empathy (opt-in)"
        case .connectedMode:
            return "AI conversation reflection"
        }
    }

    var icon: String {
        switch self {
        case .privateMode:
            return "lock.fill"
        case .connected:
            return "globe"
        case .connectedMode:
            return "brain.head.profile"
        }
    }
}

// MARK: - Feeling
enum Feeling: String, CaseIterable, Identifiable, Codable {
    case calm = "calm"
    case tense = "tense"
    case neutral = "neutral"
    case happy = "happy"
    case sad = "sad"
    case anxious = "anxious"
    case grateful = "grateful"
    case overwhelmed = "overwhelmed"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .calm:
            return "Calm"
        case .tense:
            return "Tense"
        case .neutral:
            return "Neutral"
        case .happy:
            return "Happy"
        case .sad:
            return "Sad"
        case .anxious:
            return "Anxious"
        case .grateful:
            return "Grateful"
        case .overwhelmed:
            return "Overwhelmed"
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
        case .happy:
            return "#FFD93D"
        case .sad:
            return "#6C7CE7"
        case .anxious:
            return "#FF8A80"
        case .grateful:
            return "#81C784"
        case .overwhelmed:
            return "#FFB74D"
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
