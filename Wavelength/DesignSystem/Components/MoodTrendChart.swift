import SwiftUI

// MARK: - Mood Trend Chart Component
struct MoodTrendChart: View {
    let data: [Double]
    let labels: [String]
    @State private var animatedData: [Double] = []
    @State private var showChart = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            // Chart header
            HStack {
                Text("Mood Trend")
                    .h2()
                
                Spacer()
                
                // Average mood indicator
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Circle()
                        .fill(averageMoodColor)
                        .frame(width: 8, height: 8)
                    
                    Text("\(Int(averageMood * 100))% positive")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            // Chart container
            VStack(spacing: DesignTokens.Spacing.md) {
                // Main chart area
                GeometryReader { geometry in
                    ZStack {
                        // Background grid
                        ChartGrid(
                            width: geometry.size.width,
                            height: geometry.size.height,
                            dataCount: data.count
                        )
                        
                        // Trend line
                        if showChart && !animatedData.isEmpty {
                            MoodTrendLine(
                                data: animatedData,
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                        }
                        
                        // Data points
                        if showChart && !animatedData.isEmpty {
                            ForEach(Array(animatedData.enumerated()), id: \.offset) { index, value in
                                Circle()
                                    .fill(averageMoodColor)
                                    .frame(width: 8, height: 8)
                                    .position(
                                        x: CGFloat(index) * (geometry.size.width / CGFloat(max(1, animatedData.count - 1))),
                                        y: geometry.size.height - (CGFloat(value) * geometry.size.height)
                                    )
                                    .scaleEffect(showChart ? 1.0 : 0.0)
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.1),
                                        value: showChart
                                    )
                            }
                        }
                    }
                }
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(DesignTokens.Colors.card)
                )
                
                // X-axis labels
                HStack {
                    ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        if index < labels.count - 1 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sm)
            }
            
            // Mood description
            HStack {
                Text(moodDescription)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(averageMoodColor)
                
                Spacer()
                
                // Trend indicator
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: trendIcon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(trendColor)
                    
                    Text(trendText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(trendColor)
                }
            }
        }
        .onAppear {
            animatedData = Array(repeating: 0.0, count: data.count)
            
            withAnimation(.easeInOut(duration: 0.5)) {
                showChart = true
            }
            
            withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                animatedData = data
            }
        }
    }
    
    // MARK: - Computed Properties
    private var averageMood: Double {
        guard !data.isEmpty else { return 0.5 }
        return data.reduce(0, +) / Double(data.count)
    }
    
    private var averageMoodColor: Color {
        switch averageMood {
        case 0.0..<0.3:
            return DesignTokens.Colors.danger
        case 0.3..<0.7:
            return DesignTokens.Colors.warning
        case 0.7...1.0:
            return DesignTokens.Colors.success
        default:
            return DesignTokens.Colors.textSecondary
        }
    }
    
    private var moodDescription: String {
        switch averageMood {
        case 0.0..<0.3:
            return "Challenging week"
        case 0.3..<0.7:
            return "Mixed week"
        case 0.7...1.0:
            return "Positive week"
        default:
            return "Unknown"
        }
    }
    
    private var trendIcon: String {
        guard data.count >= 2 else { return "minus" }
        let firstHalf = Array(data.prefix(data.count / 2))
        let secondHalf = Array(data.suffix(data.count / 2))
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        if secondAvg > firstAvg + 0.1 {
            return "arrow.up.right"
        } else if secondAvg < firstAvg - 0.1 {
            return "arrow.down.right"
        } else {
            return "arrow.right"
        }
    }
    
    private var trendColor: Color {
        guard data.count >= 2 else { return DesignTokens.Colors.textSecondary }
        let firstHalf = Array(data.prefix(data.count / 2))
        let secondHalf = Array(data.suffix(data.count / 2))
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        if secondAvg > firstAvg + 0.1 {
            return DesignTokens.Colors.success
        } else if secondAvg < firstAvg - 0.1 {
            return DesignTokens.Colors.danger
        } else {
            return DesignTokens.Colors.textSecondary
        }
    }
    
    private var trendText: String {
        guard data.count >= 2 else { return "Stable" }
        let firstHalf = Array(data.prefix(data.count / 2))
        let secondHalf = Array(data.suffix(data.count / 2))
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        if secondAvg > firstAvg + 0.1 {
            return "Improving"
        } else if secondAvg < firstAvg - 0.1 {
            return "Declining"
        } else {
            return "Stable"
        }
    }
}

// MARK: - Chart Grid
struct ChartGrid: View {
    let width: CGFloat
    let height: CGFloat
    let dataCount: Int
    
    var body: some View {
        ZStack {
            // Horizontal grid lines
            ForEach(0..<5, id: \.self) { index in
                Rectangle()
                    .fill(DesignTokens.Colors.border.opacity(0.3))
                    .frame(height: 0.5)
                    .position(
                        x: width / 2,
                        y: height * CGFloat(index) / 4
                    )
            }
            
            // Vertical grid lines
            ForEach(0..<dataCount, id: \.self) { index in
                Rectangle()
                    .fill(DesignTokens.Colors.border.opacity(0.2))
                    .frame(width: 0.5)
                    .position(
                        x: CGFloat(index) * (width / CGFloat(max(1, dataCount - 1))),
                        y: height / 2
                    )
            }
        }
    }
}

// MARK: - Mood Trend Line
struct MoodTrendLine: View {
    let data: [Double]
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Path { path in
            guard !data.isEmpty else { return }
            
            let stepX = width / CGFloat(max(1, data.count - 1))
            
            for (index, value) in data.enumerated() {
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
                    DesignTokens.Colors.primary.opacity(0.7),
                    DesignTokens.Colors.primary.opacity(0.4)
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
    }
}

// MARK: - Preview
#Preview {
    MoodTrendChart(
        data: [0.3, 0.4, 0.6, 0.5, 0.7, 0.6, 0.8],
        labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    )
    .padding()
    .background(DesignTokens.Colors.surface)
}
