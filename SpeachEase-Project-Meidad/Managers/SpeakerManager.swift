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
