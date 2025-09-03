import SwiftUI

// MARK: - Mode Badge Component
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
        ModeBadge(mode: .privateMode)
        ModeBadge(mode: .connected)
    }
    .padding()
    .background(DesignTokens.Colors.surface)
}
