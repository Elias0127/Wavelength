import AVFoundation
import Combine
import Foundation

@MainActor
class AudioRecordingService: NSObject, ObservableObject {
    static let shared = AudioRecordingService()

    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0.0
    @Published var error: AudioRecordingError?
    @Published var isAuthorized = false

    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?

    override init() {
        super.init()
        requestMicrophonePermission()
    }

    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if !granted {
                    self?.error = .permissionDenied
                    print("Microphone permission denied")
                } else {
                    print("Microphone permission granted")
                }
            }
        }
    }

    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session setup successful")
        } catch {
            self.error = .audioSessionError(error)
            print("Audio session setup failed: \(error)")
        }
    }

    func startRecording() {
        guard isAuthorized else {
            error = .permissionDenied
            print("Cannot start recording: microphone not authorized")
            return
        }

        guard !isRecording else { return }

        setupAudioSession()
        stopTimers()

        isRecording = true
        recordingDuration = 0
        startTimers()
        error = nil
        print("Audio recording started")
    }

    func stopRecording() {
        guard isRecording else { return }

        stopTimers()
        isRecording = false

        // Deactivate audio session
        do {
            try audioSession?.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }

        print("Audio recording stopped")
    }

    func cancelRecording() {
        stopRecording()
        recordingDuration = 0
        audioLevel = 0.0
        error = nil
        print("Audio recording cancelled")
    }

    private func startTimers() {
        // Recording duration timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {
            [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            Task { @MainActor in
                guard self.isRecording else {
                    timer.invalidate()
                    return
                }
                self.recordingDuration += 0.1
            }
        }

        if let timer = recordingTimer {
            RunLoop.main.add(timer, forMode: .common)
        }

        // Audio level timer
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) {
            [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            Task { @MainActor in
                guard self.isRecording else {
                    timer.invalidate()
                    return
                }
                self.updateAudioLevel()
            }
        }

        if let timer = levelTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopTimers() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }

    private func updateAudioLevel() {
        // Simulate audio level for now - in a real implementation, this would read from the audio input
        if isRecording {
            audioLevel = Float.random(in: 0.1...0.8)
        } else {
            audioLevel = 0.0
        }
    }

    func getRecordingData() -> Data? {
        // This would return actual recording data in a real implementation
        return nil
    }

    deinit {
        recordingTimer?.invalidate()
        levelTimer?.invalidate()
    }
}

enum AudioRecordingError: LocalizedError {
    case permissionDenied
    case audioSessionError(Error)
    case recordingURLError
    case recordingStartError
    case recordingError(Error)
    case recordingFinishError
    case encodingError(Error)
    case fileReadError(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required to record audio."
        case .audioSessionError(let error):
            return "Audio session error: \(error.localizedDescription)"
        case .recordingURLError:
            return "Failed to create recording URL."
        case .recordingStartError:
            return "Failed to start recording."
        case .recordingError(let error):
            return "Recording error: \(error.localizedDescription)"
        case .recordingFinishError:
            return "Recording finished with an error."
        case .encodingError(let error):
            return "Audio encoding error: \(error.localizedDescription)"
        case .fileReadError(let error):
            return "Failed to read recording file: \(error.localizedDescription)"
        }
    }
}
