import SwiftUI

// MARK: - Diary Entry Card Component
struct DiaryEntryCard: View {
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
                // Diary-style header with date and time
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        // Date in diary format
                        Text(entry.formattedDate)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        // Time
                        Text(entry.timeAgo)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Mode and favorite indicators
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        if entry.favorite {
                            Image(systemName: "heart.fill")
                                .foregroundColor(DesignTokens.Colors.danger)
                                .font(.system(size: 12))
                        }
                        
                        ModeBadge(mode: entry.mode)
                    }
                }
                
                // Entry title (diary-style)
                Text(entry.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Mental state visualization
                HStack(spacing: DesignTokens.Spacing.md) {
                    // Mood indicator with enhanced design
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Circle()
                            .fill(Color(hex: entry.feeling.color))
                            .frame(width: 10, height: 10)
                        
                        Text(entry.feeling.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: entry.feeling.color))
                    }
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                            .fill(Color(hex: entry.feeling.color).opacity(0.1))
                    )
                    
                    // Mental state sparkline
                    if !entry.valenceSeries.isEmpty {
                        VStack(alignment: .trailing, spacing: 2) {
                            MentalStateSparkline(data: entry.valenceSeries)
                                .frame(width: 60, height: 16)
                            
                            Text("\(Int(entry.averageValence * 100))%")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Tags (diary-style)
                if !entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            ForEach(entry.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .padding(.horizontal, DesignTokens.Spacing.sm)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(DesignTokens.Colors.border.opacity(0.5))
                                    )
                            }
                            
                            if entry.tags.count > 3 {
                                Text("+\(entry.tags.count - 3)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
                
                // Preview text (diary excerpt)
                Text(entry.transcript)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(DesignTokens.Colors.textPrimary.opacity(0.8))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(1)
            }
            .padding(DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(DesignTokens.Colors.card)
                    .overlay(
                        // Subtle journal line
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(DesignTokens.Colors.border.opacity(0.2))
                                .frame(height: 0.5)
                                .padding(.horizontal, DesignTokens.Spacing.lg)
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
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
        }
        .accessibilityLabel("Journal entry: \(entry.title)")
        .accessibilityHint("Tap to read full entry")
    }
}

// MARK: - Mental State Sparkline
struct MentalStateSparkline: View {
    let data: [Double]
    @State private var animatedData: [Double] = []
    
    var body: some View {
        GeometryReader { geometry in
            if !data.isEmpty {
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(max(1, data.count - 1))
                    
                    for (index, value) in animatedData.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - (CGFloat(value) * height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            DesignTokens.Colors.primary,
                            DesignTokens.Colors.primary.opacity(0.6)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )
                .onAppear {
                    animatedData = Array(repeating: 0.0, count: data.count)
                    withAnimation(.easeInOut(duration: 0.8)) {
                        animatedData = data
                    }
                }
            }
        }
        .clipped()
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.md) {
            DiaryEntryCard(entry: MockEntries.seed[0]) {}
            DiaryEntryCard(entry: MockEntries.seed[1]) {}
            DiaryEntryCard(entry: MockEntries.seed[2]) {}
        }
        .padding()
    }
    .background(DesignTokens.Colors.surface)
}
