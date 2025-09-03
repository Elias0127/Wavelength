import SwiftUI

// MARK: - Reusable Style Modifiers
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DesignTokens.Colors.card)
            .cornerRadius(DesignTokens.Radius.lg)
            .shadow(color: DesignTokens.Shadows.card, radius: 8, x: 0, y: 4)
    }
}

struct SectionTitle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(DesignTokens.Typography.h2)
            .foregroundColor(DesignTokens.Colors.textPrimary)
    }
}

struct Pill: ViewModifier {
    let backgroundColor: Color
    let textColor: Color
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .font(DesignTokens.Typography.caption)
            .cornerRadius(DesignTokens.Radius.xl)
    }
}

struct PrimaryButton: ViewModifier {
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        content
            .font(DesignTokens.Typography.button)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                isEnabled ? DesignTokens.Colors.primary : DesignTokens.Colors.border
            )
            .cornerRadius(DesignTokens.Radius.lg)
            .shadow(color: DesignTokens.Shadows.button, radius: 4, x: 0, y: 2)
    }
}

struct SecondaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(DesignTokens.Typography.button)
            .foregroundColor(DesignTokens.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(DesignTokens.Colors.border)
            .cornerRadius(DesignTokens.Radius.lg)
    }
}

// MARK: - View Extensions
extension View {
    func cardBackground() -> some View {
        modifier(CardBackground())
    }
    
    func sectionTitle() -> some View {
        modifier(SectionTitle())
    }
    
    func pill(backgroundColor: Color = DesignTokens.Colors.border, textColor: Color = DesignTokens.Colors.textPrimary) -> some View {
        modifier(Pill(backgroundColor: backgroundColor, textColor: textColor))
    }
    
    func primaryButton(isEnabled: Bool = true) -> some View {
        modifier(PrimaryButton(isEnabled: isEnabled))
    }
    
    func secondaryButton() -> some View {
        modifier(SecondaryButton())
    }
    
    func h1() -> some View {
        font(DesignTokens.Typography.h1)
            .foregroundColor(DesignTokens.Colors.textPrimary)
    }
    
    func h2() -> some View {
        font(DesignTokens.Typography.h2)
            .foregroundColor(DesignTokens.Colors.textPrimary)
    }
    
    func bodyText() -> some View {
        font(DesignTokens.Typography.body)
            .foregroundColor(DesignTokens.Colors.textPrimary)
    }
    
    func captionText() -> some View {
        font(DesignTokens.Typography.caption)
            .foregroundColor(DesignTokens.Colors.textSecondary)
    }
}
