import SwiftUI

// MARK: - Breathing Ring Component
struct BreathingRing: View {
    let intensity: Double // 0.0 to 1.0
    let isAnimating: Bool
    let content: () -> AnyView
    
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    
    init(intensity: Double = 0.5, isAnimating: Bool = true, @ViewBuilder content: @escaping () -> some View) {
        self.intensity = intensity
        self.isAnimating = isAnimating
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            DesignTokens.Colors.primary.opacity(0.3),
                            DesignTokens.Colors.primary.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 200, height: 200)
                .scaleEffect(scale)
                .opacity(opacity)
            
            // Inner ring
            Circle()
                .stroke(
                    DesignTokens.Colors.primary.opacity(0.2),
                    lineWidth: 1
                )
                .frame(width: 160, height: 160)
                .scaleEffect(scale * 0.8)
                .opacity(opacity * 0.7)
            
            // Content
            content()
        }
        .onAppear {
            if isAnimating {
                startBreathingAnimation()
            }
        }
        .onChange(of: isAnimating) { newValue in
            if newValue {
                startBreathingAnimation()
            } else {
                stopBreathingAnimation()
            }
        }
    }
    
    private func startBreathingAnimation() {
        let baseDuration = 3.0 + (1.0 - intensity) * 2.0 // Slower for higher intensity
        
        withAnimation(
            .easeInOut(duration: baseDuration)
            .repeatForever(autoreverses: true)
        ) {
            scale = 1.0 + (intensity * 0.3)
            opacity = 0.2 + (intensity * 0.4)
        }
    }
    
    private func stopBreathingAnimation() {
        withAnimation(.easeOut(duration: 0.5)) {
            scale = 1.0
            opacity = 0.3
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: DesignTokens.Spacing.xl) {
        BreathingRing(intensity: 0.3, isAnimating: true) {
            TalkButton(action: {})
        }
        
        BreathingRing(intensity: 0.7, isAnimating: true) {
            TalkButton(action: {})
        }
    }
    .padding()
    .background(DesignTokens.Colors.surface)
}
