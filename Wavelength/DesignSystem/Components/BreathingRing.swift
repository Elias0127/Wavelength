import SwiftUI

// MARK: - Breathing Ring Component
struct BreathingRing: View {
    let intensity: Double // 0.0 to 1.0
    let isAnimating: Bool
    let content: () -> AnyView
    
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    @State private var rotation: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    
    init(intensity: Double = 0.5, isAnimating: Bool = true, @ViewBuilder content: @escaping () -> some View) {
        self.intensity = intensity
        self.isAnimating = isAnimating
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        ZStack {
            // Multiple concentric rings for depth
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                DesignTokens.Colors.primary.opacity(0.4 - Double(index) * 0.1),
                                DesignTokens.Colors.primary.opacity(0.2 - Double(index) * 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: CGFloat(3 - index)
                    )
                    .frame(width: 200 - CGFloat(index * 20), height: 200 - CGFloat(index * 20))
                    .scaleEffect(scale * (1.0 - CGFloat(index) * 0.1))
                    .opacity(opacity * (1.0 - Double(index) * 0.2))
                    .rotationEffect(.degrees(rotation * Double(index + 1) * 0.5))
            }
            
            // Pulsing center ring
            Circle()
                .stroke(
                    DesignTokens.Colors.primary.opacity(0.6),
                    lineWidth: 2
                )
                .frame(width: 120, height: 120)
                .scaleEffect(pulseScale)
                .opacity(opacity * 0.8)
            
            // Content with subtle breathing effect
            content()
                .scaleEffect(1.0 + (intensity * 0.05))
                .opacity(0.9 + (intensity * 0.1))
        }
        .onAppear {
            if isAnimating {
                startBreathingAnimation()
            }
        }
        .onChange(of: isAnimating) {
            if isAnimating {
                startBreathingAnimation()
            } else {
                stopBreathingAnimation()
            }
        }
        .onChange(of: intensity) {
            // Adjust animation based on intensity changes
            if isAnimating {
                updateAnimationForIntensity(intensity)
            }
        }
    }
    
    private func startBreathingAnimation() {
        let baseDuration = 3.0 + (1.0 - intensity) * 2.0 // Slower for higher intensity
        let rotationDuration = 20.0 // Slow rotation
        
        // Main breathing animation
        withAnimation(
            .easeInOut(duration: baseDuration)
            .repeatForever(autoreverses: true)
        ) {
            scale = 1.0 + (intensity * 0.3)
            opacity = 0.2 + (intensity * 0.4)
        }
        
        // Rotation animation
        withAnimation(
            .linear(duration: rotationDuration)
            .repeatForever(autoreverses: false)
        ) {
            rotation = 360.0
        }
        
        // Pulse animation
        withAnimation(
            .easeInOut(duration: baseDuration * 0.7)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.0 + (intensity * 0.2)
        }
    }
    
    private func stopBreathingAnimation() {
        withAnimation(.easeOut(duration: 0.8)) {
            scale = 1.0
            opacity = 0.3
            rotation = 0.0
            pulseScale = 1.0
        }
    }
    
    private func updateAnimationForIntensity(_ newIntensity: Double) {
        let baseDuration = 3.0 + (1.0 - newIntensity) * 2.0
        
        withAnimation(
            .easeInOut(duration: baseDuration)
            .repeatForever(autoreverses: true)
        ) {
            scale = 1.0 + (newIntensity * 0.3)
            opacity = 0.2 + (newIntensity * 0.4)
        }
        
        withAnimation(
            .easeInOut(duration: baseDuration * 0.7)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.0 + (newIntensity * 0.2)
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
