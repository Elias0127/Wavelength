import SwiftUI

// MARK: - Talk Button Component
struct TalkButton: View {
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
    TalkButton(action: {})
        .padding()
        .background(DesignTokens.Colors.surface)
}
