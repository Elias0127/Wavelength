import Foundation

@MainActor
class ConversationSummarizationService: ObservableObject {
    static let shared = ConversationSummarizationService()

    private let apiBaseURL = "http://10.0.0.188:3000"

    private init() {}

    func summarizeConversation(_ turns: [ConversationTurn]) async throws -> ConversationSummary {
        guard !turns.isEmpty else {
            throw SummarizationError.emptyConversation
        }

        // Build conversation transcript
        let conversationText = buildConversationText(from: turns)

        // Call OpenAI API to summarize
        let summary = try await callOpenAISummarization(conversationText: conversationText)

        return summary
    }

    private func buildConversationText(from turns: [ConversationTurn]) -> String {
        var conversationText = ""

        for turn in turns {
            // Add user transcript
            conversationText += "User: \(turn.userTranscript)\n\n"

            // Add AI response if available
            if let aiResponse = turn.assistantResponse {
                conversationText += "AI: \(aiResponse)\n\n"
            }
        }

        return conversationText
    }

    private func callOpenAISummarization(conversationText: String) async throws
        -> ConversationSummary
    {
        let url = URL(string: "\(apiBaseURL)/api/openai/summarize-conversation")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ConversationSummarizationRequest(
            conversation: conversationText,
            instructions: """
                You are a compassionate AI assistant helping someone create a personal journal entry from their therapy conversation. 

                Please analyze the conversation and create a first-person journal entry that:
                1. Captures the main themes and emotions discussed
                2. Reflects on the insights gained during the conversation
                3. Is written in the first person as if the person is writing their own journal
                4. Includes a meaningful title that captures the essence of the conversation
                5. Ends with an overall emotional state assessment
                6. Feels personal, reflective, and therapeutic
                7. Maintains the person's voice and perspective throughout

                The journal entry should feel like a natural reflection that the person would write themselves after having this conversation.
                """
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw SummarizationError.apiError("Failed to summarize conversation")
        }

        let summary = try JSONDecoder().decode(ConversationSummary.self, from: data)
        return summary
    }
}

// MARK: - Data Models

struct ConversationSummarizationRequest: Codable {
    let conversation: String
    let instructions: String
}

struct ConversationSummary: Codable {
    let title: String
    let content: String
    let emotionalState: String
    let tags: [String]
    let overallMood: String
    let date: Date

    init(
        title: String, content: String, emotionalState: String, tags: [String], overallMood: String,
        date: Date = Date()
    ) {
        self.title = title
        self.content = content
        self.emotionalState = emotionalState
        self.tags = tags
        self.overallMood = overallMood
        self.date = date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        emotionalState = try container.decode(String.self, forKey: .emotionalState)
        tags = try container.decode([String].self, forKey: .tags)
        overallMood = try container.decode(String.self, forKey: .overallMood)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
    }

    private enum CodingKeys: String, CodingKey {
        case title, content, emotionalState, tags, overallMood, date
    }
}

enum SummarizationError: Error, LocalizedError {
    case emptyConversation
    case apiError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .emptyConversation:
            return "No conversation to summarize"
        case .apiError(let message):
            return "API error: \(message)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
