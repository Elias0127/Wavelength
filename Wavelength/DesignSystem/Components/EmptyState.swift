import SwiftUI

// MARK: - Empty State Component
struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String = "book.closed",
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            // Content
            VStack(spacing: DesignTokens.Spacing.md) {
                Text(title)
                    .h2()
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .bodyText()
                    .multilineTextAlignment(.center)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .primaryButton()
                }
                .padding(.horizontal, DesignTokens.Spacing.xxxl)
            }
        }
        .padding(DesignTokens.Spacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.surface)
    }
}

// MARK: - Preview
#Preview {
    EmptyState(
        icon: "mic.slash",
        title: "No entries yet",
        message: "Start your journaling journey by tapping the Talk button to record your first entry.",
        actionTitle: "Create First Entry"
    ) {
        // Action
    }
}
