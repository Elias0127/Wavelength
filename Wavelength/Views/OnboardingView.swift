import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var selectedMode: Mode = .privateMode
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxxl) {
            Spacer()
            
            // App branding
            VStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "waveform")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(DesignTokens.Colors.primary)
                
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Wavelength")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("Voice-First Journaling Companion")
                        .bodyText()
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            // Mode selection
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("Choose your privacy mode")
                    .h2()
                    .multilineTextAlignment(.center)
                
                VStack(spacing: DesignTokens.Spacing.md) {
                    // Private Mode Card
                    ModeCard(
                        mode: .privateMode,
                        isSelected: selectedMode == .privateMode,
                        onTap: { selectedMode = .privateMode }
                    )
                    
                    // Connected Mode Card
                    ModeCard(
                        mode: .connected,
                        isSelected: selectedMode == .connected,
                        onTap: { selectedMode = .connected }
                    )
                }
            }
            
            Spacer()
            
            // Continue button
            VStack(spacing: DesignTokens.Spacing.lg) {
                Button(action: {
                    appViewModel.mode = selectedMode
                    appViewModel.completeOnboarding()
                }) {
                    Text("Continue")
                        .primaryButton()
                }
                .padding(.horizontal, DesignTokens.Spacing.xxxl)
                
                // Privacy notice
                VStack(spacing: DesignTokens.Spacing.sm) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .font(.system(size: 12))
                        
                        Text("Microphone/Speech permission needed later")
                            .captionText()
                    }
                    
                    Text("No data leaves device in Private Mode")
                        .captionText()
                }
            }
            
            Spacer()
        }
        .padding(DesignTokens.Spacing.xl)
        .background(DesignTokens.Colors.surface)
    }
}

// MARK: - Mode Card
struct ModeCard: View {
    let mode: Mode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.lg) {
                // Icon
                Image(systemName: mode.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : DesignTokens.Colors.primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.border)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(mode.displayName)
                        .font(DesignTokens.Typography.h2)
                        .foregroundColor(isSelected ? .white : DesignTokens.Colors.textPrimary)
                    
                    Text(mode.description)
                        .bodyText()
                        .foregroundColor(isSelected ? .white.opacity(0.8) : DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .stroke(
                                isSelected ? Color.clear : DesignTokens.Colors.border,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(appViewModel: AppViewModel())
}
