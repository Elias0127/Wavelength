import AVFoundation
import Combine
import Foundation
import Network

@MainActor
class ConnectedModeService: ObservableObject {
    // MARK: - Published Properties
    @Published var conversationState: ConversationState = .idle
    @Published var liveCaptionState = LiveCaptionState(
        partialText: "", isFinalized: false, confidence: 1.0, wordCount: 0, speakingRate: 0.0)
    @Published var emotionStripState = EmotionStripState(
        arousal: 0.5, valence: 0.0, energy: 0.5, trend: .stable, lastUpdate: Date())
    @Published var conversationTurns: [ConversationTurn] = []
    @Published var errorMessage: String?
    @Published var connectionStatus: String = "Disconnected"

    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioSession: AVAudioSession?

    private var openaiWebSocket: URLSessionWebSocketTask?
    private let aiService = AIService.shared

    enum WebSocketState {
        case idle, connecting, open, closing, closed
    }

    private var openaiState: WebSocketState = .idle

    // Audio batching
    private var audioBuffer = Data()
    private var lastAudioSend = Date()
    private let audioSendInterval: TimeInterval = 0.5  // Send every 500ms to prevent buffer overflow

    private var silenceTimer: Timer?
    private var stabilityTimer: Timer?
    private var emotionUpdateTimer: Timer?

    private var lastPartialText = ""
    private var lastPartialUpdate = Date()
    private var turnStartTime = Date()
    private var currentTurnDuration: TimeInterval = 0

    private var cancellables = Set<AnyCancellable>()
    
    // AI response tracking
    private var currentAIResponse = ""
    private var pendingUserTranscript = ""

    // MARK: - Configuration
    private let apiBaseURL = "http://10.0.0.188:3000"
    private let openaiSessionURL = "http://10.0.0.188:3000/api/openai/realtime/session"

    // MARK: - Initialization
    init() {
        setupAudioSession()
        setupEmotionUpdateTimer()
    }

    deinit {
        // Note: cleanup() is main actor isolated, but deinit can't be async
        // In a real app, we'd handle this differently, but for now we'll let it be
        // The cleanup will happen when the object is deallocated
    }

    // MARK: - Public Methods

    func startConversation() async {
        do {
            conversationState = .listening
            errorMessage = nil

            // Get OpenAI token from backend
            let openaiToken = try await getOpenAIToken()

            // Initialize OpenAI connection
            try await setupOpenAIConnection(token: openaiToken)

            // Start audio capture
            try startAudioCapture()

            print("✅ Connected Mode conversation started")

        } catch {
            await handleError(error)
        }
    }

    func stopConversation() {
        Task { @MainActor in
            cleanup()
            conversationState = .idle
            print("🛑 Connected Mode conversation stopped")
        }
    }

    func killSwitch() {
        Task { @MainActor in
            // Immediate stop - clear all buffers and connections
            cleanup()
            conversationState = .idle
            liveCaptionState = LiveCaptionState(
                partialText: "", isFinalized: false, confidence: 1.0, wordCount: 0,
                speakingRate: 0.0)
            emotionStripState = EmotionStripState(
                arousal: 0.5, valence: 0.0, energy: 0.5, trend: .stable, lastUpdate: Date())
            errorMessage = nil
            print("🚨 Kill switch activated - all connections cleared")
        }
    }

    // MARK: - Private Methods

    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(
                .playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession?.setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }

    private func setupEmotionUpdateTimer() {
        // Update emotion strip at ~4 Hz to avoid flicker
        emotionUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) {
            [weak self] _ in
            Task { @MainActor in
                self?.updateEmotionStrip()
            }
        }
    }

    private func getOpenAIToken() async throws -> String {
        let url = URL(string: openaiSessionURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "model": "gpt-realtime",
            "voice": "verse",
            "instructions":
                "You are a warm, trauma-informed counselor. Use OARS. Brief turns, gentle tone.",
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw ConnectedModeError.networkError("Failed to get OpenAI token")
        }

        let sessionResponse = try JSONDecoder().decode(OpenAISessionResponse.self, from: data)
        return sessionResponse.token
    }

    private func setupOpenAIConnection(token: String) async throws {
        // Create WebSocket URL for OpenAI Realtime API
        let wsURLString = "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview"
        guard let wsURL = URL(string: wsURLString) else {
            throw ConnectedModeError.websocketConnectionFailed("Invalid OpenAI WebSocket URL")
        }

        // Create WebSocket task with Bearer token authentication
        var request = URLRequest(url: wsURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")

        // Configure URLSession for better WebSocket handling
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        let session = URLSession(configuration: config)

        openaiState = .connecting
        openaiWebSocket = session.webSocketTask(with: request)
        openaiWebSocket?.resume()

        // Start receiving messages
        receiveOpenAIMessages()

        // Send initial session configuration
        await sendOpenAISessionUpdate()

        // Add small delay to ensure session is configured
        try await Task.sleep(nanoseconds: 100_000_000)  // 100ms

        print("🔗 OpenAI Realtime connection established")
        updateConnectionStatus()
    }

    private func sendOpenAISessionUpdate() async {
        let sessionUpdate: [String: Any] = [
            "type": "session.update",
            "session": [
                "modalities": ["text", "audio"],
                "instructions":
                    "You are a warm, trauma-informed counselor. Use OARS techniques. Keep responses brief and gentle. Always respond in English.",
                "voice": "alloy",
                "input_audio_format": "pcm16",
                "output_audio_format": "pcm16",
                "input_audio_transcription": [
                    "model": "whisper-1"
                ],
                "turn_detection": [
                    "type": "server_vad",
                    "threshold": 0.5,
                    "prefix_padding_ms": 300,
                    "silence_duration_ms": 200,
                ],
            ],
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: sessionUpdate)
            let message = URLSessionWebSocketTask.Message.string(
                String(data: jsonData, encoding: .utf8) ?? "")

            openaiWebSocket?.send(message) { error in
                if let error = error {
                    print("❌ Failed to send session update to OpenAI: \(error)")
                } else {
                    print("✅ OpenAI session configured")
                }
            }
        } catch {
            print("❌ Failed to encode session update: \(error)")
        }
    }

    private func startAudioCapture() throws {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode

        guard let inputNode = inputNode else {
            throw ConnectedModeError.audioCaptureFailed("Input node not available")
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            [weak self] buffer, _ in
            Task {
                await self?.processAudioBuffer(buffer)
            }
        }

        audioEngine?.prepare()
        try audioEngine?.start()

        print("🎤 Audio capture started")
    }

    private func stopAudioCapture() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioBuffer = Data()  // Clear any pending audio
        print("⏹️ Audio capture stopped")
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) async {
        guard let channelData = buffer.floatChannelData?[0] else { return }

        let frameCount = Int(buffer.frameLength)
        let sampleRate = buffer.format.sampleRate

        // Convert to 16-bit PCM data
        var pcmData = Data()
        for i in 0..<frameCount {
            let sample = Int16(channelData[i] * Float(Int16.max))
            pcmData.append(contentsOf: withUnsafeBytes(of: sample.littleEndian) { Data($0) })
        }

        // Resample to 16kHz if needed
        let resampledData = await resampleAudioFor16kHz(pcmData, originalSampleRate: sampleRate)

        // Accumulate audio data in buffer
        audioBuffer.append(resampledData)

        // Send batched audio if enough time has passed
        let now = Date()
        if now.timeIntervalSince(lastAudioSend) >= audioSendInterval {
            await sendBatchedAudio()
            lastAudioSend = now
        }
    }

    private func sendBatchedAudio() async {
        guard !audioBuffer.isEmpty else { return }

        // Check if OpenAI connection is open before sending
        guard openaiState == .open else {
            // Clear buffer if connection is not open
            audioBuffer = Data()
            return
        }

        // Limit buffer size to prevent overwhelming WebSocket
        let maxBufferSize = 48000  // ~3 seconds at 16kHz (48KB max)
        let currentBuffer: Data
        if audioBuffer.count > maxBufferSize {
            currentBuffer = Data(audioBuffer.prefix(maxBufferSize))
            audioBuffer = Data(audioBuffer.dropFirst(maxBufferSize))
        } else {
            currentBuffer = audioBuffer
            audioBuffer = Data()
        }

        // Only log buffer size occasionally to avoid spam
        if Int.random(in: 1...20) == 1 {
            print("📊 Audio buffer size: \(currentBuffer.count) bytes")
        }

        // Send to OpenAI only
        await sendAudioToOpenAI(currentBuffer)
    }

    private func resampleAudioFor16kHz(_ data: Data, originalSampleRate: Double) async -> Data {
        // Simple downsampling for 16kHz target
        // Most systems record at 44.1kHz or 48kHz, so we need to downsample
        let targetSampleRate: Double = 16000
        let ratio = originalSampleRate / targetSampleRate

        // If already at target rate, return as-is
        if abs(ratio - 1.0) < 0.01 {
            return data
        }

        // Simple decimation - take every nth sample
        let decimationFactor = Int(ratio)
        var resampledData = Data()

        // Process 16-bit samples (2 bytes each)
        for i in stride(from: 0, to: data.count - 1, by: 2) {
            if i % (decimationFactor * 2) == 0 {
                // Take this sample
                resampledData.append(data[i])
                resampledData.append(data[i + 1])
            }
        }

        return resampledData
    }

    private func sendAudioToOpenAI(_ audioData: Data) async {
        guard openaiState == .open, let webSocket = openaiWebSocket else {
            return  // Skip sending if not open
        }

        // Create input_audio_buffer.append event with base64-encoded audio
        let base64Audio = audioData.base64EncodedString()
        let audioEvent: [String: Any] = [
            "type": "input_audio_buffer.append",
            "audio": base64Audio,
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: audioEvent)
            let message = URLSessionWebSocketTask.Message.string(
                String(data: jsonData, encoding: .utf8) ?? "")

            webSocket.send(message) { error in
                if let error = error {
                    print("❌ Failed to send audio to OpenAI: \(error)")
                }
            }
        } catch {
            print("❌ Failed to encode audio event for OpenAI: \(error)")
        }
    }

    private func receiveOpenAIMessages() {
        openaiWebSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                Task { @MainActor in
                    self?.openaiState = .open
                    await self?.handleOpenAIMessage(message)
                    // Continue receiving
                    self?.receiveOpenAIMessages()
                }

            case .failure(let error):
                print("❌ OpenAI WebSocket error: \(error)")
                Task { @MainActor in
                    self?.openaiState = .closed
                    print("🔌 OpenAI connection lost - stopping audio stream")

                    // Stop audio capture when connection is lost
                    self?.stopAudioCapture()

                    await self?.handleError(error)
                }
            }
        }
    }

    private func handleOpenAIMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let eventType = json["type"] as? String
            {
                print("🔄 OpenAI Event: \(eventType)")
                
                switch eventType {
                case "conversation.item.input_audio_transcription.completed":
                    if let transcript = json["transcript"] as? String {
                        print("📝 User transcript: \(transcript)")
                        pendingUserTranscript = transcript
                        await updateLiveCaption(transcript, isFinal: true)
                        await analyzeTranscriptWithLocalAI(transcript)
                        // Don't finalize turn here - wait for AI response
                    }
                    
                case "conversation.item.created":
                    if let item = json["item"] as? [String: Any] {
                        print("🔄 Item created: \(item["role"] as? String ?? "unknown") - \(item["type"] as? String ?? "unknown")")
                        
                        // Handle user message items
                        if let role = item["role"] as? String, role == "user",
                           let content = item["content"] as? [[String: Any]] {
                            for contentItem in content {
                                if let transcript = contentItem["transcript"] as? String, !transcript.isEmpty {
                                    print("📝 User transcript found: \(transcript)")
                                    pendingUserTranscript = transcript
                                    await updateLiveCaption(transcript, isFinal: true)
                                    await analyzeTranscriptWithLocalAI(transcript)
                                }
                            }
                        }
                    }
                    
                case "response.created", "response.output_item.added":
                    print("🤖 AI response started")
                    
                case "response.content_part.added":
                    if let part = json["part"] as? [String: Any],
                       let transcript = part["transcript"] as? String {
                        print("🤖 AI response part: \(transcript)")
                        // Store for conversation turn
                        await handleAIResponsePart(transcript)
                    }
                    
                case "input_audio_buffer.speech_started":
                    print("🎤 Speech detected")
                    
                case "input_audio_buffer.speech_stopped":
                    print("🔇 Speech ended")
                    // Don't trigger response - OpenAI handles this automatically with server_vad
                    
                case "input_audio_buffer.committed":
                    print("✅ Audio buffer committed")
                    
                case "response.audio_transcript.delta":
                    if let delta = json["delta"] as? String {
                        print("🤖 AI delta: \(delta)")
                        // Accumulate the delta response
                        await handleAIResponsePart(delta)
                    }
                    
                case "response.audio_transcript.done":
                    if let transcript = json["transcript"] as? String {
                        print("🤖 AI final response: \(transcript)")
                        await handleFinalAIResponse(transcript)
                    }
                    
                case "response.audio.delta", "response.audio.done":
                    // Audio data - no need to log
                    break
                    
                case "conversation.item.input_audio_transcription.delta":
                    if let delta = json["delta"] as? String {
                        print("📝 User speech: \(delta)")
                        // Update live caption with partial transcript
                        await updateLiveCaption(delta, isFinal: false)
                    }
                    
                case "session.created", "session.updated":
                    print("✅ OpenAI session configured")
                    
                case "error":
                    if let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        print("❌ OpenAI error: \(message)")
                        await handleError(ConnectedModeError.openAIError(message))
                    }
                    
                default:
                    // Only log unhandled events that might be important
                    if !["response.content_part.done", "response.output_item.done", "response.done", "rate_limits.updated"].contains(eventType) {
                        print("🔄 Unhandled OpenAI event: \(eventType)")
                    }
                }
            }

        case .data(_):
            // Handle binary data (audio responses)
            print("📦 Received audio data from OpenAI")

        @unknown default:
            break
        }
    }

    private func analyzeTranscriptWithLocalAI(_ transcript: String) async {
        // Only analyze non-empty transcripts
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Use AIService to analyze emotion
        let sentimentAnalysis = aiService.analyzeSentiment(transcript)

        // Map AIService results to EmotionStripState
        await updateEmotionDataFromLocalAI(
            arousal: sentimentAnalysis.sentimentScore,  // Use sentiment as arousal proxy
            valence: sentimentAnalysis.valenceSeries.first ?? 0.5,  // Use first valence value
            energy: sentimentAnalysis.sentimentScore  // Use sentiment as energy proxy
        )
    }

    private func updateEmotionDataFromLocalAI(arousal: Double, valence: Double, energy: Double)
        async
    {
        // Update emotion strip state with local AI analysis
        emotionStripState = EmotionStripState(
            arousal: max(0.0, min(1.0, arousal)),
            valence: max(-1.0, min(1.0, (valence - 0.5) * 2)),  // Convert 0-1 to -1 to 1
            energy: max(0.0, min(1.0, energy)),
            trend: calculateTrend(arousal: arousal, valence: valence, energy: energy),
            lastUpdate: Date()
        )
    }

    private func calculateTrend(arousal: Double, valence: Double, energy: Double) -> EmotionTrend {
        // Simple trend calculation - could be enhanced with historical data
        return .stable
    }

    private func updateLiveCaption(_ text: String, isFinal: Bool) async {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            .count
        let speakingRate = calculateSpeakingRate(wordCount: wordCount)

        liveCaptionState = LiveCaptionState(
            partialText: text,
            isFinalized: isFinal,
            confidence: 0.9,  // TODO: Get from OpenAI
            wordCount: wordCount,
            speakingRate: speakingRate
        )

        // Check for turn boundaries
        if !isFinal {
            lastPartialText = text
            lastPartialUpdate = Date()
            resetTurnTimers()
        }
    }

    private func updateEmotionStrip() {
        // Smooth updates to avoid flicker
        // This runs at 4 Hz from the timer
    }

    private func calculateSpeakingRate(wordCount: Int) -> Double {
        let duration = Date().timeIntervalSince(turnStartTime)
        return duration > 0 ? Double(wordCount) / (duration / 60.0) : 0.0
    }

    private func resetTurnTimers() {
        silenceTimer?.invalidate()
        stabilityTimer?.invalidate()

        // Start silence detection timer
        silenceTimer = Timer.scheduledTimer(
            withTimeInterval: AudioConfig.silenceThreshold, repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.checkTurnBoundary()
            }
        }
    }

    private func checkTurnBoundary() async {
        let timeSinceLastUpdate = Date().timeIntervalSince(lastPartialUpdate)

        if timeSinceLastUpdate >= AudioConfig.stabilityThreshold {
            // Turn has ended - finalize
            await finalizeTurn(lastPartialText)
        }
    }

    private func finalizeTurn(_ transcript: String) async {
        // This method is now only used for manual finalization
        // The actual conversation turn creation happens in handleFinalAIResponse
        conversationState = .analyzing
        
        // Store transcript for when AI responds
        pendingUserTranscript = transcript
        
        // Update UI with finalized transcript
        liveCaptionState = LiveCaptionState(
            partialText: transcript,
            isFinalized: true,
            confidence: 1.0,
            wordCount: transcript.components(separatedBy: .whitespacesAndNewlines).filter {
                !$0.isEmpty
            }.count,
            speakingRate: calculateSpeakingRate(
                wordCount: transcript.components(separatedBy: .whitespacesAndNewlines).filter {
                    !$0.isEmpty
                }.count)
        )
        
        // Wait for AI response - don't create conversation turn yet
        conversationState = .listening
        
        // Reset turn timing
        turnStartTime = Date()
        currentTurnDuration = 0
        lastPartialText = ""
    }

    private func handleAIResponsePart(_ transcript: String) async {
        // Accumulate AI response parts
        currentAIResponse += transcript
    }
    
    private func triggerAIResponse() async {
        // Send response.create event to trigger AI response
        guard openaiState == .open, let webSocket = openaiWebSocket else {
            return
        }
        
        let responseEvent: [String: Any] = [
            "type": "response.create",
            "response": [
                "modalities": ["text", "audio"],
                "instructions": "Respond as a warm, trauma-informed counselor using OARS techniques. Keep responses brief and gentle."
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: responseEvent)
            let message = URLSessionWebSocketTask.Message.string(
                String(data: jsonData, encoding: .utf8) ?? "")
            
            webSocket.send(message) { error in
                if let error = error {
                    print("❌ Failed to trigger AI response: \(error)")
                } else {
                    print("🤖 AI response triggered")
                }
            }
        } catch {
            print("❌ Failed to encode response event: \(error)")
        }
    }

    private func handleFinalAIResponse(_ transcript: String) async {
        // Use the final transcript or accumulated response
        let finalResponse = transcript.isEmpty ? currentAIResponse : transcript
        
        // Create conversation turn with the actual AI response
        if !pendingUserTranscript.isEmpty {
            let sentimentAnalysis = aiService.analyzeSentiment(pendingUserTranscript)
            
            let prosodySnapshot = ProsodySnapshot(
                transcript: pendingUserTranscript,
                prosody: ProsodyData(
                    arousal: sentimentAnalysis.sentimentScore,
                    valence: sentimentAnalysis.valenceSeries.first ?? 0.5,
                    energy: sentimentAnalysis.sentimentScore,
                    events: []
                )
            )
            
            let turn = ConversationTurn(
                userTranscript: pendingUserTranscript,
                prosodySnapshot: prosodySnapshot,
                assistantResponse: finalResponse,
                duration: currentTurnDuration
            )
            
            print("🎯 Displaying conversation turn:")
            print("   User: \(pendingUserTranscript)")
            print("   AI: \(finalResponse)")
            
            conversationTurns.append(turn)
            
            // Reset for next turn
            currentAIResponse = ""
            pendingUserTranscript = ""
            turnStartTime = Date()
            currentTurnDuration = 0
        }
        
        conversationState = .listening
    }

    private func updateConnectionStatus() {
        let openaiStatus = openaiState == .open ? "OpenAI ✅" : "OpenAI ❌"
        connectionStatus = "\(openaiStatus) | Local AI ✅"
    }

    private func handleError(_ error: Error) async {
        conversationState = .error(error.localizedDescription)
        errorMessage = error.localizedDescription
        updateConnectionStatus()
        print("❌ Connected Mode error: \(error)")
    }

    private func cleanup() {
        // Stop timers
        silenceTimer?.invalidate()
        stabilityTimer?.invalidate()
        emotionUpdateTimer?.invalidate()

        // Close WebSocket connections
        openaiWebSocket?.cancel(with: .normalClosure, reason: nil)

        // Stop audio capture
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()

        // Reset state
        openaiWebSocket = nil
        audioEngine = nil
        inputNode = nil

        // Reset connection states
        openaiState = .idle

        // Clear audio buffer
        audioBuffer = Data()
        
        // Reset AI response tracking
        currentAIResponse = ""
        pendingUserTranscript = ""
    }
}
