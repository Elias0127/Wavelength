import SwiftUI

// MARK: - Recording Modal View
struct RecordingModalView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @Binding var isPresented: Bool
    @State private var showPermissionAlert = false
    @State private var recordingPulse = false
    @State private var waveAnimation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        DesignTokens.Colors.surface,
                        DesignTokens.Colors.card.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: DesignTokens.Spacing.xxxl) {
                    Spacer()
                    
                    // Recording indicator with enhanced animations
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        ZStack {
                            // Outer pulse rings
                            if homeViewModel.isRecording {
                                ForEach(0..<3, id: \.self) { index in
                                    Circle()
                                        .stroke(
                                            DesignTokens.Colors.primary.opacity(0.3 - Double(index) * 0.1),
                                            lineWidth: 2
                                        )
                                        .frame(width: 200 + CGFloat(index * 40), height: 200 + CGFloat(index * 40))
                                        .scaleEffect(recordingPulse ? 1.2 : 0.8)
                                        .opacity(recordingPulse ? 0.0 : 1.0)
                                        .animation(
                                            .easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: false)
                                            .delay(Double(index) * 0.3),
                                            value: recordingPulse
                                        )
                                }
                            }
                            
                            // Main breathing ring
                            BreathingRing(
                                intensity: homeViewModel.isRecording ? 0.9 : 0.5,
                                isAnimating: true
                            ) {
                                ZStack {
                                    // Microphone icon with wave animation
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 40, weight: .medium))
                                        .foregroundColor(homeViewModel.isRecording ? .white : DesignTokens.Colors.primary)
                                        .scaleEffect(homeViewModel.isRecording ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 0.5), value: homeViewModel.isRecording)
                                    
                                    // Recording indicator
                                    if homeViewModel.isRecording {
                                        Circle()
                                            .fill(DesignTokens.Colors.danger)
                                            .frame(width: 12, height: 12)
                                            .offset(x: 25, y: -25)
                                            .scaleEffect(recordingPulse ? 1.5 : 1.0)
                                            .opacity(recordingPulse ? 0.0 : 1.0)
                                            .animation(
                                                .easeInOut(duration: 0.8)
                                                .repeatForever(autoreverses: false),
                                                value: recordingPulse
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Enhanced timer with better typography
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            Text(homeViewModel.formattedDuration)
                                .font(.system(size: 52, weight: .ultraLight, design: .monospaced))
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .contentTransition(.numericText())
                            
                            // Status text with animation
                            Text(homeViewModel.isRecording ? "Listening..." : "Ready to listen")
                                .bodyText()
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .opacity(waveAnimation ? 0.5 : 1.0)
                                .animation(
                                    .easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true),
                                    value: waveAnimation
                                )
                        }
                    }
                    
                    Spacer()
                    
                    // Enhanced action buttons
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        if homeViewModel.isRecording {
                            // Stop recording button with enhanced design
                            Button(action: {
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                impactFeedback.impactOccurred()
                                homeViewModel.stopRecording()
                            }) {
                                HStack(spacing: DesignTokens.Spacing.md) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Stop & Continue")
                                        .font(DesignTokens.Typography.button)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                        .fill(
                                            LinearGradient(
                                                colors: [DesignTokens.Colors.primary, DesignTokens.Colors.primary.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: DesignTokens.Shadows.button, radius: 8, x: 0, y: 4)
                                )
                            }
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 0.1), value: homeViewModel.isRecording)
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
                            // Start recording button with enhanced design
                            Button(action: {
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                homeViewModel.startRecording()
                            }) {
                                HStack(spacing: DesignTokens.Spacing.md) {
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Start Recording")
                                        .font(DesignTokens.Typography.button)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                        .fill(
                                            LinearGradient(
                                                colors: [DesignTokens.Colors.primary, DesignTokens.Colors.primary.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: DesignTokens.Shadows.button, radius: 8, x: 0, y: 4)
                                )
                            }
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 0.1), value: homeViewModel.isRecording)
                            .padding(.horizontal, DesignTokens.Spacing.xxxl)
                        }
                    }
                    
                    Spacer()
                    
                    // Enhanced hint text with better visual hierarchy
                    VStack(spacing: DesignTokens.Spacing.md) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "waveform")
                                .foregroundColor(DesignTokens.Colors.primary)
                                .font(.system(size: 14))
                            
                            Text("Speak naturally about what's on your mind")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        Text("Your words are processed locally and never leave your device")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                }
                .padding(DesignTokens.Spacing.xl)
            }
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
        .onAppear {
            waveAnimation = true
        }
        .onChange(of: homeViewModel.isRecording) {
            if homeViewModel.isRecording {
                recordingPulse = true
            } else {
                recordingPulse = false
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
