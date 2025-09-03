import Foundation
import SwiftUI

// MARK: - Home View Model
@MainActor
class HomeViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var showReflection = false
    @Published var mockTranscript = ""
    
    private var recordingTimer: Timer?
    
    // MARK: - Recording Actions
    func startRecording() {
        isRecording = true
        recordingDuration = 0
        startTimer()
        
        // TODO: hook up AVAudioEngine + VAD + STT
        // For now, simulate recording with mock transcript
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.mockTranscript = "I'm feeling a bit overwhelmed today. Work has been really busy and I haven't had much time for myself. I think I need to set better boundaries."
        }
    }
    
    func stopRecording() {
        isRecording = false
        stopTimer()
        showReflection = true
    }
    
    func cancelRecording() {
        isRecording = false
        stopTimer()
        recordingDuration = 0
        mockTranscript = ""
    }
    
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.recordingDuration += 0.1
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
