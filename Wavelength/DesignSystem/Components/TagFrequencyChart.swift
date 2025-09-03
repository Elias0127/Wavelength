import SwiftUI

// MARK: - Tag Frequency Chart Component
struct TagFrequencyChart: View {
    let tagFrequency: [String: Int]
    let maxItems: Int
    
    init(tagFrequency: [String: Int], maxItems: Int = 8) {
        self.tagFrequency = tagFrequency
        self.maxItems = maxItems
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            // Header
            HStack {
                Text("Most Common Topics")
                    .h2()
                
                Spacer()
                
                Text("\(tagFrequency.count) topics")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            if topTags.isEmpty {
                // Empty state
                VStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "tag.slash")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Text("No topics yet")
                        .bodyText()
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Text("Keep journaling to see your most common topics")
                        .captionText()
                        .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(DesignTokens.Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(DesignTokens.Colors.card)
                )
            } else {
                // Tag frequency visualization
                VStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(Array(topTags.enumerated()), id: \.offset) { index, tagData in
                        TagFrequencyRow(
                            tag: tagData.0,
                            count: tagData.1,
                            maxCount: maxCount,
                            rank: index + 1
                        )
                    }
                }
                .padding(DesignTokens.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(DesignTokens.Colors.card)
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var topTags: [(String, Int)] {
        tagFrequency.sorted { $0.value > $1.value }.prefix(maxItems).map { ($0.key, $0.value) }
    }
    
    private var maxCount: Int {
        topTags.first?.1 ?? 1
    }
}

// MARK: - Tag Frequency Row
struct TagFrequencyRow: View {
    let tag: String
    let count: Int
    let maxCount: Int
    let rank: Int
    
    @State private var animatedWidth: CGFloat = 0
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Rank indicator
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 24, height: 24)
                
                Text("\(rank)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Tag name
            Text(tag.capitalized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .frame(width: 80, alignment: .leading)
            
            // Bar visualization
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Colors.border.opacity(0.3))
                        .frame(height: 8)
                    
                    // Animated progress bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [rankColor, rankColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animatedWidth, height: 8)
                        .animation(
                            .easeInOut(duration: 1.0)
                            .delay(Double(rank) * 0.1),
                            value: animatedWidth
                        )
                }
            }
            .frame(height: 8)
            
            // Count
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .frame(width: 30, alignment: .trailing)
        }
        .onAppear {
            let progress = CGFloat(count) / CGFloat(maxCount)
            animatedWidth = progress * 100 // Assuming max width of 100
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return DesignTokens.Colors.warning
        case 2:
            return DesignTokens.Colors.primary
        case 3:
            return DesignTokens.Colors.success
        default:
            return DesignTokens.Colors.textSecondary
        }
    }
}

// MARK: - Tag Cloud Alternative
struct TagCloud: View {
    let tagFrequency: [String: Int]
    let maxItems: Int
    
    init(tagFrequency: [String: Int], maxItems: Int = 12) {
        self.tagFrequency = tagFrequency
        self.maxItems = maxItems
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("Topic Cloud")
                .h2()
            
            if topTags.isEmpty {
                Text("No topics yet")
                    .bodyText()
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignTokens.Spacing.sm) {
                    ForEach(Array(topTags.enumerated()), id: \.offset) { index, tagData in
                        TagCloudChip(
                            tag: tagData.0,
                            count: tagData.1,
                            maxCount: maxCount,
                            rank: index + 1
                        )
                    }
                }
            }
        }
    }
    
    private var topTags: [(String, Int)] {
        tagFrequency.sorted { $0.value > $1.value }.prefix(maxItems).map { ($0.key, $0.value) }
    }
    
    private var maxCount: Int {
        topTags.first?.1 ?? 1
    }
}

// MARK: - Tag Cloud Chip
struct TagCloudChip: View {
    let tag: String
    let count: Int
    let maxCount: Int
    let rank: Int
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Text(tag.capitalized)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("\(count)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                .fill(rankColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                        .stroke(rankColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var fontSize: CGFloat {
        let baseSize: CGFloat = 12
        let maxSize: CGFloat = 16
        let ratio = CGFloat(count) / CGFloat(maxCount)
        return baseSize + (maxSize - baseSize) * ratio
    }
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return DesignTokens.Colors.warning
        case 2:
            return DesignTokens.Colors.primary
        case 3:
            return DesignTokens.Colors.success
        default:
            return DesignTokens.Colors.textSecondary
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: DesignTokens.Spacing.xl) {
        TagFrequencyChart(
            tagFrequency: [
                "work": 8,
                "anxiety": 6,
                "family": 4,
                "exercise": 3,
                "sleep": 2,
                "creativity": 1
            ]
        )
        
        TagCloud(
            tagFrequency: [
                "work": 8,
                "anxiety": 6,
                "family": 4,
                "exercise": 3,
                "sleep": 2,
                "creativity": 1
            ]
        )
    }
    .padding()
    .background(DesignTokens.Colors.surface)
}
