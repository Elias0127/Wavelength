import Foundation

// MARK: - Mock Data
struct MockEntries {
    
    static let seed: [Entry] = [
        Entry(
            title: "Work Review Anxiety",
            transcript: "I'm anxious about tomorrow's review. I keep imagining the worst scenarios and can't seem to focus on anything else today. What if they think I'm not performing well enough?",
            counselorReply: "Sounds like tomorrow's review feels heavy—especially the 'what-ifs.' What might make it 10% calmer? Sometimes naming our fears helps them feel less overwhelming.",
            tags: ["work", "anxiety", "review"],
            feeling: .tense,
            valenceSeries: [0.2, 0.15, 0.1, 0.25, 0.3, 0.2],
            mode: .privateMode
        ),
        
        Entry(
            title: "Morning Walk Clarity",
            transcript: "Took a walk this morning and felt so much clearer about everything. The fresh air really helped me think through the project challenges. I feel more confident about my approach now.",
            counselorReply: "It's wonderful how movement can shift our perspective. What was it about the walk that helped you feel more confident?",
            tags: ["exercise", "clarity", "confidence"],
            feeling: .calm,
            valenceSeries: [0.6, 0.7, 0.75, 0.8, 0.85, 0.8],
            mode: .connected
        ),
        
        Entry(
            title: "Family Dinner",
            transcript: "Had dinner with family tonight. It was nice to catch up, though I felt a bit disconnected. Everyone seems to have their lives figured out while I'm still figuring things out.",
            counselorReply: "Comparison can be really tough, especially with family. What's one thing you're proud of in your own journey right now?",
            tags: ["family", "comparison", "reflection"],
            feeling: .neutral,
            valenceSeries: [0.4, 0.5, 0.45, 0.4, 0.5, 0.45],
            mode: .privateMode
        ),
        
        Entry(
            title: "Sleep Struggles",
            transcript: "Another night of poor sleep. I keep waking up at 3 AM with racing thoughts. Tried meditation but my mind won't quiet down. Feeling exhausted.",
            counselorReply: "Sleep struggles can really impact everything else. What's one small thing that's helped you wind down before?",
            tags: ["sleep", "stress", "meditation"],
            feeling: .tense,
            valenceSeries: [0.3, 0.2, 0.25, 0.3, 0.2, 0.25],
            mode: .privateMode
        ),
        
        Entry(
            title: "Creative Breakthrough",
            transcript: "Had a breakthrough on the design project today! Everything just clicked and I felt so in flow. It's been a while since I felt that creative energy.",
            counselorReply: "That flow state is such a gift when it arrives. What do you think helped create the conditions for that breakthrough?",
            tags: ["creativity", "flow", "work"],
            feeling: .calm,
            valenceSeries: [0.7, 0.8, 0.85, 0.9, 0.85, 0.8],
            mode: .connected
        ),
        
        Entry(
            title: "Weekend Plans",
            transcript: "Looking forward to the weekend but also feeling a bit overwhelmed by all the things I want to do. Need to find balance between rest and productivity.",
            counselorReply: "That tension between rest and productivity is so common. What would 'just enough' rest look like for you this weekend?",
            tags: ["weekend", "balance", "planning"],
            feeling: .neutral,
            valenceSeries: [0.5, 0.6, 0.55, 0.5, 0.6, 0.55],
            mode: .privateMode
        )
    ]
    
    static let weeklySummary = WeeklySummary(
        wins: [
            "Completed the design project ahead of schedule",
            "Maintained a 3-day exercise streak",
            "Had a meaningful conversation with a friend"
        ],
        stressors: [
            "Work review anxiety",
            "Sleep disturbances",
            "Feeling behind on personal goals"
        ],
        tryNext: [
            "Try a 5-minute breathing exercise before bed",
            "Schedule 10 minutes of planning each morning",
            "Set one small boundary at work this week"
        ],
        moodTrend: [0.3, 0.4, 0.6, 0.5, 0.7, 0.6, 0.5],
        tagFrequency: [
            "work": 3,
            "anxiety": 2,
            "exercise": 1,
            "family": 1,
            "sleep": 1,
            "creativity": 1
        ]
    )
    
    static let dailyPrompts = [
        "What's one thing you're grateful for today?",
        "How are you feeling right now, in this moment?",
        "What's been on your mind lately?",
        "What would you like to let go of today?",
        "What's one small win you had this week?",
        "How did you take care of yourself today?",
        "What's something you learned about yourself recently?"
    ]
    
    static func randomPrompt() -> String {
        dailyPrompts.randomElement() ?? dailyPrompts[0]
    }
}
