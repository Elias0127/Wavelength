import AVFoundation
import Combine
import Foundation
import Speech


@MainActor
class RecordingService: NSObject, ObservableObject {
    static let shared = RecordingService()

    
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var transcript = ""
    @Published var isProcessing = false
    @Published var audioLevel: Float = 0.0
    @Published var error: RecordingError?
    @Published var isAuthorized = false

    
    private let speechRecognitionService = SpeechRecognitionService.shared
    private let audioRecordingService = AudioRecordingService.shared
    private var cancellables = Set<AnyCancellable>()

    
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    
    override init() {
        super.init()
        setupBindings()
    }

    private func setupBindings() {
        
        speechRecognitionService.$isRecording
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)

        speechRecognitionService.$transcript
            .assign(to: \.transcript, on: self)
            .store(in: &cancellables)

        speechRecognitionService.$isAuthorized
            .assign(to: \.isAuthorized, on: self)
            .store(in: &cancellables)

        speechRecognitionService.$error
            .map { speechError in
                guard let speechError = speechError else { return nil }
                return RecordingError.speechRecognitionError(speechError)
            }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)

        
        audioRecordingService.$recordingDuration
            .assign(to: \.recordingDuration, on: self)
            .store(in: &cancellables)

        audioRecordingService.$audioLevel
            .assign(to: \.audioLevel, on: self)
            .store(in: &cancellables)

        audioRecordingService.$error
            .map { audioError in
                guard let audioError = audioError else { return nil }
                return RecordingError.audioRecordingError(audioError)
            }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)

        
        
    }

    
    func startRecording() {
        guard isAuthorized else {
            error = .permissionDenied
            return
        }

        guard !isRecording else { return }

        
        speechRecognitionService.startRecording()
        audioRecordingService.startRecording()

        
        transcript = ""
        error = nil
        isProcessing = false
    }

    func stopRecording() {
        guard isRecording else { return }

        
        speechRecognitionService.stopRecording()

        
        isProcessing = true

        
        audioRecordingService.stopRecording()

        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isProcessing = false
        }
    }

    func cancelRecording() {
        speechRecognitionService.cancelRecording()
        audioRecordingService.cancelRecording()
        transcript = ""
        error = nil
        isProcessing = false
    }
}


enum RecordingError: LocalizedError {
    case permissionDenied
    case speechRecognitionError(SpeechRecognitionError)
    case audioRecordingError(AudioRecordingError)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone and speech recognition permissions are required."
        case .speechRecognitionError(let error):
            return error.errorDescription
        case .audioRecordingError(let error):
            return error.errorDescription
        }
    }
}
