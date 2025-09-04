import Foundation

// MARK: - API Response Models

struct OpenAISessionResponse: Codable, Equatable {
    let token: String
    let sessionId: String
}

// MARK: - Prosody Models

struct ProsodySnapshot: Codable, Equatable {
    let timestamp: Date
    let transcript: String
    let prosody: ProsodyData
    let assistant: String?
    let tags: [String]

    init(transcript: String, prosody: ProsodyData, assistant: String? = nil, tags: [String] = []) {
        self.timestamp = Date()
        self.transcript = transcript
        self.prosody = prosody
        self.assistant = assistant
        self.tags = tags
    }
}

struct ProsodyData: Codable, Equatable {
    let arousal: Double  // 0.0 to 1.0 (calm to excited)
    let valence: Double  // -1.0 to 1.0 (negative to positive)
    let energy: Double  // 0.0 to 1.0 (low to high energy)
    let events: [String]  // Specific events like "tightness", "pause", etc.

    init(arousal: Double = 0.5, valence: Double = 0.0, energy: Double = 0.5, events: [String] = [])
    {
        self.arousal = max(0.0, min(1.0, arousal))
        self.valence = max(-1.0, min(1.0, valence))
        self.energy = max(0.0, min(1.0, energy))
        self.events = events
    }
}

// MARK: - Conversation State Models

enum ConversationState: Equatable {
    case idle
    case listening
    case transcribing
    case analyzing
    case responding
    case error(String)

    static func == (lhs: ConversationState, rhs: ConversationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
            (.listening, .listening),
            (.transcribing, .transcribing),
            (.analyzing, .analyzing),
            (.responding, .responding):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

enum TurnBoundary {
    case userStart
    case userEnd
    case assistantStart
    case assistantEnd
}

struct ConversationTurn: Equatable {
    let id: UUID
    let userTranscript: String
    let prosodySnapshot: ProsodySnapshot?
    let assistantResponse: String?
    let timestamp: Date
    let duration: TimeInterval

    init(
        userTranscript: String, prosodySnapshot: ProsodySnapshot? = nil,
        assistantResponse: String? = nil, duration: TimeInterval = 0
    ) {
        self.id = UUID()
        self.userTranscript = userTranscript
        self.prosodySnapshot = prosodySnapshot
        self.assistantResponse = assistantResponse
        self.timestamp = Date()
        self.duration = duration
    }
}

// MARK: - Audio Configuration

struct AudioConfig {
    static let sampleRate: Int = 16000
    static let channels: Int = 1
    static let bitDepth: Int = 16
    static let silenceThreshold: TimeInterval = 0.5  // 500ms
    static let stabilityThreshold: TimeInterval = 0.4  // 400ms
    static let chunkDuration: TimeInterval = 0.5  // 0.5 seconds for OpenAI
}

// MARK: - UI State Models

struct LiveCaptionState: Equatable {
    let partialText: String
    let isFinalized: Bool
    let confidence: Double
    let wordCount: Int
    let speakingRate: Double  // words per minute
}

struct EmotionStripState: Equatable {
    let arousal: Double
    let valence: Double
    let energy: Double
    let trend: EmotionTrend
    let lastUpdate: Date
}

enum EmotionTrend: Equatable {
    case increasing
    case decreasing
    case stable
}

// MARK: - Error Models

enum ConnectedModeError: Error, LocalizedError {
    case apiKeyMissing
    case networkError(String)
    case audioCaptureFailed(String)
    case websocketConnectionFailed(String)
    case transcriptionFailed(String)
    case prosodyAnalysisFailed(String)
    case openAIError(String)

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "API keys not configured"
        case .networkError(let message):
            return "Network error: \(message)"
        case .audioCaptureFailed(let message):
            return "Audio capture failed: \(message)"
        case .websocketConnectionFailed(let message):
            return "WebSocket connection failed: \(message)"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .prosodyAnalysisFailed(let message):
            return "Prosody analysis failed: \(message)"
        case .openAIError(let message):
            return "OpenAI error: \(message)"
        }
    }
}
