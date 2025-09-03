import SwiftUI


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

                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        HStack {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(DesignTokens.Colors.primary)
                                    .font(.system(size: 18, weight: .medium))

                                Text("AI Reflection")
                                    .h2()
                            }

                            Spacer()

                            
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Circle()
                                    .fill(DesignTokens.Colors.success)
                                    .frame(width: 8, height: 8)

                                Text("Active")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(DesignTokens.Colors.success)
                            }
                        }

                        
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                            
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                DesignTokens.Colors.primary,
                                                DesignTokens.Colors.primary.opacity(0.7),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)

                                Image(systemName: "sparkles")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .medium))
                            }

                            
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                Text(
                                    counselorReply.isEmpty
                                        ? generateCounselorReply() : counselorReply
                                )
                                .bodyText()
                                .multilineTextAlignment(.leading)

                                
                                HStack {
                                    Text("Wavelength AI")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(DesignTokens.Colors.primary)

                                    Spacer()

                                    Text("Just now")
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                            }
                            .padding(DesignTokens.Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                    .fill(DesignTokens.Colors.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        DesignTokens.Colors.primary.opacity(0.3),
                                                        DesignTokens.Colors.primary.opacity(0.1),
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )

                            Spacer()
                        }
                    }
                    .cardBackground()
                    .padding(.horizontal, DesignTokens.Spacing.lg)

                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("Tags & Feeling")
                            .h2()

                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            Text("Tags")
                                .bodyText()
                                .foregroundColor(DesignTokens.Colors.textSecondary)

                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible()), count: 3),
                                spacing: DesignTokens.Spacing.sm
                            ) {
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
                                                backgroundColor: feeling == feelingOption
                                                    ? Color(hex: feelingOption.color)
                                                    : DesignTokens.Colors.border,
                                                textColor: feeling == feelingOption
                                                    ? .white : DesignTokens.Colors.textPrimary
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
                        
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        saveEntry()
                    }
                    .foregroundColor(DesignTokens.Colors.primary)
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .onAppear {
            
            let aiService = AIService.shared
            let sentimentAnalysis = aiService.analyzeSentiment(transcript)
            feeling = sentimentAnalysis.feeling

            counselorReply = generateCounselorReply()
            tags = extractTags(from: transcript)
        }
    }

    
    private func generateCounselorReply() -> String {
        
        let aiService = AIService.shared
        return aiService.generateCounselorReply(for: transcript, feeling: feeling)
    }

    private func extractTags(from text: String) -> [String] {
        
        let aiService = AIService.shared
        return aiService.extractTags(from: text)
    }

    private var suggestedTags: [String] {
        let allTags = [
            "work", "family", "anxiety", "sleep", "exercise", "creativity", "stress", "joy",
            "reflection", "gratitude", "challenge", "growth",
        ]
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


#Preview {
    ReflectionView(
        transcript:
            "I'm feeling a bit overwhelmed today. Work has been really busy and I haven't had much time for myself. I think I need to set better boundaries.",
        appViewModel: AppViewModel(),
        isPresented: .constant(true)
    )
}
