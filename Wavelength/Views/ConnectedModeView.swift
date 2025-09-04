import AVFoundation
import SwiftUI

struct ConnectedModeView: View {
    @StateObject private var connectedModeService = ConnectedModeService()
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false
    @State private var breathingPhase: Double = 0
    @State private var showSaveConversationSheet = false

    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3),
                    Color(.systemBackground),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Breathing animation overlay
            if connectedModeService.conversationState == .listening {
                BreathingOverlay(phase: breathingPhase)
                    .opacity(0.1)
            }

            VStack(spacing: 0) {
                // Immersive header
                immersiveHeaderView

                // Main conversation area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            // Live emotion visualization
                            LiveEmotionVisualization(state: connectedModeService.emotionStripState)

                            // Conversation flow
                            ConversationFlowView(
                                turns: connectedModeService.conversationTurns,
                                liveCaption: connectedModeService.liveCaptionState
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    .onChange(of: connectedModeService.conversationTurns.count) { _ in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            if let lastTurn = connectedModeService.conversationTurns.last {
                                proxy.scrollTo(lastTurn.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Floating action button
                floatingActionButton
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await connectedModeService.startConversation()
            }
            startBreathingAnimation()
        }
        .onDisappear {
            connectedModeService.stopConversation()
        }
        .alert("Error", isPresented: .constant(connectedModeService.errorMessage != nil)) {
            Button("OK") {
                connectedModeService.errorMessage = nil
            }
        } message: {
            if let errorMessage = connectedModeService.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showSaveConversationSheet) {
            SaveConversationSheet(
                conversationTurns: connectedModeService.conversationTurns,
                onSave: { entry in
                    // Save the entry to the journal
                    // This would typically be handled by a data service
                    print("Saving AI conversation entry: \(entry.title)")
                    showSaveConversationSheet = false
                    connectedModeService.stopConversation()
                    dismiss()
                },
                onCancel: {
                    showSaveConversationSheet = false
                    connectedModeService.stopConversation()
                }
            )
        }
    }

    // MARK: - Immersive Header

    private var immersiveHeaderView: some View {
        VStack(spacing: 16) {
            // Top bar with close and status
            HStack {
                Button(action: {
                    connectedModeService.stopConversation()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }

                Spacer()

                // Connection status
                HStack(spacing: 8) {
                    Circle()
                        .fill(connectionStatusColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(
                            connectedModeService.conversationState == .listening ? 1.2 : 1.0
                        )
                        .animation(
                            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                            value: connectedModeService.conversationState == .listening)

                    Text(connectedModeService.connectionStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // Title and status
            VStack(spacing: 8) {
                Text("Connected Mode")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                HStack(spacing: 12) {
                    // Status indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 10, height: 10)

                        Text(statusMessage)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(statusColor)
                    }

                    if connectedModeService.conversationState == .listening {
                        // Live indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                    value: isAnimating)

                            Text("LIVE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var connectionStatusColor: Color {
        switch connectedModeService.conversationState {
        case .idle: return .gray
        case .listening: return .green
        case .transcribing: return .blue
        case .analyzing: return .orange
        case .responding: return .purple
        case .error: return .red
        }
    }

    private var statusColor: Color {
        connectionStatusColor
    }

    private var statusMessage: String {
        switch connectedModeService.conversationState {
        case .idle: return "Ready to listen"
        case .listening: return "Listening intently"
        case .transcribing: return "Understanding you"
        case .analyzing: return "Processing emotions"
        case .responding: return "Crafting response"
        case .error(let message): return "Error: \(message)"
        }
    }

    // MARK: - Floating Action Button

    private var floatingActionButton: some View {
        VStack(spacing: 16) {
            // Kill switch (emergency stop)
            if connectedModeService.conversationState != .idle {
                Button(action: {
                    connectedModeService.killSwitch()
                }) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.red)
                        .clipShape(Circle())
                        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: isAnimating)
            }

            // Main action button
            Button(action: {
                if connectedModeService.conversationState == .idle {
                    Task {
                        await connectedModeService.startConversation()
                    }
                } else {
                    // Check if we have conversation turns to save
                    if !connectedModeService.conversationTurns.isEmpty {
                        showSaveConversationSheet = true
                    } else {
                        connectedModeService.stopConversation()
                    }
                }
            }) {
                ZStack {
                    // Pulsing background
                    if connectedModeService.conversationState == .listening {
                        Circle()
                            .fill(buttonColor.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                value: isAnimating)
                    }

                    // Main button
                    Circle()
                        .fill(buttonColor)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: buttonIcon)
                                .font(.title)
                                .foregroundColor(.white)
                        )
                        .shadow(color: buttonColor.opacity(0.4), radius: 12, x: 0, y: 6)
                }
            }
            .scaleEffect(connectedModeService.conversationState == .listening ? 1.1 : 1.0)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.6),
                value: connectedModeService.conversationState)
        }
        .padding(.bottom, 40)
    }

    private var buttonColor: Color {
        switch connectedModeService.conversationState {
        case .idle: return .blue
        case .listening: return .green
        case .transcribing: return .blue
        case .analyzing: return .orange
        case .responding: return .purple
        case .error: return .red
        }
    }

    private var buttonIcon: String {
        switch connectedModeService.conversationState {
        case .idle: return "mic.fill"
        case .listening: return "stop.fill"
        case .transcribing: return "waveform"
        case .analyzing: return "brain.head.profile"
        case .responding: return "bubble.left.and.bubble.right.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    // MARK: - Animation Helpers

    private func startBreathingAnimation() {
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            breathingPhase = 1.0
        }

        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
    }
}

// MARK: - Breathing Overlay

struct BreathingOverlay: View {
    let phase: Double

    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 200 + CGFloat(index * 100))
                    .scaleEffect(0.5 + (phase * 0.5))
                    .opacity(0.3 - (Double(index) * 0.1))
                    .animation(
                        .easeInOut(duration: 4.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.5),
                        value: phase
                    )
            }
        }
    }
}

// MARK: - Live Emotion Visualization

struct LiveEmotionVisualization: View {
    let state: EmotionStripState
    @State private var animationPhase: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            // Title
            HStack {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundColor(.pink)

                Text("Emotional State")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                // Trend indicator
                HStack(spacing: 6) {
                    Image(systemName: trendIcon)
                        .foregroundColor(trendColor)
                        .font(.caption)

                    Text(trendText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(trendColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(trendColor.opacity(0.1))
                .clipShape(Capsule())
            }

            // Emotion rings
            ZStack {
                // Background rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            emotionColors[index].opacity(0.2),
                            lineWidth: 8
                        )
                        .frame(width: 120 + CGFloat(index * 40))
                }

                // Active emotion rings
                ForEach(0..<3) { index in
                    Circle()
                        .trim(from: 0, to: emotionValues[index])
                        .stroke(
                            LinearGradient(
                                colors: [emotionColors[index], emotionColors[index].opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120 + CGFloat(index * 40))
                        .rotationEffect(.degrees(-90))
                        .scaleEffect(1.0 + (animationPhase * 0.05))
                        .animation(.easeInOut(duration: 0.8), value: emotionValues[index])
                }

                // Center content
                VStack(spacing: 8) {
                    Text("\(Int(overallIntensity * 100))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Emotional Intensity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 200)

            // Emotion labels
            HStack(spacing: 20) {
                ForEach(0..<3) { index in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(emotionColors[index])
                            .frame(width: 12, height: 12)

                        Text(emotionLabels[index])
                            .font(.caption)
                            .fontWeight(.medium)

                        Text("\(Int(emotionValues[index] * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.pink.opacity(0.3), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animationPhase = 1.0
            }
        }
    }

    private var emotionValues: [Double] {
        [state.arousal, (state.valence + 1) / 2, state.energy]
    }

    private var emotionColors: [Color] {
        [.orange, .blue, .green]
    }

    private var emotionLabels: [String] {
        ["Arousal", "Valence", "Energy"]
    }

    private var overallIntensity: Double {
        emotionValues.reduce(0, +) / Double(emotionValues.count)
    }

    private var trendIcon: String {
        switch state.trend {
        case .increasing: return "arrow.up.circle.fill"
        case .decreasing: return "arrow.down.circle.fill"
        case .stable: return "arrow.right.circle.fill"
        }
    }

    private var trendColor: Color {
        switch state.trend {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .blue
        }
    }

    private var trendText: String {
        switch state.trend {
        case .increasing: return "Rising"
        case .decreasing: return "Falling"
        case .stable: return "Stable"
        }
    }
}

// MARK: - Conversation Flow View

struct ConversationFlowView: View {
    let turns: [ConversationTurn]
    let liveCaption: LiveCaptionState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title2)
                    .foregroundColor(.purple)

                Text("Conversation")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Text("\(turns.count) turns")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }

            if turns.isEmpty && liveCaption.partialText.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("Start speaking to begin")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Your conversation will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                // Conversation turns
                LazyVStack(spacing: 20) {
                    ForEach(turns, id: \.id) { turn in
                        ConversationTurnView(turn: turn)
                            .onAppear {
                                print("🎯 Displaying conversation turn:")
                                print("   User: \(turn.userTranscript)")
                                print("   AI: \(turn.assistantResponse ?? "None")")
                            }
                    }

                    // Live caption (if active and not finalized)
                    if !liveCaption.partialText.isEmpty && !liveCaption.isFinalized {
                        LiveCaptionBubble(
                            text: liveCaption.partialText,
                            isLive: true,
                            wordCount: liveCaption.wordCount,
                            speakingRate: liveCaption.speakingRate
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Live Caption Bubble

struct LiveCaptionBubble: View {
    let text: String
    let isLive: Bool
    let wordCount: Int
    let speakingRate: Double
    @State private var isAnimating = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Text("You")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)

                        if isLive {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                                    .animation(
                                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                        value: isAnimating)

                                Text("LIVE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    Spacer()

                    Text("\(wordCount) words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Message
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        isLive ? Color.blue : Color.blue.opacity(0.3),
                                        lineWidth: isLive ? 2 : 1
                                    )
                            )
                    )

                // Stats
                HStack {
                    Text("Speaking rate: \(Int(speakingRate)) WPM")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if isLive {
                        Text("Listening...")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Conversation Turn View

struct ConversationTurnView: View {
    let turn: ConversationTurn

    var body: some View {
        VStack(spacing: 16) {
            // User message
            UserMessageBubble(
                text: turn.userTranscript,
                timestamp: turn.timestamp,
                prosody: turn.prosodySnapshot?.prosody
            )

            // Assistant response (if available)
            if let response = turn.assistantResponse {
                AssistantMessageBubble(
                    text: response,
                    timestamp: turn.timestamp
                )
            }
        }
    }
}

// MARK: - User Message Bubble

struct UserMessageBubble: View {
    let text: String
    let timestamp: Date
    let prosody: ProsodyData?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text("You")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)

                    Spacer()

                    Text(timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Message
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )

                // Emotion metrics
                if let prosody = prosody {
                    EmotionMetricsView(prosody: prosody)
                }
            }
        }
    }
}

// MARK: - Assistant Message Bubble

struct AssistantMessageBubble: View {
    let text: String
    let timestamp: Date

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 8) {
                // Header
                HStack {
                    Text(timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.purple)

                        Text("Wavelength AI")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                    }
                }

                // Message
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.purple.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                    )
            }

            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Emotion Metrics View

struct EmotionMetricsView: View {
    let prosody: ProsodyData

    var body: some View {
        HStack(spacing: 16) {
            EmotionMetric(
                title: "Arousal",
                value: prosody.arousal,
                color: .orange
            )

            EmotionMetric(
                title: "Valence",
                value: (prosody.valence + 1) / 2,
                color: .blue
            )

            EmotionMetric(
                title: "Energy",
                value: prosody.energy,
                color: .green
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Emotion Metric

struct EmotionMetric: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)

            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 3)
                    .frame(width: 32, height: 32)

                Circle()
                    .trim(from: 0, to: value)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: value)

                Text("\(Int(value * 100))")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
        }
    }
}

#Preview {
    ConnectedModeView()
}
