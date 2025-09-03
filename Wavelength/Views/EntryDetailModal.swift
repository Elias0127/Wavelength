import SwiftUI

// MARK: - Entry Detail Modal
struct EntryDetailModal: View {
    let entry: Entry
    @ObservedObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var isFavorite = false
    @State private var showContent = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    // Diary-style header
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        // Date and time header
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text(entry.formattedDate)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            Text(entry.timeAgo)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.7))
                        }
                        
                        // Title (editable placeholder for future)
                        HStack {
                            Text(entry.title)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            // Favorite toggle
                            Button(action: {
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                isFavorite.toggle()
                                // TODO: Update entry favorite status
                            }) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(isFavorite ? DesignTokens.Colors.danger : DesignTokens.Colors.textSecondary)
                                    .font(.system(size: 20, weight: .medium))
                            }
                        }
                        
                        // Mode badge
                        HStack {
                            ModeBadge(mode: entry.mode)
                            Spacer()
                        }
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .fill(DesignTokens.Colors.card)
                    )
                    
                    // Transcript section (diary-style)
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        HStack {
                            Image(systemName: "book.pages")
                                .foregroundColor(DesignTokens.Colors.primary)
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("My Thoughts")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            Spacer()
                        }
                        
                        // Diary-style transcript with better typography
                        Text(entry.transcript)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                            .padding(DesignTokens.Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                    .fill(DesignTokens.Colors.surface)
                                    .overlay(
                                        // Subtle journal lines
                                        VStack(spacing: 20) {
                                            ForEach(0..<8, id: \.self) { _ in
                                                Rectangle()
                                                    .fill(DesignTokens.Colors.border.opacity(0.1))
                                                    .frame(height: 0.5)
                                            }
                                        }
                                        .padding(.horizontal, DesignTokens.Spacing.lg)
                                    )
                            )
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .fill(DesignTokens.Colors.card)
                    )
                    
                    // Counselor reflection section
                    if let counselorReply = entry.counselorReply, !counselorReply.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(DesignTokens.Colors.primary)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Reflection")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                
                                Spacer()
                                
                                // AI indicator
                                HStack(spacing: DesignTokens.Spacing.xs) {
                                    Circle()
                                        .fill(DesignTokens.Colors.success)
                                        .frame(width: 6, height: 6)
                                    
                                    Text("AI")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(DesignTokens.Colors.success)
                                }
                            }
                            
                            // Speech bubble design
                            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                                // AI avatar
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [DesignTokens.Colors.primary, DesignTokens.Colors.primary.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 28, height: 28)
                                    
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.white)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                
                                // Reflection bubble
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                    Text(counselorReply)
                                        .font(.system(size: 15, weight: .regular, design: .rounded))
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                        .multilineTextAlignment(.leading)
                                        .lineSpacing(2)
                                    
                                    // AI signature
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
                                        .fill(DesignTokens.Colors.surface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [DesignTokens.Colors.primary.opacity(0.2), DesignTokens.Colors.primary.opacity(0.05)],
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
                        .padding(DesignTokens.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .fill(DesignTokens.Colors.card)
                        )
                    }
                    
                    // Tags and mood section
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(DesignTokens.Colors.primary)
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("Tags & Mood")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: DesignTokens.Spacing.md) {
                            // Tags
                            if !entry.tags.isEmpty {
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                    Text("Topics")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignTokens.Spacing.sm) {
                                        ForEach(entry.tags, id: \.self) { tag in
                                            TagChip(text: tag)
                                        }
                                    }
                                }
                            }
                            
                            // Mood section
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                Text("How I felt")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                
                                HStack(spacing: DesignTokens.Spacing.md) {
                                    // Mood pill
                                    HStack(spacing: DesignTokens.Spacing.sm) {
                                        Circle()
                                            .fill(Color(hex: entry.feeling.color))
                                            .frame(width: 12, height: 12)
                                        
                                        Text(entry.feeling.displayName)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(hex: entry.feeling.color))
                                    }
                                    .padding(.horizontal, DesignTokens.Spacing.md)
                                    .padding(.vertical, DesignTokens.Spacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                            .fill(Color(hex: entry.feeling.color).opacity(0.1))
                                    )
                                    
                                    Spacer()
                                    
                                    // Mood percentage
                                    Text("\(Int(entry.averageValence * 100))% positive")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .fill(DesignTokens.Colors.card)
                    )
                    
                    // Emotion visualization section
                    if !entry.valenceSeries.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(DesignTokens.Colors.primary)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Emotion Journey")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: DesignTokens.Spacing.md) {
                                // Larger sparkline
                                MentalStateSparkline(data: entry.valenceSeries)
                                    .frame(height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                            .fill(DesignTokens.Colors.surface)
                                    )
                                
                                // Emotion journey caption
                                Text(emotionJourneyCaption)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(DesignTokens.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .fill(DesignTokens.Colors.card)
                        )
                    }
                    
                    // Action buttons
                    VStack(spacing: DesignTokens.Spacing.md) {
                        // Edit tags button (disabled placeholder)
                        Button(action: {
                            // TODO: Edit tags functionality
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Tags")
                            }
                            .secondaryButton()
                        }
                        .disabled(true)
                        .opacity(0.5)
                        
                        // Delete button
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Entry")
                            }
                            .secondaryButton()
                        }
                        .foregroundColor(DesignTokens.Colors.danger)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
                .padding(.vertical, DesignTokens.Spacing.lg)
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 30)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: showContent)
            }
            .background(DesignTokens.Colors.surface)
            .navigationTitle("Journal Entry")
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
        .onAppear {
            isFavorite = entry.favorite
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                showContent = true
            }
        }
        .alert("Delete Entry", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                appViewModel.deleteEntry(id: entry.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this entry? This action cannot be undone.")
        }
    }
    
    // MARK: - Computed Properties
    private var emotionJourneyCaption: String {
        guard entry.valenceSeries.count >= 2 else {
            return "Single moment captured"
        }
        
        let start = entry.valenceSeries.first ?? 0.5
        let end = entry.valenceSeries.last ?? 0.5
        
        let startFeeling = start < 0.3 ? "tense" : start < 0.7 ? "neutral" : "calm"
        let endFeeling = end < 0.3 ? "tense" : end < 0.7 ? "neutral" : "calm"
        
        if abs(start - end) < 0.1 {
            return "Stayed \(endFeeling) throughout"
        } else if end > start {
            return "Started \(startFeeling) → ended \(endFeeling)"
        } else {
            return "Started \(startFeeling) → ended \(endFeeling)"
        }
    }
}

// MARK: - Preview
#Preview {
    EntryDetailModal(
        entry: MockEntries.seed[0],
        appViewModel: AppViewModel()
    )
}
