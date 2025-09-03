import SwiftUI

// MARK: - Entry Card Component
struct EntryCard: View {
    let entry: Entry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(entry.title)
                            .h2()
                            .lineLimit(2)
                        
                        Text(entry.timeAgo)
                            .captionText()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                        ModeBadge(mode: entry.mode)
                        
                        if entry.favorite {
                            Image(systemName: "heart.fill")
                                .foregroundColor(DesignTokens.Colors.danger)
                                .font(.system(size: 12))
                        }
                    }
                }
                
                // Tags
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
                
                // Feeling and Chart
                HStack {
                    // Feeling pill
                    Text(entry.feeling.displayName)
                        .pill(
                            backgroundColor: Color(hex: entry.feeling.color),
                            textColor: .white
                        )
                    
                    Spacer()
                    
                    // Mini chart
                    if !entry.valenceSeries.isEmpty {
                        MiniLineChart(data: entry.valenceSeries)
                            .frame(width: 60, height: 20)
                    }
                }
                
                // Preview text
                Text(entry.transcript)
                    .bodyText()
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(DesignTokens.Spacing.lg)
            .cardBackground()
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
