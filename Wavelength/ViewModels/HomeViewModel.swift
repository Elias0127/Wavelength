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
                
                if !isRecording && !transcript.isEmpty {
                    self?.createEntryFromTranscript()
                    self?.showReflection = true
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

    private func createEntryFromTranscript() {
        let currentTranscript = recordingService.transcript
        guard !currentTranscript.isEmpty else { return }

        
        let words = currentTranscript.components(separatedBy: " ")
        let title = words.prefix(3).joined(separator: " ")

        
        let sentimentAnalysis = aiService.analyzeSentiment(currentTranscript)
        let tags = aiService.extractTags(from: currentTranscript)
        let counselorReply = aiService.generateCounselorReply(
            for: currentTranscript, feeling: sentimentAnalysis.feeling)

        let entry = Entry(
            title: title,
            transcript: currentTranscript,
            counselorReply: counselorReply,
            tags: tags,
            feeling: sentimentAnalysis.feeling,
            valenceSeries: sentimentAnalysis.valenceSeries,
            mode: dataService.mode
        )

        dataService.addEntry(entry)
    }
}
