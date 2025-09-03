import SwiftUI

// MARK: - Mini Line Chart Component
struct MiniLineChart: View {
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
                        colors: [DesignTokens.Colors.primary, DesignTokens.Colors.primary.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                .onAppear {
                    animateChart()
                }
            }
        }
        .clipped()
    }
    
    private func animateChart() {
        animatedData = Array(repeating: 0.0, count: data.count)
        
        withAnimation(.easeInOut(duration: 1.0)) {
            animatedData = data
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: DesignTokens.Spacing.lg) {
        MiniLineChart(data: [0.2, 0.4, 0.3, 0.6, 0.8, 0.7])
            .frame(height: 30)
            .background(DesignTokens.Colors.card)
            .cornerRadius(DesignTokens.Radius.sm)
        
        MiniLineChart(data: [0.8, 0.6, 0.7, 0.9, 0.8, 0.85])
            .frame(height: 30)
            .background(DesignTokens.Colors.card)
            .cornerRadius(DesignTokens.Radius.sm)
        
        MiniLineChart(data: [0.3, 0.2, 0.4, 0.3, 0.2, 0.25])
            .frame(height: 30)
            .background(DesignTokens.Colors.card)
            .cornerRadius(DesignTokens.Radius.sm)
    }
    .padding()
    .background(DesignTokens.Colors.surface)
}
