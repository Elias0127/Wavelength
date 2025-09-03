import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var showRecordingModal = false
    @State private var showReflection = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    // Top bar
                    HStack {
                        ModeBadge(mode: appViewModel.mode)
                        
                        Spacer()
                        
                        // Streak chip
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(DesignTokens.Colors.warning)
                                .font(.system(size: 12))
                            
                            Text("\(appViewModel.streak) day streak")
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
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    // Hero section
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        // Breathing ring with talk button
                        BreathingRing(
                            intensity: appViewModel.latestEntry?.averageValence ?? 0.5,
                            isAnimating: !homeViewModel.isRecording
                        ) {
                            TalkButton {
                                showRecordingModal = true
                            }
                        }
                        
                        // Subtext
                        Text("Take a minute… what's on your mind?")
                            .bodyText()
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        // Daily prompt
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            Text("Today's prompt")
                                .captionText()
                            
                            Text(appViewModel.currentPrompt)
                                .bodyText()
                                .multilineTextAlignment(.center)
                                .padding(DesignTokens.Spacing.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                        .fill(DesignTokens.Colors.card)
                                )
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    // Recent section
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        SectionHeader(title: "Recent")
                        
                        if let latestEntry = appViewModel.latestEntry {
                            EntryCard(entry: latestEntry) {
                                // TODO: Navigate to entry detail
                            }
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                        } else {
                            EmptyState(
                                icon: "mic.slash",
                                title: "No entries yet",
                                message: "Start your journaling journey by tapping the Talk button to record your first entry.",
                                actionTitle: "Create First Entry"
                            ) {
                                showRecordingModal = true
                            }
                            .frame(height: 300)
                        }
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.surface)
            .navigationTitle("Wavelength")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showRecordingModal) {
            RecordingModalView(
                homeViewModel: homeViewModel,
                isPresented: $showRecordingModal
            )
        }
        .sheet(isPresented: $showReflection) {
            ReflectionView(
                transcript: homeViewModel.mockTranscript,
                appViewModel: appViewModel,
                isPresented: $showReflection
            )
        }
        .onChange(of: homeViewModel.showReflection) { showReflection in
            if showReflection {
                showRecordingModal = false
                self.showReflection = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView(appViewModel: AppViewModel())
}
