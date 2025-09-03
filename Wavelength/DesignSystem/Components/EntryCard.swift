import SwiftUI

// MARK: - Entry Card Component
struct EntryCard: View {
    let entry: Entry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Enhanced header with better visual hierarchy
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text(entry.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Text(entry.timeAgo)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            if entry.favorite {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(DesignTokens.Colors.danger)
                                    .font(.system(size: 10))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    ModeBadge(mode: entry.mode)
                }
                
                // Enhanced tags section
                if !entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ForEach(entry.tags, id: \.self) { tag in
                                TagChip(text: tag)
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
                
                // Enhanced feeling and chart section
                HStack(alignment: .center) {
                    // Enhanced feeling pill
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Circle()
                            .fill(Color(hex: entry.feeling.color))
                            .frame(width: 8, height: 8)
                        
                        Text(entry.feeling.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: entry.feeling.color))
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                            .fill(Color(hex: entry.feeling.color).opacity(0.1))
                    )
                    
                    Spacer()
                    
                    // Enhanced mini chart
                    if !entry.valenceSeries.isEmpty {
                        VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                            MiniLineChart(data: entry.valenceSeries)
                                .frame(width: 80, height: 24)
                            
                            Text("\(Int(entry.averageValence * 100))%")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    }
                }
                
                // Enhanced preview text with better typography
                Text(entry.transcript)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
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
                                        DesignTokens.Colors.border.opacity(0.3),
                                        DesignTokens.Colors.border.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: DesignTokens.Shadows.card,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Journal entry: \(entry.title)")
        .accessibilityHint("Tap to view full entry")
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.lg) {
            EntryCard(entry: MockEntries.seed[0]) {}
            EntryCard(entry: MockEntries.seed[1]) {}
        }
        .padding()
    }
    .background(DesignTokens.Colors.surface)
}
