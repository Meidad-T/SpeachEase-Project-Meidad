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
    

    
    func transcribeAudioFile(url: URL) {
        // Just-in-time authorization check for Speech Recognition (NOT Microphone)
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .notDetermined {
            SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
                DispatchQueue.main.async {
                    if authStatus == .authorized {
                        self?.hasPermission = true
                        self?.performTranscription(url: url)
                    } else {
                        self?.errorMessage = "Speech recognition permission declined."
                    }
                }
            }
            return
        } else if status == .denied || status == .restricted {
            self.errorMessage = "Speech recognition permission is required to analyze the file."
            return
        }
        
        performTranscription(url: url)
    }
    
    private func performTranscription(url: URL) {
        
        // Cancel previous task if any
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Reset state
        self.transcript = ""
        self.transcriptionResult = nil
        self.isProcessing = true
        self.errorMessage = nil
        
        // Init Recognizer
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        self.speechRecognizer = recognizer
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
