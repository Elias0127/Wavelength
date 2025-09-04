import AVFoundation
import SwiftUI

struct ConnectedModeView: View {
    @StateObject private var connectedModeService = ConnectedModeService()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with status and controls
                headerView

                // Main content area
                ScrollView {
                    VStack(spacing: 20) {
                        // Live caption view
                        LiveCaptionView(state: connectedModeService.liveCaptionState)

                        // Emotion strip
                        EmotionStripView(state: connectedModeService.emotionStripState)

                        // Conversation thread
                        ThreadView(turns: connectedModeService.conversationTurns)
                    }
                    .padding()
                }

                // Bottom controls
                bottomControlsView
            }
            .background(Color(.systemBackground))
            .navigationTitle("Connected Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        connectedModeService.stopConversation()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    killSwitchButton
                }
            }
        }
        .onAppear {
            Task {
                await connectedModeService.startConversation()
            }
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
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 12) {
            // Status indicator
            HStack {
                statusIndicator
                Spacer()
                statusText
            }
            .padding(.horizontal)

            // Mic pulse indicator
            if connectedModeService.conversationState == .listening {
                micPulseIndicator
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 2)
                    .scaleEffect(connectedModeService.conversationState == .listening ? 1.5 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: connectedModeService.conversationState == .listening
                    )
            )
    }

    private var statusText: some View {
        Text(statusMessage)
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private var statusColor: Color {
        switch connectedModeService.conversationState {
        case .idle:
            return .gray
        case .listening:
            return .green
        case .transcribing:
            return .blue
        case .analyzing:
            return .orange
        case .responding:
            return .purple
        case .error:
            return .red
        }
    }

    private var statusMessage: String {
        switch connectedModeService.conversationState {
        case .idle:
            return "Ready"
        case .listening:
            return "Listening"
        case .transcribing:
            return "Transcribing"
        case .analyzing:
            return "Analyzing"
        case .responding:
            return "Responding"
        case .error(let message):
            return "Error: \(message)"
        }
    }

    private var micPulseIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green)
                    .frame(width: 4, height: 20)
                    .scaleEffect(y: 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: connectedModeService.conversationState == .listening
                    )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Bottom Controls

    private var bottomControlsView: some View {
        HStack(spacing: 20) {
            // Start/Stop button
            Button(action: {
                if connectedModeService.conversationState == .idle {
                    Task {
                        await connectedModeService.startConversation()
                    }
                } else {
                    connectedModeService.stopConversation()
                }
            }) {
                HStack {
                    Image(
                        systemName: connectedModeService.conversationState == .idle
                            ? "mic.fill" : "stop.fill")
                    Text(connectedModeService.conversationState == .idle ? "Start" : "Stop")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    connectedModeService.conversationState == .idle ? Color.blue : Color.red
                )
                .cornerRadius(25)
            }

            // Kill switch
            killSwitchButton
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private var killSwitchButton: some View {
        Button(action: {
            connectedModeService.killSwitch()
        }) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
        }
        .disabled(connectedModeService.conversationState == .idle)
    }
}

// MARK: - Live Caption View

struct LiveCaptionView: View {
    let state: LiveCaptionState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.blue)
                Text("Live Caption")
                    .font(.headline)
                Spacer()
                Text("\(state.wordCount) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(state.partialText.isEmpty ? "Listening..." : state.partialText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(state.partialText.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(state.isFinalized ? Color(.systemGray5) : Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(state.isFinalized ? Color.blue : Color.clear, lineWidth: 2)
                        )
                )

            HStack {
                Text("Speaking rate: \(Int(state.speakingRate)) WPM")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if !state.isFinalized {
                    Text("Live")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
    }
}

// MARK: - Emotion Strip View

struct EmotionStripView: View {
    let state: EmotionStripState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text("Emotion")
                    .font(.headline)
                Spacer()
                trendIndicator
            }

            HStack(spacing: 16) {
                emotionIndicator(title: "Arousal", value: state.arousal, color: .orange)
                emotionIndicator(title: "Valence", value: (state.valence + 1) / 2, color: .blue)
                emotionIndicator(title: "Energy", value: state.energy, color: .green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var trendIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: trendIcon)
                .foregroundColor(trendColor)
            Text(trendText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var trendIcon: String {
        switch state.trend {
        case .increasing:
            return "arrow.up"
        case .decreasing:
            return "arrow.down"
        case .stable:
            return "arrow.right"
        }
    }

    private var trendColor: Color {
        switch state.trend {
        case .increasing:
            return .green
        case .decreasing:
            return .red
        case .stable:
            return .gray
        }
    }

    private var trendText: String {
        switch state.trend {
        case .increasing:
            return "Rising"
        case .decreasing:
            return "Falling"
        case .stable:
            return "Stable"
        }
    }

    private func emotionIndicator(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 4)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: value)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: value)

                Text("\(Int(value * 100))")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
    }
}

// MARK: - Thread View

struct ThreadView: View {
    let turns: [ConversationTurn]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.purple)
                Text("Conversation")
                    .font(.headline)
                Spacer()
                Text("\(turns.count) turns")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if turns.isEmpty {
                Text("No conversation turns yet...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(turns, id: \.id) { turn in
                        TurnView(turn: turn)
                    }
                }
            }
        }
    }
}

// MARK: - Turn View

struct TurnView: View {
    let turn: ConversationTurn

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // User message
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                Text("You")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(turn.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(turn.userTranscript)
                .font(.body)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)

            // Prosody summary
            if let prosody = turn.prosodySnapshot?.prosody {
                HStack(spacing: 12) {
                    Text("Arousal: \(Int(prosody.arousal * 100))%")
                    Text("Valence: \(Int((prosody.valence + 1) * 50))%")
                    Text("Energy: \(Int(prosody.energy * 100))%")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            // Assistant response (placeholder for Phase 3)
            if let response = turn.assistantResponse {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                    Text("Assistant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                Text(response)
                    .font(.body)
                    .italic()
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    ConnectedModeView()
}
