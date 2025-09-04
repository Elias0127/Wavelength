import SwiftUI

// MARK: - Enhanced Breathing Ring Component
struct BreathingRing: View {
    let intensity: Double
    let isAnimating: Bool
    let mode: Mode
    let action: () -> Void
    
    @State private var breathingScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        ZStack {
            // Immersive Background Effects
            if mode == .connected {
                // Connected Mode: Advanced AI Visualization
                ZStack {
                    // Neural Network Pattern
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .stroke(
                                DesignTokens.Colors.connectedMode.opacity(0.1),
                                lineWidth: 1
                            )
                            .frame(width: 200 + CGFloat(index * 40), height: 200 + CGFloat(index * 40))
                            .rotationEffect(.degrees(rotationAngle + Double(index * 45)))
                            .animation(
                                .linear(duration: 20)
                                .repeatForever(autoreverses: false),
                                value: rotationAngle
                            )
                    }
                    
                    // Floating Particles
                    ForEach(0..<12, id: \.self) { index in
                        Circle()
                            .fill(DesignTokens.Colors.connectedMode.opacity(0.3))
                            .frame(width: 4, height: 4)
                            .offset(
                                x: CGFloat(cos(Double(index) * .pi / 6)) * 120,
                                y: CGFloat(sin(Double(index) * .pi / 6)) * 120
                            )
                            .scaleEffect(breathingScale)
                            .opacity(glowOpacity)
                            .animation(
                                .easeInOut(duration: 3)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: breathingScale
                            )
                    }
                }
            } else {
                // Private Mode: Calming Privacy Visualization
                ZStack {
                    // Privacy Shield Pattern
                    ForEach(0..<6, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                DesignTokens.Colors.privateMode.opacity(0.15),
                                lineWidth: 2
                            )
                            .frame(width: 180 + CGFloat(index * 30), height: 180 + CGFloat(index * 30))
                            .rotationEffect(.degrees(rotationAngle + Double(index * 30)))
                            .animation(
                                .linear(duration: 30)
                                .repeatForever(autoreverses: false),
                                value: rotationAngle
                            )
                    }
                    
                    // Privacy Lock Icons
                    ForEach(0..<4, id: \.self) { index in
                        Image(systemName: "lock.shield")
                            .font(.system(size: 16))
                            .foregroundColor(DesignTokens.Colors.privateMode.opacity(0.4))
                            .offset(
                                x: CGFloat(cos(Double(index) * .pi / 2)) * 100,
                                y: CGFloat(sin(Double(index) * .pi / 2)) * 100
                            )
                            .scaleEffect(breathingScale)
                            .opacity(glowOpacity)
                            .animation(
                                .easeInOut(duration: 4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.5),
                                value: breathingScale
                            )
                    }
                }
            }
            
            // Main Breathing Ring
            ZStack {
                // Outer Ring
                Circle()
                    .stroke(
                        mode == .privateMode ? 
                            DesignTokens.Colors.privateMode.opacity(0.3) : 
                            DesignTokens.Colors.connectedMode.opacity(0.3),
                        lineWidth: 3
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(breathingScale)
                    .animation(
                        .easeInOut(duration: 4)
                        .repeatForever(autoreverses: true),
                        value: breathingScale
                    )
                
                // Middle Ring
                Circle()
                    .stroke(
                        mode == .privateMode ? 
                            DesignTokens.Colors.privateMode.opacity(0.5) : 
                            DesignTokens.Colors.connectedMode.opacity(0.5),
                        lineWidth: 2
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(breathingScale * 0.8)
                    .animation(
                        .easeInOut(duration: 4)
                        .repeatForever(autoreverses: true)
                        .delay(0.5),
                        value: breathingScale
                    )
                
                // Inner Ring
                Circle()
                    .stroke(
                        mode == .privateMode ? 
                            DesignTokens.Colors.privateMode.opacity(0.7) : 
                            DesignTokens.Colors.connectedMode.opacity(0.7),
                        lineWidth: 1
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(breathingScale * 0.6)
                    .animation(
                        .easeInOut(duration: 4)
                        .repeatForever(autoreverses: true)
                        .delay(1.0),
                        value: breathingScale
                    )
                
                // Center Action Button
                TalkButton(action: action, mode: mode)
            }
        }
        .onAppear {
            startBreathingAnimation()
        }
    }
    
    private func startBreathingAnimation() {
        breathingScale = 1.2
        rotationAngle = 360
        glowOpacity = 0.7
    }
}

struct LegacyBreathingRing: View {
    let intensity: Double
    let isAnimating: Bool
    let action: () -> Void
    
    @State private var breathingScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Outer Ring
            Circle()
                .stroke(DesignTokens.Colors.primary.opacity(0.3), lineWidth: 3)
                .frame(width: 200, height: 200)
                .scaleEffect(breathingScale)
                .animation(
                    .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true),
                    value: breathingScale
                )
            
            // Middle Ring
            Circle()
                .stroke(DesignTokens.Colors.primary.opacity(0.5), lineWidth: 2)
                .frame(width: 160, height: 160)
                .scaleEffect(breathingScale * 0.8)
                .animation(
                    .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true)
                    .delay(0.5),
                    value: breathingScale
                )
            
            // Inner Ring
            Circle()
                .stroke(DesignTokens.Colors.primary.opacity(0.7), lineWidth: 1)
                .frame(width: 120, height: 120)
                .scaleEffect(breathingScale * 0.6)
                .animation(
                    .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true)
                    .delay(1.0),
                    value: breathingScale
                )
            
            // Center Action Button
            LegacyTalkButton(action: action)
        }
        .onAppear {
            breathingScale = 1.2
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: DesignTokens.Spacing.xxxl) {
        BreathingRing(
            intensity: 0.7,
            isAnimating: true,
            mode: .privateMode
        ) {
            print("Private mode action")
        }
        
        BreathingRing(
            intensity: 0.7,
            isAnimating: true,
            mode: .connected
        ) {
            print("Connected mode action")
        }
    }
    .padding()
    .background(DesignTokens.Colors.surface)
}
