import SwiftUI

struct HomeView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var showRecordingModal = false
    @State private var showReflection = false
    @State private var showModeTransition = false
    @State private var showConnectedMode = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Immersive Background
                backgroundGradient

                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.xl) {

                        // Enhanced Privacy Mode Toggle
                        PrivacyModeToggle(mode: $appViewModel.mode) {
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                                showModeTransition = true
                            }

                            // Hide transition after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    showModeTransition = false
                                }
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)

                        // Streak Display
                        HStack {
                            Spacer()

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
                                    .fill(DesignTokens.Colors.border.opacity(0.5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                                            .stroke(
                                                DesignTokens.Colors.warning.opacity(0.3),
                                                lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)

                        // Enhanced Breathing Ring with Mode-specific Experience
                        BreathingRing(
                            intensity: appViewModel.latestEntry?.averageValence ?? 0.5,
                            isAnimating: !homeViewModel.isRecording,
                            mode: appViewModel.mode
                        ) {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                            impactFeedback.impactOccurred()
                            showRecordingModal = true
                        }
                        .padding(.vertical, DesignTokens.Spacing.xl)

                        // Connected Mode Button (only show when in connected mode)
                        if appViewModel.mode == .connected {
                            ConnectedModeButton {
                                showConnectedMode = true
                            }
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                        }

                        // Mode-specific Prompt Section
                        VStack(spacing: DesignTokens.Spacing.md) {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                Image(
                                    systemName: appViewModel.mode == .privateMode
                                        ? "lightbulb.fill" : "brain.head.profile"
                                )
                                .foregroundColor(
                                    appViewModel.mode == .privateMode
                                        ? DesignTokens.Colors.warning
                                        : DesignTokens.Colors.connectedMode
                                )
                                .font(.system(size: 14))

                                Text(
                                    appViewModel.mode == .privateMode
                                        ? "Today's prompt" : "AI-enhanced prompt"
                                )
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            }

                            Text(appViewModel.currentPrompt)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .padding(DesignTokens.Spacing.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                        .fill(DesignTokens.Colors.card)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            (appViewModel.mode == .privateMode
                                                                ? DesignTokens.Colors.privateMode
                                                                : DesignTokens.Colors.connectedMode)
                                                                .opacity(0.3),
                                                            (appViewModel.mode == .privateMode
                                                                ? DesignTokens.Colors.privateMode
                                                                : DesignTokens.Colors.connectedMode)
                                                                .opacity(0.1),
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)

                        // Recent Entries Section
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                            SectionHeader(title: "Recent")

                            if let latestEntry = appViewModel.latestEntry {
                                EntryCard(entry: latestEntry) {
                                    // Handle entry tap
                                }
                                .padding(.horizontal, DesignTokens.Spacing.lg)
                            } else {
                                EmptyState(
                                    icon: "mic.slash",
                                    title: "No entries yet",
                                    message:
                                        "Start your journaling journey by tapping the Talk button to record your first entry.",
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

                // Mode Transition Overlay
                if showModeTransition {
                    modeTransitionOverlay
                }
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
                transcript: homeViewModel.transcript,
                appViewModel: appViewModel,
                isPresented: $showReflection
            )
        }
        .sheet(isPresented: $showConnectedMode) {
            ConnectedModeView()
        }
        .onChange(of: homeViewModel.showReflection) {
            if homeViewModel.showReflection {
                showRecordingModal = false
                self.showReflection = true
            }
        }
    }

    // MARK: - Computed Properties

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                DesignTokens.Colors.surface,
                appViewModel.mode == .privateMode
                    ? DesignTokens.Colors.privateMode.opacity(0.05)
                    : DesignTokens.Colors.connectedMode.opacity(0.05),
                DesignTokens.Colors.surface,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var modeTransitionOverlay: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .blur(radius: 20)

            VStack(spacing: DesignTokens.Spacing.xl) {
                // Mode Icon
                Image(
                    systemName: appViewModel.mode == .privateMode ? "lock.shield" : "globe.americas"
                )
                .font(.system(size: 60, weight: .light))
                .foregroundColor(
                    appViewModel.mode == .privateMode
                        ? DesignTokens.Colors.privateMode : DesignTokens.Colors.connectedMode
                )
                .scaleEffect(showModeTransition ? 1.2 : 0.8)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showModeTransition)

                // Mode Text
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text(appViewModel.mode == .privateMode ? "Private Mode" : "Connected Mode")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    Text(
                        appViewModel.mode == .privateMode
                            ? "Your thoughts stay with you" : "Enhanced AI companion activated"
                    )
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                }
                .opacity(showModeTransition ? 1 : 0)
                .animation(.easeIn(duration: 0.5).delay(0.3), value: showModeTransition)
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    HomeView(appViewModel: AppViewModel())
}
