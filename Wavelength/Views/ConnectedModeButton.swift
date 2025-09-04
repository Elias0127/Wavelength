import SwiftUI

struct ConnectedModeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Start Real-Time Conversation")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Voice therapy with live emotion analysis")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(DesignTokens.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [
                        DesignTokens.Colors.connectedMode,
                        DesignTokens.Colors.connectedMode.opacity(0.8),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .stroke(
                        DesignTokens.Colors.connectedMode.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .cornerRadius(DesignTokens.Radius.xl)
            .shadow(
                color: DesignTokens.Colors.connectedMode.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(ConnectedModeButtonStyle())
        .accessibilityLabel("Start real-time therapeutic conversation")
        .accessibilityHint("Opens voice therapy mode with live emotion analysis")
    }
}

struct ConnectedModeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 20) {
        ConnectedModeButton {
            print("Connected Mode tapped")
        }

        Text("Connected Mode Button Preview")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
    .background(Color(.systemBackground))
}
