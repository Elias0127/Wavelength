import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @State private var showShareSheet = false
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self._settingsViewModel = StateObject(wrappedValue: SettingsViewModel(
            onModeToggle: {
                appViewModel.toggleMode()
            },
            onExportData: {
                appViewModel.exportData()
            },
            onEraseData: {
                appViewModel.eraseAllData()
            }
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    // Mode toggle section
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("Privacy Mode")
                            .h2()
                        
                        VStack(spacing: DesignTokens.Spacing.md) {
                            HStack {
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                    Text(appViewModel.mode.displayName)
                                        .bodyText()
                                    
                                    Text(appViewModel.mode.description)
                                        .captionText()
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { appViewModel.mode == .connected },
                                    set: { _ in settingsViewModel.toggleMode() }
                                ))
                                .tint(DesignTokens.Colors.primary)
                            }
                            .padding(DesignTokens.Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                    .fill(DesignTokens.Colors.card)
                            )
                        }
                    }
                    .cardBackground()
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    // Privacy panel
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("Privacy & Data")
                            .h2()
                        
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            SettingsRow(
                                icon: "square.and.arrow.up",
                                title: "Export Data",
                                subtitle: "Download your journal entries",
                                action: settingsViewModel.exportData
                            )
                            
                            Divider()
                                .background(DesignTokens.Colors.border)
                            
                            SettingsRow(
                                icon: "trash",
                                title: "Erase All Data",
                                subtitle: "Permanently delete all entries",
                                action: settingsViewModel.eraseData,
                                isDestructive: true
                            )
                        }
                        .padding(DesignTokens.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .fill(DesignTokens.Colors.card)
                        )
                    }
                    .cardBackground()
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    // Privacy information
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("Privacy Information")
                            .h2()
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            Text("Your privacy is our priority. In Private Mode, all data stays on your device. In Connected Mode, only minimal audio features are processed externally.")
                                .bodyText()
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            Button(action: {
                                settingsViewModel.showPrivacy()
                            }) {
                                Text("Learn More")
                                    .foregroundColor(DesignTokens.Colors.primary)
                            }
                        }
                        .padding(DesignTokens.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .fill(DesignTokens.Colors.card)
                        )
                    }
                    .cardBackground()
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    // Disclaimers
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("Important Disclaimers")
                            .h2()
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            Text("• Wavelength is not a substitute for professional therapy or medical advice")
                            Text("• AI reflections are generated responses and should not be considered professional counseling")
                            Text("• If you're experiencing a crisis, please contact emergency services or a mental health professional")
                            
                            Button(action: {
                                settingsViewModel.showCrisis()
                            }) {
                                Text("Crisis Resources")
                                    .foregroundColor(DesignTokens.Colors.danger)
                            }
                        }
                        .bodyText()
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .padding(DesignTokens.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .fill(DesignTokens.Colors.card)
                        )
                    }
                    .cardBackground()
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    // About section
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Text("Wavelength")
                            .h2()
                        
                        Text("Version \(settingsViewModel.appVersion) (\(settingsViewModel.buildNumber))")
                            .captionText()
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Text("Voice-First Journaling Companion")
                            .captionText()
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    .padding(DesignTokens.Spacing.xl)
                }
                .padding(.vertical, DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.surface)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $settingsViewModel.showExportSheet) {
            // TODO: Export sheet implementation
            Text("Export functionality would be implemented here")
        }
        .alert("Erase All Data", isPresented: $settingsViewModel.showEraseConfirmation) {
            Button("Erase", role: .destructive) {
                settingsViewModel.confirmErase()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your journal entries. This action cannot be undone.")
        }
        .sheet(isPresented: $settingsViewModel.showPrivacySheet) {
            PrivacySheet()
        }
        .sheet(isPresented: $settingsViewModel.showCrisisResources) {
            CrisisResourcesSheet()
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    let isDestructive: Bool
    
    init(icon: String, title: String, subtitle: String, action: @escaping () -> Void, isDestructive: Bool = false) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: icon)
                    .foregroundColor(isDestructive ? DesignTokens.Colors.danger : DesignTokens.Colors.primary)
                    .font(.system(size: 20))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(title)
                        .bodyText()
                        .foregroundColor(isDestructive ? DesignTokens.Colors.danger : DesignTokens.Colors.textPrimary)
                    
                    Text(subtitle)
                        .captionText()
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .font(.system(size: 12))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Privacy Sheet
struct PrivacySheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    Text("Privacy Policy")
                        .h1()
                    
                    Text("Your privacy is fundamental to Wavelength. Here's how we protect your data:")
                        .bodyText()
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Private Mode (Default)")
                            .h2()
                        
                        Text("• All data stays on your device")
                        Text("• No internet connection required")
                        Text("• Speech-to-text processing happens locally")
                        Text("• No data is sent to external servers")
                    }
                    .bodyText()
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Connected Mode (Optional)")
                            .h2()
                        
                        Text("• Only minimal audio features are processed externally")
                        Text("• Your transcripts and reflections remain local")
                        Text("• Enhanced empathy through prosody analysis")
                        Text("• You can switch modes anytime")
                    }
                    .bodyText()
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.surface)
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Crisis Resources Sheet
struct CrisisResourcesSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    Text("Crisis Resources")
                        .h1()
                    
                    Text("If you're experiencing a mental health crisis, please reach out for help:")
                        .bodyText()
                    
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        CrisisResourceCard(
                            title: "988 Suicide & Crisis Lifeline",
                            number: "988",
                            description: "24/7 crisis support in the US"
                        )
                        
                        CrisisResourceCard(
                            title: "Crisis Text Line",
                            number: "Text HOME to 741741",
                            description: "24/7 crisis support via text"
                        )
                        
                        CrisisResourceCard(
                            title: "Emergency Services",
                            number: "911",
                            description: "For immediate emergency assistance"
                        )
                    }
                    
                    Text("For international resources, please contact your local emergency services or mental health organizations.")
                        .captionText()
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.surface)
            .navigationTitle("Crisis Resources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Crisis Resource Card
struct CrisisResourceCard: View {
    let title: String
    let number: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(title)
                .h2()
            
            Text(number)
                .bodyText()
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text(description)
                .captionText()
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .padding(DesignTokens.Spacing.lg)
        .cardBackground()
    }
}

// MARK: - Preview
#Preview {
    SettingsView(appViewModel: AppViewModel())
}
