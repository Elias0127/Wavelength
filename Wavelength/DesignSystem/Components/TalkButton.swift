import SwiftUI

// MARK: - Enhanced Talk Button Component
struct TalkButton: View {
    let action: () -> Void
    let mode: Mode
    
    @State private var isPressed = false
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            ZStack {
                // Background Circle with Mode-specific Styling
                Circle()
                    .fill(
                        LinearGradient(
                            colors: mode == .privateMode ? 
                                [DesignTokens.Colors.privateMode, DesignTokens.Colors.privateMode.opacity(0.8)] :
                                [DesignTokens.Colors.connectedMode, DesignTokens.Colors.connectedMode.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .shadow(
                        color: mode == .privateMode ? 
                            DesignTokens.Colors.privateMode.opacity(0.4) : 
                            DesignTokens.Colors.connectedMode.opacity(0.4),
                        radius: mode == .connected ? 16 : 8,
                        x: 0,
                        y: mode == .connected ? 8 : 4
                    )
                
                // Connected Mode Special Effects
                if mode == .connected {
                    // Outer Pulse Ring
                    Circle()
                        .stroke(
                            DesignTokens.Colors.connectedMode.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    // Inner Glow Effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    DesignTokens.Colors.connectedMode.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                // Main Content
                VStack(spacing: DesignTokens.Spacing.sm) {
                    // Mode-specific Icon
                    Image(systemName: mode == .privateMode ? "mic.fill" : "brain.head.profile")
                        .font(.system(size: mode == .connected ? 28 : 32, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating && mode == .connected ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    Text(mode == .privateMode ? "Talk" : "Connect")
                        .font(DesignTokens.Typography.button)
                        .foregroundColor(.white)
                    
                    // Connected Mode Subtitle
                    if mode == .connected {
                        Text("AI Enhanced")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            isAnimating = true
            if mode == .connected {
                pulseScale = 1.3
            }
        }
        .accessibilityLabel(mode == .privateMode ? "Start private voice recording" : "Start AI-enhanced voice recording")
        .accessibilityHint("Tap to record your thoughts with \(mode == .privateMode ? "complete privacy" : "advanced AI analysis")")
    }
}

struct LegacyTalkButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Talk")
                    .font(DesignTokens.Typography.button)
                    .foregroundColor(.white)
            }
            .frame(width: 120, height: 120)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignTokens.Colors.primary, DesignTokens.Colors.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: DesignTokens.Shadows.button, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel("Start voice recording")
        .accessibilityHint("Tap and hold to record your thoughts")
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: DesignTokens.Spacing.xl) {
        TalkButton(action: {}, mode: .privateMode)
        TalkButton(action: {}, mode: .connected)
    }
    .padding()
    .background(DesignTokens.Colors.surface)
}
