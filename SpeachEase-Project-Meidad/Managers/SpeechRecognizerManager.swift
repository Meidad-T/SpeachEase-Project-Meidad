import SwiftUI
import Speech
import AVFoundation

@MainActor
class SpeechRecognizerManager: ObservableObject {
    @Published var transcript: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var hasPermission: Bool = false
    
    // Permission status
    @Published var permissionStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var transcriptionResult: SFTranscription?
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init() {
        // Lazy init
    }
