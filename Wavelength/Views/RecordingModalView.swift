import SwiftUI

// MARK: - Recording Modal View
struct RecordingModalView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @Binding var isPresented: Bool
    @State private var showPermissionAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignTokens.Spacing.xxxl) {
                Spacer()
                
                // Recording indicator
                VStack(spacing: DesignTokens.Spacing.xl) {
                    // Breathing ring with mic icon
                    BreathingRing(
                        intensity: 0.8,
                        isAnimating: homeViewModel.isRecording
                    ) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
                    
                    // Timer
                    Text(homeViewModel.formattedDuration)
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    // Status text
                    Text(homeViewModel.isRecording ? "Listening..." : "Tap to start recording")
                        .bodyText()
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: DesignTokens.Spacing.lg) {
                    if homeViewModel.isRecording {
                        // Stop recording button
                        Button(action: {
                            homeViewModel.stopRecording()
                        }) {
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "stop.fill")
                                Text("Stop & Continue")
                            }
                            .primaryButton()
                        }
                        .padding(.horizontal, DesignTokens.Spacing.xxxl)
                        
                        // Cancel button
                        Button(action: {
                            homeViewModel.cancelRecording()
                            isPresented = false
                        }) {
                            Text("Cancel")
                                .secondaryButton()
                        }
                        .padding(.horizontal, DesignTokens.Spacing.xxxl)
                    } else {
                        // Start recording button
                        Button(action: {
                            // TODO: Check microphone permissions
                            homeViewModel.startRecording()
                        }) {
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "mic.fill")
                                Text("Start Recording")
                            }
                            .primaryButton()
                        }
                        .padding(.horizontal, DesignTokens.Spacing.xxxl)
                    }
                }
                
                Spacer()
                
                // Hint text
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Speak naturally about what's on your mind")
                        .captionText()
                        .multilineTextAlignment(.center)
                    
                    Text("Your words are processed locally and never leave your device")
                        .captionText()
                        .multilineTextAlignment(.center)
                        .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.7))
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
            }
            .padding(DesignTokens.Spacing.xl)
            .background(DesignTokens.Colors.surface)
            .navigationTitle("Voice Journal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        homeViewModel.cancelRecording()
                        isPresented = false
                    }
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .alert("Microphone Permission Required", isPresented: $showPermissionAlert) {
            Button("Settings") {
                // TODO: Open app settings
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Wavelength needs microphone access to record your voice. Please enable it in Settings.")
        }
    }
}

// MARK: - Preview
#Preview {
    RecordingModalView(
        homeViewModel: HomeViewModel(),
        isPresented: .constant(true)
    )
}
