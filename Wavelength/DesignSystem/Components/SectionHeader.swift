import SwiftUI

// MARK: - Section Header Component
struct SectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        HStack {
            Text(title)
                .sectionTitle()
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.primary)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: DesignTokens.Spacing.lg) {
        SectionHeader(title: "Recent Entries")
        
        SectionHeader(title: "This Week", actionTitle: "See all") {
            // Action
        }
        
        SectionHeader(title: "Insights")
    }
    .padding()
    .background(DesignTokens.Colors.surface)
}
