import SwiftUI

// MARK: - AI Conversation Entry Card Component
struct AIConversationEntryCard: View {
    let entry: Entry
    let onTap: () -> Void
    @State private var isPressed = false
    @State private var showContent = false

    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                // AI conversation header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        // Date and time
                        Text(entry.formattedDate)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(DesignTokens.Colors.textSecondary)

                        Text(entry.timeAgo)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.7))
                    }

                    Spacer()

                    // AI conversation indicator
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 12))
                            .foregroundColor(DesignTokens.Colors.primary)

                        Text("AI Conversation")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                            .fill(DesignTokens.Colors.primary.opacity(0.1))
                    )
                }

                // Entry title with AI styling
                HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(DesignTokens.Colors.primary)
                        .padding(.top, 2)

                    Text(entry.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // Emotional state and mood indicators
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    // Primary feeling
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Circle()
                            .fill(Color(hex: entry.feeling.color))
                            .frame(width: 10, height: 10)

                        Text(entry.feeling.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: entry.feeling.color))

                        if let emotionalState = entry.emotionalState {
                            Text("•")
                                .font(.system(size: 12))
                                .foregroundColor(DesignTokens.Colors.textSecondary)

                            Text(emotionalState)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                            .fill(Color(hex: entry.feeling.color).opacity(0.1))
                    )

                    // Conversation stats
                    if let turns = entry.originalConversationTurns, !turns.isEmpty {
                        HStack(spacing: DesignTokens.Spacing.md) {
                            ConversationStat(
                                icon: "bubble.left.and.bubble.right.fill",
                                text: "\(turns.count) exchanges",
                                color: DesignTokens.Colors.primary
                            )

                            if !entry.valenceSeries.isEmpty {
                                ConversationStat(
                                    icon: "chart.line.uptrend.xyaxis",
                                    text: "\(Int(entry.averageValence * 100))% positive",
                                    color: DesignTokens.Colors.success
                                )
                            }
                        }
                    }
                }

                // Tags with AI conversation styling
                if !entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            ForEach(entry.tags.prefix(4), id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(DesignTokens.Colors.primary)
                                    .padding(.horizontal, DesignTokens.Spacing.sm)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(DesignTokens.Colors.primary.opacity(0.1))
                                    )
                            }

                            if entry.tags.count > 4 {
                                Text("+\(entry.tags.count - 4)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }

                // Content preview with AI styling
                Text(entry.transcript)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(DesignTokens.Colors.textPrimary.opacity(0.8))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(1)
            }
            .padding(DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(DesignTokens.Colors.card)
                    .overlay(
                        // AI conversation border
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
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
                    .overlay(
                        // Subtle AI pattern
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "sparkles")
                                    .font(.system(size: 8))
                                    .foregroundColor(DesignTokens.Colors.primary.opacity(0.2))
                                    .padding(.trailing, DesignTokens.Spacing.sm)
                                    .padding(.bottom, DesignTokens.Spacing.sm)
                            }
                        }
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 20)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showContent)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0, maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            }, perform: {}
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
        }
        .accessibilityLabel("AI conversation journal entry: \(entry.title)")
        .accessibilityHint("Tap to read full conversation reflection")
    }
}

// MARK: - Conversation Stat Component
struct ConversationStat: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)

            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - AI Conversation Detail View
struct AIConversationDetailView: View {
    let entry: Entry
    @Environment(\.dismiss) private var dismiss
    @State private var showOriginalConversation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                Text(entry.formattedDate)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)

                                Text(entry.timeAgo)
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.7))
                            }

                            Spacer()

                            // AI conversation badge
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignTokens.Colors.primary)

                                Text("AI Conversation")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(DesignTokens.Colors.primary)
                            }
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                    .fill(DesignTokens.Colors.primary.opacity(0.1))
                            )
                        }

                        Text(entry.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .fill(DesignTokens.Colors.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                    .stroke(DesignTokens.Colors.border.opacity(0.3), lineWidth: 1)
                            )
                    )

                    // Emotional state
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Emotional State")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        HStack(spacing: DesignTokens.Spacing.lg) {
                            // Primary feeling
                            VStack(spacing: DesignTokens.Spacing.sm) {
                                Circle()
                                    .fill(Color(hex: entry.feeling.color))
                                    .frame(width: 40, height: 40)

                                Text(entry.feeling.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: entry.feeling.color))
                            }

                            if let emotionalState = entry.emotionalState {
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                    Text("Overall State")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(DesignTokens.Colors.textSecondary)

                                    Text(emotionalState)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                }
                            }

                            Spacer()
                        }
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .fill(DesignTokens.Colors.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                    .stroke(DesignTokens.Colors.border.opacity(0.3), lineWidth: 1)
                            )
                    )

                    // Journal content
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Reflection")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        Text(entry.transcript)
                            .font(.body)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .lineSpacing(4)
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .fill(DesignTokens.Colors.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                    .stroke(DesignTokens.Colors.border.opacity(0.3), lineWidth: 1)
                            )
                    )

                    // Original conversation (if available)
                    if let turns = entry.originalConversationTurns, !turns.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            HStack {
                                Text("Original Conversation")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Spacer()

                                Button(action: {
                                    showOriginalConversation.toggle()
                                }) {
                                    HStack(spacing: DesignTokens.Spacing.xs) {
                                        Text(showOriginalConversation ? "Hide" : "Show")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(DesignTokens.Colors.primary)

                                        Image(
                                            systemName: showOriginalConversation
                                                ? "chevron.up" : "chevron.down"
                                        )
                                        .font(.system(size: 12))
                                        .foregroundColor(DesignTokens.Colors.primary)
                                    }
                                }
                            }

                            if showOriginalConversation {
                                LazyVStack(spacing: DesignTokens.Spacing.md) {
                                    ForEach(turns, id: \.id) { turn in
                                        ConversationTurnDetailView(turn: turn)
                                    }
                                }
                            }
                        }
                        .padding(DesignTokens.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .fill(DesignTokens.Colors.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                        .stroke(
                                            DesignTokens.Colors.border.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }

                    // Tags
                    if !entry.tags.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            Text("Tags")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible()), count: 3),
                                spacing: DesignTokens.Spacing.sm
                            ) {
                                ForEach(entry.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(DesignTokens.Colors.primary)
                                        .padding(.horizontal, DesignTokens.Spacing.sm)
                                        .padding(.vertical, DesignTokens.Spacing.xs)
                                        .background(
                                            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                                .fill(DesignTokens.Colors.primary.opacity(0.1))
                                        )
                                }
                            }
                        }
                        .padding(DesignTokens.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .fill(DesignTokens.Colors.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                        .stroke(
                                            DesignTokens.Colors.border.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.surface)
            .navigationTitle("Conversation Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignTokens.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Conversation Turn Detail View
struct ConversationTurnDetailView: View {
    let turn: ConversationTurn

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // User message
            HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                Circle()
                    .fill(DesignTokens.Colors.primary.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("You")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.primary)
                    )

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(turn.userTranscript)
                        .font(.system(size: 14))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .padding(DesignTokens.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                .fill(DesignTokens.Colors.primary.opacity(0.1))
                        )

                    Text(turn.timestamp, style: .time)
                        .font(.system(size: 10))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }

                Spacer()
            }

            // AI response
            if let response = turn.assistantResponse {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                    Spacer()

                    VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                        Text(response)
                            .font(.system(size: 14))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .padding(DesignTokens.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                    .fill(DesignTokens.Colors.border.opacity(0.1))
                            )

                        Text(turn.timestamp, style: .time)
                            .font(.system(size: 10))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }

                    Circle()
                        .fill(DesignTokens.Colors.border.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 12))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        )
                }
            }
        }
    }
}

#Preview {
    AIConversationEntryCard(
        entry: Entry(
            title: "Reflecting on My Anxiety",
            transcript:
                "Today I had a meaningful conversation about my anxiety and learned some valuable coping strategies...",
            tags: ["anxiety", "growth", "coping"],
            feeling: .calm,
            isAIGenerated: true,
            emotionalState: "Reflective and hopeful"
        ),
        onTap: {}
    )
}
