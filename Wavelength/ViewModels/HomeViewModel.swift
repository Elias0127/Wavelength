import Combine
import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var showReflection = false

    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var transcript = ""
    @Published var isProcessing = false
    @Published var audioLevel: Float = 0.0
    @Published var error: RecordingError?
    @Published var isAuthorized = false

    private let dataService = DataService.shared
    private let recordingService = RecordingService.shared
    private let aiService = AIService.shared
    private var cancellables = Set<AnyCancellable>()

    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init() {
        setupBindings()
    }

    private func setupBindings() {

        recordingService.$isRecording
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)

        recordingService.$recordingDuration
            .assign(to: \.recordingDuration, on: self)
            .store(in: &cancellables)

        recordingService.$transcript
            .assign(to: \.transcript, on: self)
            .store(in: &cancellables)

        recordingService.$isProcessing
            .assign(to: \.isProcessing, on: self)
            .store(in: &cancellables)

        recordingService.$audioLevel
            .assign(to: \.audioLevel, on: self)
            .store(in: &cancellables)

        recordingService.$error
            .assign(to: \.error, on: self)
            .store(in: &cancellables)

        recordingService.$isAuthorized
            .assign(to: \.isAuthorized, on: self)
            .store(in: &cancellables)

        recordingService.$isRecording
            .combineLatest(recordingService.$transcript)
            .sink { [weak self] isRecording, transcript in
                print("Recording state: \(isRecording), Transcript: '\(transcript)'")
                if !isRecording && !transcript.isEmpty {
                    print("Showing reflection with transcript: '\(transcript)'")
                    // Don't create entry here - let ReflectionView handle it
                    self?.showReflection = true
                } else if !isRecording && transcript.isEmpty {
                    print("Recording stopped but transcript is empty")
                }
            }
            .store(in: &cancellables)
    }

    func startRecording() {
        recordingService.startRecording()
    }

    func stopRecording() {
        recordingService.stopRecording()
    }

    func cancelRecording() {
        recordingService.cancelRecording()
        showReflection = false
    }
}
