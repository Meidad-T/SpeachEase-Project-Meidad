import SwiftUI
import AVFoundation

@MainActor
final class SpeakerManager: NSObject, ObservableObject {
    static let shared = SpeakerManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var isEnabled = false
    @Published var selectedGender: AVSpeechSynthesisVoiceGender = .female
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String) {
        // Stop any current speech
        stop()
        
        guard isEnabled else { return }
        
        // Configure utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = getPreferredVoice()
        utterance.rate = 0.5 // Default rate
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    private func getPreferredVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        
        // Filter for English (US) and selected gender
        let englishVoices = voices.filter { $0.language == "en-US" && $0.gender == selectedGender }
        
        // Priority: Premium > Enhanced > Default
        // Note: Attribute keys might vary by iOS version, but .quality is standard
        if let premium = englishVoices.first(where: { $0.quality == .premium }) {
            return premium
        }
        
        if let enhanced = englishVoices.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }
        
        return englishVoices.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    func toggle() {
        isEnabled.toggle()
        if !isEnabled {
            stop()
        }
    }
}

extension SpeakerManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
