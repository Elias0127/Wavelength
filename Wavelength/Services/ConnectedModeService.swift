import AVFoundation
import Combine
import Foundation
import Network

@MainActor
class ConnectedModeService: ObservableObject {
    
    @Published var conversationState: ConversationState = .idle
    @Published var liveCaptionState = LiveCaptionState(
        partialText: "", isFinalized: false, confidence: 1.0, wordCount: 0, speakingRate: 0.0)
    @Published var emotionStripState = EmotionStripState(
        arousal: 0.5, valence: 0.0, energy: 0.5, trend: .stable, lastUpdate: Date())
    @Published var conversationTurns: [ConversationTurn] = []
    @Published var errorMessage: String?
    @Published var connectionStatus: String = "Disconnected"

    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioSession: AVAudioSession?
    
    
    private var playbackEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    private var audioQueue = Data() 
    private var isPlayingAudio = false

    private var openaiWebSocket: URLSessionWebSocketTask?
    private let aiService = AIService.shared

    enum WebSocketState {
        case idle, connecting, open, closing, closed
    }

    private var openaiState: WebSocketState = .idle

    
    private var audioBuffer = Data()
    private var lastAudioSend = Date()
    private let audioSendInterval: TimeInterval = 0.5  

    private var silenceTimer: Timer?
    private var stabilityTimer: Timer?
    private var emotionUpdateTimer: Timer?

    private var lastPartialText = ""
    private var lastPartialUpdate = Date()
    private var turnStartTime = Date()
    private var currentTurnDuration: TimeInterval = 0

    private var cancellables = Set<AnyCancellable>()
    
    
    private var currentAIResponse = ""
    private var pendingUserTranscript = ""
    private var isAIResponding = false 

    
    private let apiBaseURL = "http:
    private let openaiSessionURL = "http:

    
    init() {
        setupAudioSession()
        setupPlaybackEngine()
        setupEmotionUpdateTimer()
    }

    deinit {
        
        
        
    }

    

    func startConversation() async {
        do {
            conversationState = .listening
            errorMessage = nil

            
            let openaiToken = try await getOpenAIToken()

            
            try await setupOpenAIConnection(token: openaiToken)

            
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

    

    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(
                .playAndRecord, 
                mode: .voiceChat, 
                options: [.allowBluetooth] 
            )
            try audioSession?.setActive(true)
            
            
            try audioSession?.overrideOutputAudioPort(.none)
            print("✅ Audio session configured for recording and earpiece playback")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }

    private func setupPlaybackEngine() {
        playbackEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        
        guard let playbackEngine = playbackEngine,
              let audioPlayerNode = audioPlayerNode else {
            print("❌ Failed to create audio playback engine")
            return
        }
        
        
        playbackEngine.attach(audioPlayerNode)
        
        
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, 
                                       sampleRate: 16000, 
                                       channels: 1, 
                                       interleaved: false)
        
        if let outputFormat = outputFormat {
            playbackEngine.connect(audioPlayerNode, to: playbackEngine.outputNode, format: outputFormat)
        }
        
        do {
            try playbackEngine.start()
            audioPlayerNode.play()
            print("✅ Audio playback engine started")
        } catch {
            print("❌ Failed to start playback engine: \(error)")
        }
    }

    private func setupEmotionUpdateTimer() {
        
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
        
        let wsURLString = "wss:
        guard let wsURL = URL(string: wsURLString) else {
            throw ConnectedModeError.websocketConnectionFailed("Invalid OpenAI WebSocket URL")
        }

        
        var request = URLRequest(url: wsURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")

        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        let session = URLSession(configuration: config)

        openaiState = .connecting
        openaiWebSocket = session.webSocketTask(with: request)
        openaiWebSocket?.resume()

        
        receiveOpenAIMessages()

        
        await sendOpenAISessionUpdate()

        
        try await Task.sleep(nanoseconds: 100_000_000)  

        print("🔗 OpenAI Realtime connection established")
        updateConnectionStatus()
    }

    private func sendOpenAISessionUpdate() async {
        let sessionUpdate: [String: Any] = [
            "type": "session.update",
            "session": [
                "modalities": ["text", "audio"],
                "instructions":
                    "You are a warm, trauma-informed counselor. Use OARS techniques. Keep responses brief and gentle. Speak with empathy and understanding. Always respond in English.",
                "voice": "verse", 
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
        audioBuffer = Data()  
        print("⏹️ Audio capture stopped")
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) async {
        
        guard !isAIResponding else {
            return
        }
        
        guard let channelData = buffer.floatChannelData?[0] else { return }

        let frameCount = Int(buffer.frameLength)
        let sampleRate = buffer.format.sampleRate

        
        var pcmData = Data()
        for i in 0..<frameCount {
            let sample = Int16(channelData[i] * Float(Int16.max))
            pcmData.append(contentsOf: withUnsafeBytes(of: sample.littleEndian) { Data($0) })
        }

        
        let resampledData = await resampleAudioFor16kHz(pcmData, originalSampleRate: sampleRate)

        
        audioBuffer.append(resampledData)

        
        let now = Date()
        if now.timeIntervalSince(lastAudioSend) >= audioSendInterval {
            await sendBatchedAudio()
            lastAudioSend = now
        }
    }

    private func sendBatchedAudio() async {
        guard !audioBuffer.isEmpty else { return }

        
        guard openaiState == .open else {
            
            audioBuffer = Data()
            return
        }

        
        let maxBufferSize = 48000  
        let currentBuffer: Data
        if audioBuffer.count > maxBufferSize {
            currentBuffer = Data(audioBuffer.prefix(maxBufferSize))
            audioBuffer = Data(audioBuffer.dropFirst(maxBufferSize))
        } else {
            currentBuffer = audioBuffer
            audioBuffer = Data()
        }

        
        if Int.random(in: 1...20) == 1 {
            print("📊 Audio buffer size: \(currentBuffer.count) bytes")
        }

        
        await sendAudioToOpenAI(currentBuffer)
    }

    private func resampleAudioFor16kHz(_ data: Data, originalSampleRate: Double) async -> Data {
        
        
        let targetSampleRate: Double = 16000
        let ratio = originalSampleRate / targetSampleRate

        
        if abs(ratio - 1.0) < 0.01 {
            return data
        }

        
        let decimationFactor = Int(ratio)
        var resampledData = Data()

        
        for i in stride(from: 0, to: data.count - 1, by: 2) {
            if i % (decimationFactor * 2) == 0 {
                
                resampledData.append(data[i])
                resampledData.append(data[i + 1])
            }
        }

        return resampledData
    }

    private func sendAudioToOpenAI(_ audioData: Data) async {
        guard openaiState == .open, let webSocket = openaiWebSocket else {
            return  
        }

        
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
                    
                    self?.receiveOpenAIMessages()
                }

            case .failure(let error):
                print("❌ OpenAI WebSocket error: \(error)")
                Task { @MainActor in
                    self?.openaiState = .closed
                    print("🔌 OpenAI connection lost - stopping audio stream")

                    
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
                        
                    }
                    
                case "conversation.item.created":
                    if let item = json["item"] as? [String: Any] {
                        print("🔄 Item created: \(item["role"] as? String ?? "unknown") - \(item["type"] as? String ?? "unknown")")
                        
                        
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
                    
                    isAIResponding = true
                    await pauseAudioInput()
                    await clearAudioBuffer()
                    
                case "response.content_part.added":
                    if let part = json["part"] as? [String: Any],
                       let transcript = part["transcript"] as? String {
                        print("🤖 AI response part: \(transcript)")
                        
                        await handleAIResponsePart(transcript)
                    }
                    
                case "input_audio_buffer.speech_started":
                    print("🎤 Speech detected")
                    
                case "input_audio_buffer.speech_stopped":
                    print("🔇 Speech ended")
                    
                    
                case "input_audio_buffer.committed":
                    print("✅ Audio buffer committed")
                    
                case "response.audio_transcript.delta":
                    if let delta = json["delta"] as? String {
                        print("🤖 AI delta: \(delta)")
                        
                        await handleAIResponsePart(delta)
                    }
                    
                case "response.audio_transcript.done":
                    if let transcript = json["transcript"] as? String {
                        print("🤖 AI final response: \(transcript)")
                        await handleFinalAIResponse(transcript)
                    }
                    
                case "response.audio.delta":
                    if let audioBase64 = json["delta"] as? String {
                        await playAudioChunk(audioBase64)
                    }
                    
                case "response.audio.done":
                    print("🔊 AI audio response completed")
                    isPlayingAudio = false
                    isAIResponding = false 
                    
                    await resumeAudioInput()
                    
                case "conversation.item.input_audio_transcription.delta":
                    if let delta = json["delta"] as? String {
                        print("📝 User speech: \(delta)")
                        
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
                    
                    if !["response.content_part.done", "response.output_item.done", "response.done", "rate_limits.updated"].contains(eventType) {
                        print("🔄 Unhandled OpenAI event: \(eventType)")
                    }
                }
            }

        case .data(_):
            
            print("📦 Received audio data from OpenAI")

        @unknown default:
            break
        }
    }

    private func analyzeTranscriptWithLocalAI(_ transcript: String) async {
        
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        
        let sentimentAnalysis = aiService.analyzeSentiment(transcript)

        
        await updateEmotionDataFromLocalAI(
            arousal: sentimentAnalysis.sentimentScore,  
            valence: sentimentAnalysis.valenceSeries.first ?? 0.5,  
            energy: sentimentAnalysis.sentimentScore  
        )
    }

    private func updateEmotionDataFromLocalAI(arousal: Double, valence: Double, energy: Double)
        async
    {
        
        emotionStripState = EmotionStripState(
            arousal: max(0.0, min(1.0, arousal)),
            valence: max(-1.0, min(1.0, (valence - 0.5) * 2)),  
            energy: max(0.0, min(1.0, energy)),
            trend: calculateTrend(arousal: arousal, valence: valence, energy: energy),
            lastUpdate: Date()
        )
    }

    private func calculateTrend(arousal: Double, valence: Double, energy: Double) -> EmotionTrend {
        
        return .stable
    }

    private func updateLiveCaption(_ text: String, isFinal: Bool) async {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            .count
        let speakingRate = calculateSpeakingRate(wordCount: wordCount)

        liveCaptionState = LiveCaptionState(
            partialText: text,
            isFinalized: isFinal,
            confidence: 0.9,  
            wordCount: wordCount,
            speakingRate: speakingRate
        )

        
        if !isFinal {
            lastPartialText = text
            lastPartialUpdate = Date()
            resetTurnTimers()
        }
    }

    private func updateEmotionStrip() {
        
        
    }

    private func calculateSpeakingRate(wordCount: Int) -> Double {
        let duration = Date().timeIntervalSince(turnStartTime)
        return duration > 0 ? Double(wordCount) / (duration / 60.0) : 0.0
    }

    private func resetTurnTimers() {
        silenceTimer?.invalidate()
        stabilityTimer?.invalidate()

        
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
            
            await finalizeTurn(lastPartialText)
        }
    }

    private func finalizeTurn(_ transcript: String) async {
        
        
        conversationState = .analyzing
        
        
        pendingUserTranscript = transcript
        
        
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
        
        
        conversationState = .listening
        
        
        turnStartTime = Date()
        currentTurnDuration = 0
        lastPartialText = ""
    }

    private func handleAIResponsePart(_ transcript: String) async {
        
        currentAIResponse += transcript
    }
    
    private func triggerAIResponse() async {
        
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

    private func pauseAudioInput() async {
        
        inputNode?.removeTap(onBus: 0)
        print("⏸️ Audio input paused during AI response")
    }
    
    private func clearAudioBuffer() async {
        
        guard openaiState == .open, let webSocket = openaiWebSocket else {
            return
        }
        
        let clearEvent: [String: Any] = [
            "type": "input_audio_buffer.clear"
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: clearEvent)
            let message = URLSessionWebSocketTask.Message.string(
                String(data: jsonData, encoding: .utf8) ?? "")
            
            webSocket.send(message) { error in
                if let error = error {
                    print("❌ Failed to clear audio buffer: \(error)")
                } else {
                    print("🧹 Audio buffer cleared")
                }
            }
        } catch {
            print("❌ Failed to encode clear buffer event: \(error)")
        }
        
        
        audioBuffer = Data()
    }
    
    private func resumeAudioInput() async {
        
        guard let inputNode = inputNode else { return }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            [weak self] buffer, _ in
            Task {
                await self?.processAudioBuffer(buffer)
            }
        }
        print("▶️ Audio input resumed")
    }

    private func playAudioChunk(_ audioBase64: String) async {
        guard let audioData = Data(base64Encoded: audioBase64),
              let audioPlayerNode = audioPlayerNode else {
            return
        }
        
        
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, 
                                 sampleRate: 16000, 
                                 channels: 1, 
                                 interleaved: false)
        
        guard let audioFormat = format else { return }
        
        let frameCount = audioData.count / 2 
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCount)) else {
            return
        }
        
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        
        audioData.withUnsafeBytes { bytes in
            let int16Buffer = bytes.bindMemory(to: Int16.self)
            let floatChannelData = buffer.floatChannelData?[0]
            
            for i in 0..<frameCount {
                
                let sample = Float(int16Buffer[i]) / Float(Int16.max)
                floatChannelData?[i] = sample
            }
        }
        
        
        if !isPlayingAudio {
            isPlayingAudio = true
            print("🔊 Starting AI audio playback")
        }
        
        
        audioPlayerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    private func handleFinalAIResponse(_ transcript: String) async {
        
        let finalResponse = transcript.isEmpty ? currentAIResponse : transcript
        
        
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
        
        silenceTimer?.invalidate()
        stabilityTimer?.invalidate()
        emotionUpdateTimer?.invalidate()

        
        openaiWebSocket?.cancel(with: .normalClosure, reason: nil)

        
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        
        
        audioPlayerNode?.stop()
        playbackEngine?.stop()

        
        openaiWebSocket = nil
        audioEngine = nil
        inputNode = nil
        audioPlayerNode = nil
        playbackEngine = nil

        
        openaiState = .idle

        
        audioBuffer = Data()
        
        
        currentAIResponse = ""
        pendingUserTranscript = ""
        isAIResponding = false
    }
}
