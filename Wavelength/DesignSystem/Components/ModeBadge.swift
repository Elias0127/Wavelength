import SwiftUI

// MARK: - Enhanced Privacy Mode Toggle Component
struct PrivacyModeToggle: View {
    @Binding var mode: Mode
    let onModeChange: () -> Void
    
    @State private var isAnimating = false
    @State private var showPrivacyInfo = false
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Main Mode Toggle
            VStack(spacing: DesignTokens.Spacing.sm) {
                // Mode Indicator with Animation
                HStack(spacing: DesignTokens.Spacing.md) {
                    // Privacy Icon with Pulse Animation
                    ZStack {
                        Circle()
                            .fill(mode == .privateMode ? 
                                  DesignTokens.Colors.privateMode.opacity(0.2) : 
                                  DesignTokens.Colors.connectedMode.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                        
                        Image(systemName: mode.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(mode == .privateMode ? 
                                           DesignTokens.Colors.privateMode : 
                                           DesignTokens.Colors.connectedMode)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mode.displayName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text(mode.description)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Toggle Button
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            mode = mode == .privateMode ? .connected : .privateMode
                            onModeChange()
                        }
                    }) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Text("Switch")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                .fill(DesignTokens.Colors.border)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                        .stroke(DesignTokens.Colors.primary.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(DesignTokens.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(mode == .privateMode ? 
                              DesignTokens.Colors.privateMode.opacity(0.05) : 
                              DesignTokens.Colors.connectedMode.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .stroke(
                                    mode == .privateMode ? 
                                    DesignTokens.Colors.privateMode.opacity(0.3) : 
                                    DesignTokens.Colors.connectedMode.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
                
                // Privacy Info Button
                Button(action: {
                    showPrivacyInfo.toggle()
                }) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Text("Learn about privacy")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
            }
            
            // Privacy Information Sheet
            if showPrivacyInfo {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack {
                        Image(systemName: mode == .privateMode ? "lock.shield" : "globe.americas")
                            .foregroundColor(mode == .privateMode ? 
                                           DesignTokens.Colors.privateMode : 
                                           DesignTokens.Colors.connectedMode)
                            .font(.system(size: 16))
                        
                        Text(mode == .privateMode ? "Complete Privacy" : "Enhanced AI Companion")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    
                    Text(mode == .privateMode ? 
                         "All processing happens on your device. Your voice, thoughts, and data never leave your phone. Perfect for sensitive reflections." :
                         "Advanced AI analyzes your voice tone and provides deeper emotional insights. Minimal audio data is processed securely in the cloud.")
                        .font(.system(size: 12))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(nil)
                }
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                .stroke(DesignTokens.Colors.border, lineWidth: 1)
                        )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Legacy Mode Badge (for backward compatibility)
struct ModeBadge: View {
    let mode: Mode
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: mode.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(mode == .privateMode ? DesignTokens.Colors.privateMode : DesignTokens.Colors.connectedMode)
            
            Text(mode.displayName)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(DesignTokens.Colors.border)
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: DesignTokens.Spacing.lg) {
        PrivacyModeToggle(mode: .constant(.privateMode)) {
            print("Mode changed")
        }
        PrivacyModeToggle(mode: .constant(.connected)) {
            print("Mode changed")
        }
    }
    .padding()
    .background(DesignTokens.Colors.surface)
}
