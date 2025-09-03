import AVFoundation
import Combine
import Foundation
import Speech


@MainActor
class SpeechRecognitionService: NSObject, ObservableObject {
    static let shared = SpeechRecognitionService()

    
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var isAuthorized = false
    @Published var error: SpeechRecognitionError?

    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    
    override init() {
        super.init()
        requestPermissions()
    }

    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.isAuthorized = true
                case .denied, .restricted, .notDetermined:
                    self?.isAuthorized = false
                    self?.error = .permissionDenied
                @unknown default:
                    self?.isAuthorized = false
                    self?.error = .permissionDenied
                }
            }
        }
    }

    
    func startRecording() {
        guard isAuthorized else {
            error = .permissionDenied
            return
        }

        guard !isRecording else { return }

        
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }

        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = .audioSessionError(error)
            return
        }

        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            self.error = .recognitionRequestError
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            self.error = .speechRecognizerUnavailable
            return
        }

        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) {
            [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcript = result.bestTranscription.formattedString
                }

                if let error = error {
                    self?.error = .recognitionError(error)
                    self?.stopRecording()
                }
            }
        }

        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            transcript = ""
            error = nil
        } catch {
            self.error = .audioEngineError(error)
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        
        recognitionTask?.cancel()
        recognitionTask = nil

        
        do {
            try AVAudioSession.sharedInstance().setActive(
                false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }

        isRecording = false
    }

    func cancelRecording() {
        stopRecording()
        transcript = ""
        error = nil
    }

    
    deinit {
        Task { @MainActor in
            stopRecording()
        }
    }
}


enum SpeechRecognitionError: LocalizedError {
    case permissionDenied
    case audioSessionError(Error)
    case recognitionRequestError
    case speechRecognizerUnavailable
    case recognitionError(Error)
    case audioEngineError(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission is required to use this feature."
        case .audioSessionError(let error):
            return "Audio session error: \(error.localizedDescription)"
        case .recognitionRequestError:
            return "Failed to create speech recognition request."
        case .speechRecognizerUnavailable:
            return "Speech recognition is currently unavailable."
        case .recognitionError(let error):
            return "Recognition error: \(error.localizedDescription)"
        case .audioEngineError(let error):
            return "Audio engine error: \(error.localizedDescription)"
        }
    }
}
