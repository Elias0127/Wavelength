import Foundation
import NaturalLanguage

@MainActor
class AIService: ObservableObject {
    static let shared = AIService()

    private let tagger = NLTagger(tagSchemes: [.sentimentScore, .lexicalClass, .nameType, .lemma])
    private let embedding = NLEmbedding.wordEmbedding(for: .english)
    private let languageRecognizer = NLLanguageRecognizer()

    private var conversationContext: ConversationContext = ConversationContext()

    private init() {}

    func analyzeAndRespond(to text: String, previousEntries: [Entry] = []) -> JournalAnalysis {

        let linguisticFeatures = extractLinguisticFeatures(from: text)

        let emotionalState = modelEmotionalState(from: text, features: linguisticFeatures)

        let patterns = detectPatterns(in: text, withHistory: previousEntries)

        let counselorResponse = generateContextualCounselorResponse(
            for: text,
            emotionalState: emotionalState,
            patterns: patterns,
            linguisticFeatures: linguisticFeatures
        )

        let insights = extractInsights(from: text, patterns: patterns)

        updateContext(with: text, emotionalState: emotionalState)

        return JournalAnalysis(
            feeling: emotionalState.primaryFeeling,
            sentimentScore: emotionalState.sentimentScore,
            valenceSeries: emotionalState.valenceSeries,
            counselorReply: counselorResponse,
            tags: extractSmartTags(from: text, features: linguisticFeatures),
            insights: insights,
            emotionalDepth: emotionalState.depth
        )
    }

    private func extractLinguisticFeatures(from text: String) -> LinguisticFeatures {
        var features = LinguisticFeatures()
        tagger.string = text

        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        features.sentenceComplexity = analyzeSentenceComplexity(sentences)

        features.temporalOrientation = analyzeTemporalOrientation(text)

        features.cognitiveDistortions = detectCognitiveDistortions(in: text)

        features.emotionalVocabularyRichness = measureEmotionalVocabulary(text)

        features.speechPatterns = analyzeSpeechPatterns(text)

        features.pronounUsage = analyzePronounUsage(text)

        return features
    }

    private func modelEmotionalState(from text: String, features: LinguisticFeatures)
        -> EmotionalState
    {
        var state = EmotionalState()

        let emotions = detectMultiDimensionalEmotions(text)
        state.emotionVector = emotions

        state.depth = calculateEmotionalDepth(text, features: features)

        state.transitions = detectEmotionalTransitions(text)

        let (arousal, valence) = mapArousalValence(emotions: emotions, features: features)
        state.arousal = arousal
        state.valence = valence

        state.primaryFeeling = classifyPrimaryFeeling(
            arousal: arousal, valence: valence, depth: state.depth)

        state.valenceSeries = generateRealisticValenceSeries(
            baseValence: valence,
            transitions: state.transitions,
            textLength: text.count
        )

        state.sentimentScore = calculateWeightedSentiment(text, emotions: emotions)

        return state
    }

    private func detectPatterns(in text: String, withHistory: [Entry]) -> [Pattern] {
        var patterns: [Pattern] = []

        if !withHistory.isEmpty {
            patterns.append(
                contentsOf: findRecurringThemes(currentText: text, history: withHistory))
        }

        patterns.append(contentsOf: detectEmotionalCycles(in: withHistory))

        patterns.append(contentsOf: identifyTriggers(currentText: text, history: withHistory))

        patterns.append(contentsOf: detectCopingMechanisms(in: text))

        patterns.append(
            contentsOf: identifyGrowthIndicators(currentText: text, history: withHistory))

        return patterns
    }

    private func generateContextualCounselorResponse(
        for text: String,
        emotionalState: EmotionalState,
        patterns: [Pattern],
        linguisticFeatures: LinguisticFeatures
    ) -> String {

        let crisisLevel = detectCrisisLevel(text.lowercased())
        if crisisLevel != .low {
            return generateCrisisResponse(level: crisisLevel, emotionalState: emotionalState)
        }

        let technique = selectOARSTechnique(
            emotionalState: emotionalState,
            patterns: patterns,
            features: linguisticFeatures
        )

        switch technique {
        case .openQuestion:
            return generateOpenQuestion(text: text, state: emotionalState, patterns: patterns)
        case .affirmation:
            return generateAffirmation(
                text: text, state: emotionalState, features: linguisticFeatures)
        case .reflection:
            return generateReflection(
                text: text, state: emotionalState, features: linguisticFeatures)
        case .summary:
            return generateSummary(patterns: patterns, state: emotionalState)
        }
    }

    private func generateOpenQuestion(text: String, state: EmotionalState, patterns: [Pattern])
        -> String
    {

        if state.depth == .surface && state.arousal > 0.7 {

            let questions = [
                "There's a lot of energy in what you're sharing. What's underneath that feeling for you?",
                "It sounds intense. If you had to name what you're really needing right now, what would it be?",
                "That's a strong reaction. What does this remind you of from your past?",
            ]
            return selectResponseVariation(questions, basedOn: text)
        }

        if patterns.contains(where: { $0.type == .recurringTheme }) {

            if let theme = patterns.first(where: { $0.type == .recurringTheme }) {
                return
                    "I notice \(theme.description) comes up often for you. What do you think that pattern is telling you?"
            }
        }

        if state.transitions.count > 2 {

            return
                "Your feelings seem to be shifting as you talk about this. What's the thread connecting these different emotions?"
        }

        if state.valence < 0.3 {
            return
                "This sounds really difficult. What would even a small step forward look like for you?"
        } else if state.valence > 0.7 {
            return "There's something meaningful here. What made this experience stand out for you?"
        } else {
            return "As you sit with these feelings, what are you learning about yourself?"
        }
    }

    private func generateAffirmation(
        text: String, state: EmotionalState, features: LinguisticFeatures
    ) -> String {

        var strengths: [String] = []

        if features.emotionalVocabularyRichness > 0.6 {
            strengths.append("self-awareness")
        }

        let resilienceWords = ["trying", "working on", "getting better", "improving", "learning"]
        if resilienceWords.contains(where: { text.lowercased().contains($0) }) {
            strengths.append("resilience")
        }

        if state.depth == .deep {
            strengths.append("vulnerability")
        }

        if strengths.contains("vulnerability") {
            return
                "Thank you for sharing something so personal. It takes real courage to look at these deeper feelings."
        } else if strengths.contains("resilience") {
            return
                "I can see how hard you're working on this. That persistence matters, even when progress feels slow."
        } else if strengths.contains("self-awareness") {
            return
                "You have such clear insight into what you're experiencing. That awareness is a real strength."
        } else {
            return
                "Taking time to reflect like this is an act of self-care. You're doing something important for yourself."
        }
    }

    private func generateReflection(
        text: String, state: EmotionalState, features: LinguisticFeatures
    ) -> String {

        if state.emotionVector.count > 2 && state.emotionVector.values.max()! < 0.6 {
            return
                "It sounds like you're feeling pulled in different directions - part of you feels \(state.primaryFeeling.displayName), but there's also something else there that's harder to name."
        }

        if let distortion = features.cognitiveDistortions.first {
            switch distortion {
            case .allOrNothing:
                return
                    "I'm hearing a lot of absolutes in how you're thinking about this. It sounds like it's been feeling very black and white."
            case .catastrophizing:
                return
                    "Your mind seems to be jumping to the worst-case scenario. That must feel overwhelming."
            case .mindReading:
                return
                    "It sounds like you're trying to figure out what others are thinking. That uncertainty can be really uncomfortable."
            case .personalization:
                return
                    "I notice you're taking a lot of responsibility for this situation. That's a heavy burden to carry alone."
            }
        }

        let needsReflection = reflectUnderlyingNeeds(text: text, state: state)
        if !needsReflection.isEmpty {
            return needsReflection
        }

        return
            "What I'm hearing is a deep sense of \(state.primaryFeeling.displayName), and it seems like this has been weighing on you for a while."
    }

    private func generateSummary(patterns: [Pattern], state: EmotionalState) -> String {

        var summary = "Looking at everything you've shared"

        if let growthPattern = patterns.first(where: { $0.type == .growth }) {
            summary += ", I see real growth in how you're \(growthPattern.description)"
        }

        if let copingPattern = patterns.first(where: { $0.type == .copingMechanism }) {
            summary +=
                ". You've found that \(copingPattern.description) helps you manage these feelings"
        }

        if state.valence < 0.4 {
            summary +=
                ", and while things feel heavy right now, you're still showing up and processing these experiences"
        } else if state.valence > 0.6 {
            summary += ", and there's a sense of momentum building in a positive direction"
        }

        summary += ". What stands out most to you about this pattern?"

        return summary
    }

    private func selectOARSTechnique(
        emotionalState: EmotionalState,
        patterns: [Pattern],
        features: LinguisticFeatures
    ) -> OARSTechnique {

        if patterns.count >= 3 {
            return .summary
        }

        if emotionalState.depth == .deep && conversationContext.responseCount % 3 == 1 {
            return .affirmation
        }

        if !features.cognitiveDistortions.isEmpty {
            return .reflection
        }

        return .openQuestion
    }

    private func calculateEmotionalDepth(_ text: String, features: LinguisticFeatures)
        -> EmotionalDepth
    {
        var depthScore = 0.0

        depthScore += features.emotionalVocabularyRichness * 0.3

        if features.pronounUsage.i > 0.3 {
            depthScore += 0.2
        }

        let vulnerabilityMarkers = ["afraid", "scared", "ashamed", "lonely", "hurt", "vulnerable"]
        if vulnerabilityMarkers.contains(where: { text.lowercased().contains($0) }) {
            depthScore += 0.3
        }

        let insightMarkers = ["realize", "understand", "notice", "feel like", "seems like"]
        if insightMarkers.contains(where: { text.lowercased().contains($0) }) {
            depthScore += 0.2
        }

        if depthScore > 0.6 {
            return .deep
        } else if depthScore > 0.3 {
            return .moderate
        } else {
            return .surface
        }
    }

    private func selectResponseVariation(_ responses: [String], basedOn text: String) -> String {

        let hash = text.hashValue
        let index = abs(hash) % responses.count
        return responses[index]
    }

    private func reflectUnderlyingNeeds(text: String, state: EmotionalState) -> String {

        let needsMap: [String: [String]] = [
            "anxious": ["safety", "certainty", "control"],
            "sad": ["connection", "understanding", "comfort"],
            "angry": ["respect", "fairness", "to be heard"],
            "overwhelmed": ["space", "support", "clarity"],
            "lonely": ["connection", "belonging", "to be seen"],
        ]

        for (emotion, needs) in needsMap {
            if text.lowercased().contains(emotion) {
                let need = needs.randomElement()!
                return "It sounds like underneath this, you're really needing \(need) right now."
            }
        }

        return ""
    }

    private func extractInsights(from text: String, patterns: [Pattern]) -> [Insight] {
        var insights: [Insight] = []

        if patterns.contains(where: { $0.type == .recurringTheme }) {
            insights.append(
                Insight(
                    type: .behavioral,
                    description: "You've identified a recurring pattern in your experiences",
                    actionable: true
                ))
        }

        if text.lowercased().contains("realize") || text.lowercased().contains("understand") {
            insights.append(
                Insight(
                    type: .cognitive,
                    description: "You're gaining new awareness about your situation",
                    actionable: true
                ))
        }

        return insights
    }

    private func updateContext(with text: String, emotionalState: EmotionalState) {
        conversationContext.responseCount += 1
        conversationContext.dominantEmotions.append(emotionalState.primaryFeeling.rawValue)

        if conversationContext.dominantEmotions.count > 10 {
            conversationContext.dominantEmotions.removeFirst()
        }
    }

    private func extractSmartTags(from text: String, features: LinguisticFeatures) -> [String] {
        var tags: [String] = []

        let emotionalKeywords = [
            "anxious", "sad", "happy", "angry", "overwhelmed", "calm", "stressed",
        ]
        for keyword in emotionalKeywords {
            if text.lowercased().contains(keyword) {
                tags.append(keyword)
            }
        }

        let topicKeywords = ["work", "family", "relationship", "health", "sleep", "exercise"]
        for keyword in topicKeywords {
            if text.lowercased().contains(keyword) {
                tags.append(keyword)
            }
        }

        return Array(Set(tags))
    }

    private func analyzeSentenceComplexity(_ sentences: [String]) -> Double {
        guard !sentences.isEmpty else { return 0.0 }

        let totalWords = sentences.reduce(0) { $0 + $1.components(separatedBy: .whitespaces).count }
        let avgWordsPerSentence = Double(totalWords) / Double(sentences.count)

        return min(1.0, max(0.0, (avgWordsPerSentence - 5) / 15))
    }

    private func analyzeTemporalOrientation(_ text: String) -> TemporalFocus {
        let pastWords = ["was", "were", "had", "did", "yesterday", "before", "ago"]
        let presentWords = ["am", "is", "are", "now", "today", "currently"]
        let futureWords = ["will", "going to", "tomorrow", "later", "next", "future"]

        let pastCount = pastWords.reduce(0) {
            $0 + (text.lowercased().components(separatedBy: $1).count - 1)
        }
        let presentCount = presentWords.reduce(0) {
            $0 + (text.lowercased().components(separatedBy: $1).count - 1)
        }
        let futureCount = futureWords.reduce(0) {
            $0 + (text.lowercased().components(separatedBy: $1).count - 1)
        }

        if pastCount > presentCount && pastCount > futureCount {
            return .past
        } else if futureCount > presentCount && futureCount > pastCount {
            return .future
        } else if presentCount > 0 {
            return .present
        } else {
            return .mixed
        }
    }

    private func detectCognitiveDistortions(in text: String) -> [CognitiveDistortion] {
        var distortions: [CognitiveDistortion] = []
        let lowercased = text.lowercased()

        if lowercased.contains("always") || lowercased.contains("never")
            || lowercased.contains("all") || lowercased.contains("none")
        {
            distortions.append(.allOrNothing)
        }

        if lowercased.contains("worst") || lowercased.contains("terrible")
            || lowercased.contains("disaster")
        {
            distortions.append(.catastrophizing)
        }

        if lowercased.contains("they think") || lowercased.contains("everyone thinks")
            || lowercased.contains("probably thinks")
        {
            distortions.append(.mindReading)
        }

        if lowercased.contains("my fault") || lowercased.contains("because of me")
            || lowercased.contains("I caused")
        {
            distortions.append(.personalization)
        }

        return distortions
    }

    private func measureEmotionalVocabulary(_ text: String) -> Double {
        let emotionalWords = [
            "happy", "sad", "angry", "anxious", "excited", "worried", "calm", "stressed",
            "overwhelmed", "frustrated", "grateful", "lonely", "confident", "scared",
            "proud", "ashamed", "hopeful", "hopeless", "content", "restless",
        ]

        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let emotionalWordCount = words.filter { emotionalWords.contains($0) }.count

        return min(1.0, Double(emotionalWordCount) / Double(words.count) * 10)
    }

    private func analyzeSpeechPatterns(_ text: String) -> SpeechPattern {
        var pattern = SpeechPattern()

        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let wordCounts = Dictionary(grouping: words, by: { $0.lowercased() })
        pattern.repetitions = wordCounts.values.filter { $0.count > 2 }.count

        let hesitationMarkers = ["um", "uh", "like", "you know"]
        pattern.hesitations = hesitationMarkers.reduce(0) {
            $0 + text.lowercased().components(separatedBy: $1).count - 1
        }

        let negationWords = ["not", "no", "never", "can't", "won't", "don't"]
        pattern.negations = negationWords.reduce(0) {
            $0 + text.lowercased().components(separatedBy: $1).count - 1
        }

        return pattern
    }

    private func analyzePronounUsage(_ text: String) -> PronounUsage {
        var usage = PronounUsage()
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let totalWords = Double(words.count)

        if totalWords > 0 {
            usage.i =
                Double(words.filter { $0 == "i" || $0 == "me" || $0 == "my" }.count) / totalWords
            usage.we =
                Double(words.filter { $0 == "we" || $0 == "us" || $0 == "our" }.count) / totalWords
            usage.they =
                Double(words.filter { $0 == "they" || $0 == "them" || $0 == "their" }.count)
                / totalWords
        }

        return usage
    }

    private func detectMultiDimensionalEmotions(_ text: String) -> [String: Double] {
        let emotionMap: [String: [String]] = [
            "joy": ["happy", "excited", "thrilled", "elated", "cheerful"],
            "sadness": ["sad", "depressed", "down", "blue", "melancholy"],
            "anger": ["angry", "mad", "furious", "irritated", "frustrated"],
            "fear": ["scared", "afraid", "worried", "anxious", "nervous"],
            "surprise": ["surprised", "shocked", "amazed", "astonished"],
            "disgust": ["disgusted", "revolted", "sickened"],
        ]

        var emotions: [String: Double] = [:]
        let lowercased = text.lowercased()

        for (emotion, keywords) in emotionMap {
            let count = keywords.reduce(0) {
                $0 + (lowercased.components(separatedBy: $1).count - 1)
            }
            if count > 0 {
                emotions[emotion] = min(1.0, Double(count) / 5.0)
            }
        }

        return emotions
    }

    private func detectEmotionalTransitions(_ text: String) -> [EmotionalTransition] {

        let transitionWords = ["but", "however", "although", "yet", "still", "though"]
        var transitions: [EmotionalTransition] = []

        let words = text.components(separatedBy: .whitespacesAndNewlines)
        for (index, word) in words.enumerated() {
            if transitionWords.contains(word.lowercased()) {
                transitions.append(
                    EmotionalTransition(
                        from: "previous",
                        to: "following",
                        position: index
                    ))
            }
        }

        return transitions
    }

    private func mapArousalValence(emotions: [String: Double], features: LinguisticFeatures) -> (
        Double, Double
    ) {

        let arousal = emotions.values.reduce(0, +) / Double(emotions.count)

        let positiveEmotions = ["joy", "excitement", "happiness"]
        let negativeEmotions = ["sadness", "anger", "fear", "disgust"]

        let positiveScore = positiveEmotions.compactMap { emotions[$0] }.reduce(0, +)
        let negativeScore = negativeEmotions.compactMap { emotions[$0] }.reduce(0, +)

        let valence = (positiveScore - negativeScore + 1) / 2

        return (arousal, valence)
    }

    private func classifyPrimaryFeeling(arousal: Double, valence: Double, depth: EmotionalDepth)
        -> Feeling
    {

        // More nuanced classification based on both arousal and valence
        if valence < 0.4 {
            return .tense
        } else if valence > 0.6 {
            return .calm
        } else {
            // In the middle range, consider arousal
            if arousal > 0.6 {
                return .tense
            } else if arousal < 0.4 {
                return .calm
            } else {
                return .neutral
            }
        }
    }

    private func generateRealisticValenceSeries(
        baseValence: Double, transitions: [EmotionalTransition], textLength: Int
    ) -> [Double] {
        var series: [Double] = []

        for i in 0..<6 {
            let variation = Double.random(in: -0.1...0.1)
            let timeVariation = sin(Double(i) * 0.5) * 0.05
            let valence = max(0.0, min(1.0, baseValence + variation + timeVariation))
            series.append(valence)
        }

        return series
    }

    private func calculateWeightedSentiment(_ text: String, emotions: [String: Double]) -> Double {

        tagger.string = text
        var sentimentScore: Double = 0.0

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore
        ) { tag, range in
            if let tag = tag {
                sentimentScore = Double(tag.rawValue) ?? 0.0
            }
            return true
        }

        let emotionalIntensity = emotions.values.reduce(0, +) / Double(emotions.count)
        return sentimentScore * (0.5 + emotionalIntensity * 0.5)
    }

    private func findRecurringThemes(currentText: String, history: [Entry]) -> [Pattern] {

        var patterns: [Pattern] = []
        let currentWords = Set(
            currentText.lowercased().components(separatedBy: .whitespacesAndNewlines))

        for entry in history.prefix(5) {
            let entryWords = Set(
                entry.transcript.lowercased().components(separatedBy: .whitespacesAndNewlines))
            let commonWords = currentWords.intersection(entryWords)

            if commonWords.count > 3 {
                patterns.append(
                    Pattern(
                        type: .recurringTheme,
                        description: "Recurring themes in your journaling",
                        confidence: Double(commonWords.count) / 10.0
                    ))
            }
        }

        return patterns
    }

    private func detectEmotionalCycles(in history: [Entry]) -> [Pattern] {

        var patterns: [Pattern] = []

        if history.count >= 3 {
            let recentFeelings = history.prefix(3).map { $0.feeling }
            if Set(recentFeelings).count == 1 {
                patterns.append(
                    Pattern(
                        type: .emotionalCycle,
                        description: "Consistent emotional pattern",
                        confidence: 0.7
                    ))
            }
        }

        return patterns
    }

    private func identifyTriggers(currentText: String, history: [Entry]) -> [Pattern] {

        var patterns: [Pattern] = []
        let triggerWords = ["work", "family", "money", "health", "relationship"]

        for trigger in triggerWords {
            if currentText.lowercased().contains(trigger) {
                patterns.append(
                    Pattern(
                        type: .trigger,
                        description: "\(trigger.capitalized) appears to be a trigger",
                        confidence: 0.6
                    ))
            }
        }

        return patterns
    }

    private func detectCopingMechanisms(in text: String) -> [Pattern] {
        var patterns: [Pattern] = []
        let copingWords = ["exercise", "meditation", "talking", "music", "walking", "breathing"]

        for coping in copingWords {
            if text.lowercased().contains(coping) {
                patterns.append(
                    Pattern(
                        type: .copingMechanism,
                        description: "Using \(coping) as a coping mechanism",
                        confidence: 0.8
                    ))
            }
        }

        return patterns
    }

    private func identifyGrowthIndicators(currentText: String, history: [Entry]) -> [Pattern] {
        var patterns: [Pattern] = []
        let growthWords = ["learning", "growing", "improving", "better", "progress", "realize"]

        for growth in growthWords {
            if currentText.lowercased().contains(growth) {
                patterns.append(
                    Pattern(
                        type: .growth,
                        description: "Showing signs of personal growth",
                        confidence: 0.7
                    ))
            }
        }

        return patterns
    }

    private func detectCrisisLevel(_ text: String) -> CrisisLevel {

        let immediateRiskKeywords = [
            "taking my life", "kill myself", "end my life", "suicide", "kill me",
            "want to die", "ready to die", "going to die", "end it all",
            "hurt myself", "harm myself", "cut myself", "overdose", "jump off",
        ]

        let highRiskKeywords = [
            "not worth living", "nothing to live for", "better off dead",
            "world would be better without me", "everyone would be happier",
            "can't go on", "give up", "hopeless", "worthless", "burden",
        ]

        let moderateRiskKeywords = [
            "depressed", "suicidal thoughts", "thinking about death",
            "don't want to be here", "tired of living", "life is pointless",
            "no point in living", "wish I was dead", "want to disappear",
        ]

        if immediateRiskKeywords.contains(where: { text.contains($0) }) {
            return .immediate
        }

        if highRiskKeywords.contains(where: { text.contains($0) }) {
            return .high
        }

        if moderateRiskKeywords.contains(where: { text.contains($0) }) {
            return .moderate
        }

        return .low
    }

    private func generateCrisisResponse(level: CrisisLevel, emotionalState: EmotionalState)
        -> String
    {
        switch level {
        case .immediate:
            return """
                🚨 I'm very concerned about what you're sharing. Your safety is the most important thing right now.

                Please reach out for help immediately:
                • Call 988 (Suicide & Crisis Lifeline) - available 24/7
                • Text HOME to 741741 (Crisis Text Line)
                • Go to your nearest emergency room
                • Call 911 if you're in immediate danger

                You are not alone, and these feelings can change. Please stay safe and reach out for support.
                """
        case .high:
            return """
                I'm deeply concerned about what you're experiencing. These feelings of hopelessness are real and valid, but they don't have to be permanent.

                Please consider reaching out for support:
                • 988 Suicide & Crisis Lifeline (call or text)
                • Crisis Text Line: Text HOME to 741741
                • National Suicide Prevention Lifeline: 1-800-273-8255

                You matter, and there are people who want to help you through this. Would you be willing to talk to someone about how you're feeling?
                """
        case .moderate:
            return """
                I hear how much pain you're in right now. Depression can make everything feel overwhelming and hopeless, but these feelings are treatable.

                You're not alone in this. Many people have felt this way and found their way through with support. 

                Would you consider:
                • Talking to a mental health professional
                • Reaching out to a trusted friend or family member
                • Calling 988 if you need immediate support

                What's one small thing that might help you feel even slightly better right now?
                """
        case .low:
            return
                "Thank you for sharing that with me. How are you feeling about what you just expressed?"
        }
    }

    func analyzeSentiment(_ text: String) -> SentimentAnalysis {
        // Return neutral for empty text
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return SentimentAnalysis(
                feeling: .neutral,
                sentimentScore: 0.5,
                valenceSeries: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
            )
        }

        let analysis = analyzeAndRespond(to: text)
        return SentimentAnalysis(
            feeling: analysis.feeling,
            sentimentScore: analysis.sentimentScore,
            valenceSeries: analysis.valenceSeries
        )
    }

    func extractTags(from text: String) -> [String] {
        // Don't extract tags from empty text
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let analysis = analyzeAndRespond(to: text)
        return analysis.tags
    }

    func generateCounselorReply(for text: String, feeling: Feeling) -> String {
        // Don't generate response for empty text
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
                "I didn't catch any words in your recording. Please try speaking again or check your microphone settings."
        }

        let analysis = analyzeAndRespond(to: text)
        return analysis.counselorReply
    }
}

struct JournalAnalysis {
    let feeling: Feeling
    let sentimentScore: Double
    let valenceSeries: [Double]
    let counselorReply: String
    let tags: [String]
    let insights: [Insight]
    let emotionalDepth: EmotionalDepth
}

struct LinguisticFeatures {
    var sentenceComplexity: Double = 0.0
    var temporalOrientation: TemporalFocus = .present
    var cognitiveDistortions: [CognitiveDistortion] = []
    var emotionalVocabularyRichness: Double = 0.0
    var speechPatterns: SpeechPattern = SpeechPattern()
    var pronounUsage: PronounUsage = PronounUsage()
}

struct EmotionalState {
    var primaryFeeling: Feeling = .neutral
    var sentimentScore: Double = 0.0
    var valenceSeries: [Double] = []
    var emotionVector: [String: Double] = [:]
    var depth: EmotionalDepth = .surface
    var transitions: [EmotionalTransition] = []
    var arousal: Double = 0.5
    var valence: Double = 0.5
}

struct ConversationContext {
    var responseCount: Int = 0
    var dominantEmotions: [String] = []
    var recentPatterns: [Pattern] = []
}

struct Pattern {
    let type: PatternType
    let description: String
    let confidence: Double
}

struct Insight {
    let type: InsightType
    let description: String
    let actionable: Bool
}

struct EmotionalTransition {
    let from: String
    let to: String
    let position: Int
}

struct SpeechPattern {
    var repetitions: Int = 0
    var hesitations: Int = 0
    var negations: Int = 0
}

struct PronounUsage {
    var i: Double = 0.0
    var we: Double = 0.0
    var they: Double = 0.0
}

enum OARSTechnique {
    case openQuestion
    case affirmation
    case reflection
    case summary
}

enum EmotionalDepth {
    case surface
    case moderate
    case deep
}

enum TemporalFocus {
    case past
    case present
    case future
    case mixed
}

enum CognitiveDistortion {
    case allOrNothing
    case catastrophizing
    case mindReading
    case personalization
}

enum PatternType {
    case recurringTheme
    case emotionalCycle
    case trigger
    case copingMechanism
    case growth
}

enum InsightType {
    case behavioral
    case emotional
    case cognitive
    case relational
}

enum CrisisLevel {
    case immediate
    case high
    case moderate
    case low
}

struct SentimentAnalysis {
    let feeling: Feeling
    let sentimentScore: Double
    let valenceSeries: [Double]
}
