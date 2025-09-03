import SwiftUI

// MARK: - Reflection View
struct ReflectionView: View {
    let transcript: String
    @ObservedObject var appViewModel: AppViewModel
    @Binding var isPresented: Bool
    @State private var counselorReply = ""
    @State private var tags: [String] = []
    @State private var feeling: Feeling = .neutral
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    // Transcript card
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("Your Words")
                            .h2()
                        
                        Text(transcript)
                            .bodyText()
                            .padding(DesignTokens.Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                    .fill(DesignTokens.Colors.card)
                            )
                    }
                    .cardBackground()
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    // Counselor reply card
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        HStack {
                            Text("Reflection")
                                .h2()
                            
                            Spacer()
                            
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(DesignTokens.Colors.primary)
                        }
                        
                        Text(counselorReply.isEmpty ? generateCounselorReply() : counselorReply)
                            .bodyText()
                            .padding(DesignTokens.Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                    .fill(DesignTokens.Colors.primary.opacity(0.1))
                            )
                    }
                    .cardBackground()
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    // Tags and feeling
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("Tags & Feeling")
                            .h2()
                        
                        // Tags
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            Text("Tags")
                                .bodyText()
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignTokens.Spacing.sm) {
                                ForEach(suggestedTags, id: \.self) { tag in
                                    TagChip(
                                        text: tag,
                                        isSelected: tags.contains(tag)
                                    ) {
                                        toggleTag(tag)
                                    }
                                }
                            }
                        }
                        
                        // Feeling
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            Text("How did you feel?")
                                .bodyText()
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            HStack(spacing: DesignTokens.Spacing.md) {
                                ForEach(Feeling.allCases) { feelingOption in
                                    Button(action: {
                                        feeling = feelingOption
                                    }) {
                                        Text(feelingOption.displayName)
                                            .pill(
                                                backgroundColor: feeling == feelingOption ? Color(hex: feelingOption.color) : DesignTokens.Colors.border,
                                                textColor: feeling == feelingOption ? .white : DesignTokens.Colors.textPrimary
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .cardBackground()
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
                .padding(.vertical, DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.surface)
            .navigationTitle("Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Discard") {
                        isPresented = false
                    }
                    .foregroundColor(DesignTokens.Colors.danger)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Entry") {
                        saveEntry()
                    }
                    .foregroundColor(DesignTokens.Colors.primary)
                }
            }
        }
        .onAppear {
            counselorReply = generateCounselorReply()
            tags = extractTags(from: transcript)
        }
    }
    
    // MARK: - Helper Methods
    private func generateCounselorReply() -> String {
        // TODO: call local LLM or template OARS
        let replies = [
            "It sounds like you're processing some important thoughts. What stands out most to you about this experience?",
            "I hear both challenge and resilience in your words. What might help you feel more supported right now?",
            "Thank you for sharing this with me. What's one small step you could take toward feeling better about this?",
            "Your awareness of these feelings is valuable. What would you like to explore further about this situation?"
        ]
        return replies.randomElement() ?? replies[0]
    }
    
    private func extractTags(from text: String) -> [String] {
        let commonTags = ["work", "family", "anxiety", "sleep", "exercise", "creativity", "stress", "joy", "reflection"]
        let lowercasedText = text.lowercased()
        
        return commonTags.filter { tag in
            lowercasedText.contains(tag)
        }
    }
    
    private var suggestedTags: [String] {
        let allTags = ["work", "family", "anxiety", "sleep", "exercise", "creativity", "stress", "joy", "reflection", "gratitude", "challenge", "growth"]
        return Array(Set(allTags + tags)).sorted()
    }
    
    private func toggleTag(_ tag: String) {
        if tags.contains(tag) {
            tags.removeAll { $0 == tag }
        } else {
            tags.append(tag)
        }
    }
    
    private func saveEntry() {
        let entry = Entry(
            title: generateTitle(from: transcript),
            transcript: transcript,
            counselorReply: counselorReply,
            tags: tags,
            feeling: feeling,
            valenceSeries: generateValenceSeries(),
            mode: appViewModel.mode
        )
        
        appViewModel.addEntry(entry)
        isPresented = false
    }
    
    private func generateTitle(from text: String) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let firstWords = Array(words.prefix(6))
        return firstWords.joined(separator: " ") + (words.count > 6 ? "..." : "")
    }
    
    private func generateValenceSeries() -> [Double] {
        // Generate mock valence data based on feeling
        let baseValence: Double
        switch feeling {
        case .calm:
            baseValence = 0.7
        case .tense:
            baseValence = 0.3
        case .neutral:
            baseValence = 0.5
        }
        
        return (0..<6).map { _ in
            baseValence + Double.random(in: -0.2...0.2)
        }.map { max(0, min(1, $0)) }
    }
}

// MARK: - Preview
#Preview {
    ReflectionView(
        transcript: "I'm feeling a bit overwhelmed today. Work has been really busy and I haven't had much time for myself. I think I need to set better boundaries.",
        appViewModel: AppViewModel(),
        isPresented: .constant(true)
    )
}
