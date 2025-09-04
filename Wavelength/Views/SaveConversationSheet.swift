import SwiftUI

struct SaveConversationSheet: View {
    let conversationTurns: [ConversationTurn]
    let onSave: (Entry) -> Void
    let onCancel: () -> Void

    @StateObject private var summarizationService = ConversationSummarizationService.shared
    @State private var isSummarizing = false
    @State private var summary: ConversationSummary?
    @State private var errorMessage: String?
    @State private var selectedFeeling: Feeling = .neutral
    @State private var customTitle = ""
    @State private var customTags: [String] = []
    @State private var newTag = ""
    @State private var showContent = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignTokens.Colors.surface
                    .ignoresSafeArea()

                if isSummarizing {
                    // Loading state
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.primary.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .scaleEffect(showContent ? 1.1 : 1.0)
                                .animation(
                                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                                    value: showContent)

                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 50))
                                .foregroundColor(DesignTokens.Colors.primary)
                        }

                        VStack(spacing: DesignTokens.Spacing.md) {
                            Text("Reflecting on Your Conversation")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Text("AI is crafting your personal journal reflection...")
                                .font(.body)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                } else if let summary = summary {
                    // Journal document view
                    ScrollView {
                        VStack(spacing: 0) {
                            // Journal header
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                                // Date and time
                                HStack {
                                    Text(summary.date, style: .date)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(DesignTokens.Colors.textSecondary)

                                    Spacer()

                                    Text(summary.date, style: .time)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }

                                // Title
                                Text(customTitle.isEmpty ? summary.title : customTitle)
                                    .font(.system(size: 32, weight: .bold, design: .serif))
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                    .lineSpacing(4)

                                // Divider
                                Rectangle()
                                    .fill(DesignTokens.Colors.border.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.vertical, DesignTokens.Spacing.md)
                            }
                            .padding(.horizontal, DesignTokens.Spacing.xl)
                            .padding(.top, DesignTokens.Spacing.xl)

                            // Journal content - Document style
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                                // Main reflection content
                                Text(summary.content)
                                    .font(.system(size: 18, weight: .regular, design: .serif))
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                    .lineSpacing(8)
                                    .padding(.horizontal, DesignTokens.Spacing.xl)

                                // Emotional state section
                                if !summary.emotionalState.isEmpty {
                                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                                        // Divider
                                        Rectangle()
                                            .fill(DesignTokens.Colors.border.opacity(0.3))
                                            .frame(height: 1)
                                            .padding(.horizontal, DesignTokens.Spacing.xl)

                                        // Emotional state content
                                        VStack(
                                            alignment: .leading, spacing: DesignTokens.Spacing.sm
                                        ) {
                                            HStack(spacing: DesignTokens.Spacing.sm) {
                                                Circle()
                                                    .fill(Color(hex: selectedFeeling.color))
                                                    .frame(width: 12, height: 12)

                                                Text("Overall Emotional State")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(
                                                        DesignTokens.Colors.textSecondary)
                                            }

                                            Text(summary.emotionalState)
                                                .font(
                                                    .system(
                                                        size: 16, weight: .medium, design: .serif)
                                                )
                                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                                .lineSpacing(4)
                                        }
                                        .padding(.horizontal, DesignTokens.Spacing.xl)
                                    }
                                }

                                // Signature line
                                VStack(alignment: .trailing, spacing: DesignTokens.Spacing.sm) {
                                    Rectangle()
                                        .fill(DesignTokens.Colors.border.opacity(0.3))
                                        .frame(height: 1)
                                        .padding(.horizontal, DesignTokens.Spacing.xl)

                                    HStack {
                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("Reflection by Wavelength AI")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(DesignTokens.Colors.textSecondary)

                                            Text(summary.date, style: .date)
                                                .font(.system(size: 11))
                                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                        }
                                    }
                                    .padding(.horizontal, DesignTokens.Spacing.xl)
                                }
                            }

                            // Customization section
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                                Rectangle()
                                    .fill(DesignTokens.Colors.border.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.horizontal, DesignTokens.Spacing.xl)
                                    .padding(.top, DesignTokens.Spacing.xl)

                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                                    Text("Customize Your Entry")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                        .padding(.horizontal, DesignTokens.Spacing.xl)

                                    // Title editing
                                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                        Text("Title")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(DesignTokens.Colors.textSecondary)

                                        TextField("Journal title", text: $customTitle)
                                            .font(
                                                .system(size: 16, weight: .regular, design: .serif)
                                            )
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .padding(.horizontal, DesignTokens.Spacing.md)
                                            .padding(.vertical, DesignTokens.Spacing.sm)
                                            .background(
                                                RoundedRectangle(
                                                    cornerRadius: DesignTokens.Radius.sm
                                                )
                                                .fill(DesignTokens.Colors.card)
                                                .overlay(
                                                    RoundedRectangle(
                                                        cornerRadius: DesignTokens.Radius.sm
                                                    )
                                                    .stroke(
                                                        DesignTokens.Colors.border.opacity(0.3),
                                                        lineWidth: 1)
                                                )
                                            )
                                    }
                                    .padding(.horizontal, DesignTokens.Spacing.xl)

                                    // Feeling selection
                                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                        Text("Overall Feeling")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(DesignTokens.Colors.textSecondary)

                                        FeelingPicker(selectedFeeling: $selectedFeeling)
                                    }
                                    .padding(.horizontal, DesignTokens.Spacing.xl)

                                    // Tags
                                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                        Text("Tags")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(DesignTokens.Colors.textSecondary)

                                        TagEditor(tags: $customTags, newTag: $newTag)
                                    }
                                    .padding(.horizontal, DesignTokens.Spacing.xl)
                                }
                            }

                            Spacer(minLength: 100)  // Bottom padding
                        }
                    }
                } else if let errorMessage = errorMessage {
                    // Error state
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)

                        Text("Error")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .multilineTextAlignment(.center)

                        Button("Try Again") {
                            startSummarization()
                        }
                        .primaryButton()
                    }
                    .padding(DesignTokens.Spacing.xl)
                } else {
                    // Initial state
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.primary.opacity(0.1))
                                .frame(width: 100, height: 100)

                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 40))
                                .foregroundColor(DesignTokens.Colors.primary)
                        }

                        VStack(spacing: DesignTokens.Spacing.md) {
                            Text("Ready to Reflect")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Text(
                                "Your conversation will be transformed into a personal journal entry"
                            )
                            .font(.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                        }

                        Button("Create Journal Entry") {
                            startSummarization()
                        }
                        .primaryButton()
                    }
                    .padding(DesignTokens.Spacing.xl)
                }
            }
            .navigationTitle("Save Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                }

                if summary != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveEntry()
                        }
                        .foregroundColor(DesignTokens.Colors.primary)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                showContent = true
            }
        }
    }

    private func startSummarization() {
        isSummarizing = true
        errorMessage = nil

        Task {
            do {
                let summary = try await summarizationService.summarizeConversation(
                    conversationTurns)
                await MainActor.run {
                    self.summary = summary
                    self.customTitle = summary.title
                    self.customTags = summary.tags
                    self.isSummarizing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSummarizing = false
                }
            }
        }
    }

    private func saveEntry() {
        guard let summary = summary else { return }

        let entry = Entry(
            title: customTitle.isEmpty ? summary.title : customTitle,
            transcript: summary.content,
            tags: customTags,
            feeling: selectedFeeling,
            mode: .connectedMode,
            isAIGenerated: true,
            originalConversationTurns: conversationTurns,
            emotionalState: summary.emotionalState
        )

        onSave(entry)
    }
}

struct FeelingPicker: View {
    @Binding var selectedFeeling: Feeling

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(Feeling.allCases) { feeling in
                    Button(action: {
                        selectedFeeling = feeling
                    }) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Circle()
                                .fill(Color(hex: feeling.color))
                                .frame(width: 8, height: 8)

                            Text(feeling.displayName)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                .fill(
                                    selectedFeeling == feeling
                                        ? DesignTokens.Colors.primary.opacity(0.1)
                                        : DesignTokens.Colors.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                .stroke(
                                    selectedFeeling == feeling
                                        ? DesignTokens.Colors.primary
                                        : DesignTokens.Colors.border.opacity(0.3),
                                    lineWidth: 1)
                        )
                    }
                    .foregroundColor(
                        selectedFeeling == feeling
                            ? DesignTokens.Colors.primary : DesignTokens.Colors.textPrimary)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
        }
    }
}

struct TagEditor: View {
    @Binding var tags: [String]
    @Binding var newTag: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                TextField("Add tag", text: $newTag)
                    .font(.system(size: 14))
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        addTag()
                    }

                Button("Add") {
                    addTag()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignTokens.Colors.primary)
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                    .fill(DesignTokens.Colors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                            .stroke(DesignTokens.Colors.border.opacity(0.3), lineWidth: 1)
                    )
            )

            if !tags.isEmpty {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 3),
                    spacing: DesignTokens.Spacing.xs
                ) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Text(tag)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Button(action: {
                                removeTag(tag)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                .fill(DesignTokens.Colors.primary.opacity(0.1))
                        )
                    }
                }
            }
        }
    }

    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

#Preview {
    SaveConversationSheet(
        conversationTurns: [
            ConversationTurn(userTranscript: "I'm feeling anxious about work"),
            ConversationTurn(
                userTranscript: "I have a big presentation tomorrow",
                assistantResponse:
                    "That sounds stressful. What specifically is worrying you about it?"),
        ],
        onSave: { _ in },
        onCancel: {}
    )
}
