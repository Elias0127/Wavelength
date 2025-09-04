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
    private var humeWebSocket: URLSessionWebSocketTask?

    enum WebSocketState {
        case idle, connecting, open, closing, closed
    }

    private var openaiState: WebSocketState = .idle
    private var humeState: WebSocketState = .idle

    // Audio batching
    private var audioBuffer = Data()
    private var lastAudioSend = Date()
    private let audioSendInterval: TimeInterval = 0.5  // Send every 500ms to prevent buffer overflow

    private var silenceTimer: Timer?
    private var stabilityTimer: Timer?
    private var emotionUpdateTimer: Timer?
    private var humePingTimer: Timer?
    private var humeReconnectTimer: Timer?

    private var lastPartialText = ""
    private var lastPartialUpdate = Date()
    private var turnStartTime = Date()
    private var currentTurnDuration: TimeInterval = 0

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Configuration
    private let apiBaseURL = "http://10.0.0.188:3000"
    private let openaiSessionURL = "http://10.0.0.188:3000/api/openai/realtime/session"
    private let humeTokenURL = "http://10.0.0.188:3000/api/hume/token"

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

            // Get tokens from backend
            let openaiToken = try await getOpenAIToken()
            let humeToken = try await getHumeToken()

            // Initialize connections
            try await setupOpenAIConnection(token: openaiToken)
            try await setupHumeConnection(token: humeToken.token)

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

    private func startHumePing() {
        // Send ping every 30 seconds to keep connection alive
        humePingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) {
            [weak self] _ in
            guard let self = self, self.humeState == .open else { return }

            self.humeWebSocket?.sendPing { error in
                if let error = error {
                    print("❌ Hume ping failed: \(error)")
                    Task { @MainActor in
                        self.humeState = .closed
                        self.scheduleHumeReconnect()
                    }
                }
            }
        }
    }

    private func scheduleHumeReconnect() {
        // Cancel any existing reconnect timer
        humeReconnectTimer?.invalidate()

        // Schedule reconnection after 2 seconds
        humeReconnectTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) {
            [weak self] _ in
            Task { @MainActor in
                await self?.attemptHumeReconnect()
            }
        }
    }

    private func attemptHumeReconnect() async {
        guard humeState == .closed else { return }

        print("🔄 Attempting to reconnect Hume...")

        do {
            // Get a fresh token
            let humeToken = try await getHumeToken()

            // Try to reconnect
            try await setupHumeConnection(token: humeToken.token)

            print("✅ Hume reconnected successfully")
            updateConnectionStatus()
        } catch {
            print("❌ Hume reconnection failed: \(error)")
            // Schedule another attempt in 5 seconds
            humeReconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) {
                [weak self] _ in
                Task { @MainActor in
                    await self?.attemptHumeReconnect()
                }
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

    private func getHumeToken() async throws -> HumeTokenResponse {
        let url = URL(string: humeTokenURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw ConnectedModeError.networkError("Failed to get Hume token")
        }

        return try JSONDecoder().decode(HumeTokenResponse.self, from: data)
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

    private func setupHumeConnection(token: String) async throws {
        // Create WebSocket URL for Hume Expression Measurement API
        let wsURLString = "wss://api.hume.ai/v0/stream/models"
        guard let wsURL = URL(string: wsURLString) else {
            throw ConnectedModeError.websocketConnectionFailed("Invalid Hume WebSocket URL")
        }

        print("🔑 Setting up Hume connection with token: \(String(token.prefix(10)))...")

        // Create WebSocket task with proper header authentication
        var request = URLRequest(url: wsURL)
        request.setValue(token, forHTTPHeaderField: "X-Hume-Api-Key")

        // Configure URLSession for better WebSocket handling
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        let session = URLSession(configuration: config)

        humeState = .connecting
        humeWebSocket = session.webSocketTask(with: request)
        humeWebSocket?.resume()

        // Start receiving prosody data
        receiveHumeMessages()

        // Wait for connection to be established with timeout
        let connectionTimeout: TimeInterval = 3.0
        let startTime = Date()

        while humeState == .connecting && Date().timeIntervalSince(startTime) < connectionTimeout {
            // Check WebSocket state
            if let webSocket = humeWebSocket {
                print("🔍 Hume WebSocket state: \(webSocket.state.rawValue)")
                if webSocket.state == .running {
                    humeState = .open
                    print("✅ Hume WebSocket connection established")
                    break
                }
            }
            try await Task.sleep(nanoseconds: 100_000_000)  // 100ms
        }

        if humeState == .connecting {
            humeState = .closed
            throw ConnectedModeError.websocketConnectionFailed("Hume connection timeout")
        }

        // Start keep-alive ping only if connection is open
        if humeState == .open {
            startHumePing()
            // Send initial configuration message
            await sendHumeInitialConfig()
        }

        print("🎭 Hume connection established")
        updateConnectionStatus()
    }

    private func sendHumeInitialConfig() async {
        guard let webSocket = humeWebSocket else { return }

        let configMessage: [String: Any] = [
            "models": ["prosody"],
            "stream_window_ms": 1500,
            "raw_text": false,
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: configMessage)
            let message = URLSessionWebSocketTask.Message.string(
                String(data: jsonData, encoding: .utf8) ?? "")

            webSocket.send(message) { error in
                if let error = error {
                    print("❌ Failed to send Hume initial config: \(error)")
                } else {
                    print("✅ Hume initial configuration sent")
                }
            }
        } catch {
            print("❌ Failed to encode Hume initial config: \(error)")
        }
    }

    private func sendOpenAISessionUpdate() async {
        let sessionUpdate: [String: Any] = [
            "type": "session.update",
            "session": [
                "modalities": ["text", "audio"],
                "instructions":
                    "You are a warm, trauma-informed counselor. Use OARS techniques. Keep responses brief and gentle.",
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
                "temperature": 0.8,
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

        // Check if both connections are still open before sending
        guard humeState == .open || openaiState == .open else {
            // Clear buffer if no connections are open
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
        if Int.random(in: 1...10) == 1 {
            print("📊 Audio buffer size: \(currentBuffer.count) bytes")
        }

        // Send to both services (individual guards will handle per-service state)
        await sendAudioToHume(currentBuffer)
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

    private func sendAudioToHume(_ audioData: Data) async {
        guard humeState == .open, let webSocket = humeWebSocket else {
            // Only log occasionally to avoid spam
            if Int.random(in: 1...20) == 1 {
                print("⚠️ Skipping Hume audio send - connection not ready (state: \(humeState))")
            }
            return  // Skip sending if not open
        }

        // Check if WebSocket is actually ready
        guard webSocket.state == .running else {
            print("⚠️ Hume WebSocket not in running state: \(webSocket.state)")
            humeState = .closed
            return
        }

        // Only log audio sends occasionally to avoid spam
        if Int.random(in: 1...5) == 1 {
            print("🎵 Sending audio to Hume (\(audioData.count) bytes)")
        }

        // Create proper Expression Measurement API format
        let base64Audio = audioData.base64EncodedString()
        let audioEvent: [String: Any] = [
            "models": ["prosody"],
            "stream_window_ms": 1500,
            "raw_text": false,
            "data": base64Audio,
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: audioEvent)
            let message = URLSessionWebSocketTask.Message.string(
                String(data: jsonData, encoding: .utf8) ?? "")

            webSocket.send(message) { error in
                if let error = error {
                    print("❌ Failed to send audio to Hume: \(error)")
                }
            }
        } catch {
            print("❌ Failed to encode audio event for Hume: \(error)")
        }
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

                    // Stop audio capture immediately if all connections are lost
                    if self?.humeState != .open {
                        self?.stopAudioCapture()
                    }

                    await self?.handleError(error)
                }
            }
        }
    }

    private func receiveHumeMessages() {
        humeWebSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                Task { @MainActor in
                    // Set state to open on first successful message
                    if self?.humeState == .connecting {
                        self?.humeState = .open
                        print("✅ Hume WebSocket connection confirmed")
                    }
                    await self?.handleHumeMessage(message)
                    // Continue receiving
                    self?.receiveHumeMessages()
                }

            case .failure(let error):
                print("❌ Hume WebSocket error: \(error)")

                // Log close code if available
                if let wsError = error as? URLError {
                    print(
                        "🔍 Hume close details - Code: \(wsError.code.rawValue), LocalizedDescription: \(wsError.localizedDescription)"
                    )
                }

                Task { @MainActor in
                    self?.humeState = .closed
                    self?.updateConnectionStatus()
                    print("🔌 Hume connection lost - attempting reconnection")

                    // Try to reconnect Hume after a short delay
                    self?.scheduleHumeReconnect()

                    // Only stop audio if both connections are lost
                    if self?.openaiState != .open {
                        self?.stopAudioCapture()
                    }
                }
            }
        }
    }

    private func handleOpenAIMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            {

                if let transcript = json["transcript"] as? String {
                    await updateLiveCaption(transcript, isFinal: false)
                }

                if let finalTranscript = json["final_transcript"] as? String {
                    await finalizeTurn(finalTranscript)
                }
            }

        case .data(_):
            // Handle binary data (audio responses)
            print("📦 Received audio data from OpenAI")

        @unknown default:
            break
        }
    }

    private func handleHumeMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            {
                // Handle Expression Measurement API response format
                if let predictions = json["predictions"] as? [[String: Any]],
                    let firstPrediction = predictions.first,
                    let prosody = firstPrediction["prosody"] as? [String: Any]
                {
                    await updateProsodyData(prosody)
                }
                // Fallback for direct prosody format
                else if let prosody = json["prosody"] as? [String: Any] {
                    await updateProsodyData(prosody)
                }
            }

        case .data(_):
            break

        @unknown default:
            break
        }
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

    private func updateProsodyData(_ prosody: [String: Any]) async {
        let arousal = prosody["arousal"] as? Double ?? 0.5
        let valence = prosody["valence"] as? Double ?? 0.0
        let energy = prosody["energy"] as? Double ?? 0.5
        let events = prosody["events"] as? [String] ?? []

        let newProsody = ProsodyData(
            arousal: arousal, valence: valence, energy: energy, events: events)

        // Update emotion strip state
        emotionStripState = EmotionStripState(
            arousal: newProsody.arousal,
            valence: newProsody.valence,
            energy: newProsody.energy,
            trend: calculateTrend(newProsody),
            lastUpdate: Date()
        )
    }

    private func updateEmotionStrip() {
        // Smooth updates to avoid flicker
        // This runs at 4 Hz from the timer
    }

    private func calculateTrend(_ prosody: ProsodyData) -> EmotionTrend {
        // Simple trend calculation based on recent values
        // TODO: Implement proper trend analysis
        return .stable
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
        conversationState = .analyzing

        // Create prosody snapshot
        let prosodySnapshot = ProsodySnapshot(
            transcript: transcript,
            prosody: ProsodyData(
                arousal: emotionStripState.arousal,
                valence: emotionStripState.valence,
                energy: emotionStripState.energy,
                events: []
            )
        )

        // Create conversation turn
        let turn = ConversationTurn(
            userTranscript: transcript,
            prosodySnapshot: prosodySnapshot,
            duration: currentTurnDuration
        )

        conversationTurns.append(turn)

        // Update UI
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

        // TODO: Trigger AI response (Phase 3)
        conversationState = .listening

        // Reset for next turn
        turnStartTime = Date()
        currentTurnDuration = 0
        lastPartialText = ""
    }

    private func updateConnectionStatus() {
        let openaiStatus = openaiState == .open ? "OpenAI ✅" : "OpenAI ❌"
        let humeStatus = humeState == .open ? "Hume ✅" : "Hume ❌"
        connectionStatus = "\(openaiStatus) | \(humeStatus)"
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
        humePingTimer?.invalidate()
        humeReconnectTimer?.invalidate()

        // Close WebSocket connections
        openaiWebSocket?.cancel(with: .normalClosure, reason: nil)
        humeWebSocket?.cancel(with: .normalClosure, reason: nil)

        // Stop audio capture
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()

        // Reset state
        openaiWebSocket = nil
        humeWebSocket = nil
        audioEngine = nil
        inputNode = nil

        // Reset connection states
        openaiState = .idle
        humeState = .idle

        // Clear audio buffer
        audioBuffer = Data()
    }
}
