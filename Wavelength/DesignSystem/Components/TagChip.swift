import SwiftUI

// MARK: - Tag Chip Component
struct TagChip: View {
    let text: String
    let isSelected: Bool
    let onTap: (() -> Void)?
    
    init(text: String, isSelected: Bool = false, onTap: (() -> Void)? = nil) {
        self.text = text
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            Text(text)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(isSelected ? .white : DesignTokens.Colors.textSecondary)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                        .fill(
                            isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.border
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Tag: \(text)")
        .accessibilityHint(isSelected ? "Selected" : "Tap to select")
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: DesignTokens.Spacing.md) {
        HStack(spacing: DesignTokens.Spacing.sm) {
            TagChip(text: "work")
            TagChip(text: "anxiety", isSelected: true)
            TagChip(text: "family")
        }
        
        HStack(spacing: DesignTokens.Spacing.sm) {
            TagChip(text: "sleep", isSelected: true)
            TagChip(text: "exercise")
            TagChip(text: "creativity")
        }
    }
    .padding()
    .background(DesignTokens.Colors.surface)
}
