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

    
    private var recordingTimer: Timer?
    private var levelTimer: Timer?

    
    override init() {
        super.init()
        setupAudioSession()
    }

    
    private func setupAudioSession() {
        
        
    }

    
    func startRecording() {
        guard !isRecording else { return }

        
        stopTimers()

        
        isRecording = true
        recordingDuration = 0
        startTimers()
        error = nil
    }

    func stopRecording() {
        guard isRecording else { return }

        stopTimers()
        isRecording = false
    }

    func cancelRecording() {
        stopRecording()
        recordingDuration = 0
        audioLevel = 0.0
        error = nil
    }

    
    private func startTimers() {
        
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
        
        
        if isRecording {
            audioLevel = Float.random(in: 0.1...0.8)
        } else {
            audioLevel = 0.0
        }
    }

    
    func getRecordingData() -> Data? {
        
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
