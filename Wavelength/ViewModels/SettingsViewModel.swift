import Foundation
import SwiftUI

// MARK: - Settings View Model
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var showExportSheet = false
    @Published var showEraseConfirmation = false
    @Published var showPrivacySheet = false
    @Published var showCrisisResources = false
    
    private let onModeToggle: () -> Void
    private let onExportData: () -> Void
    private let onEraseData: () -> Void
    
    init(
        onModeToggle: @escaping () -> Void,
        onExportData: @escaping () -> Void,
        onEraseData: @escaping () -> Void
    ) {
        self.onModeToggle = onModeToggle
        self.onExportData = onExportData
        self.onEraseData = onEraseData
    }
    
    // MARK: - Actions
    func toggleMode() {
        onModeToggle()
    }
    
    func exportData() {
        showExportSheet = true
        onExportData()
    }
    
    func eraseData() {
        showEraseConfirmation = true
    }
    
    func confirmErase() {
        onEraseData()
        showEraseConfirmation = false
    }
    
    func showPrivacy() {
        showPrivacySheet = true
    }
    
    func showCrisis() {
        showCrisisResources = true
    }
    
    // MARK: - App Info
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
