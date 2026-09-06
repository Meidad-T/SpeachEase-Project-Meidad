import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
import Speech
import CoreMedia

struct PracticeSessionView: View {
    @Binding var session: PracticeSession
    var onSave: (PracticeSession) -> Void
    @Environment(\.dismiss) var dismiss
    
    // Logic State
    @StateObject private var speechManager = SpeechRecognizerManager()
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var timer: Timer?
    @State private var currentTime: TimeInterval = 0
    @State private var totalDuration: TimeInterval = 0
    
    // UI State
    @State private var selectedTab = "New"
    @State private var isImporting = false
    @State private var isAnalyzing = false
    @State private var analysisStatus: String = "Processing..."
    
    @State private var showFullTranscript = false
    
    // Animation Flags for Progressive Reveal
    @State private var showTranscript = false
    @State private var showSummary = false
    @State private var showMetrics = false
    @State private var showScore = false
    @State private var isResultMode = false
    
    // Error State
    @State private var showErrorAlert = false
    @State private var errorAlertMessage = ""
    
    // Reset Confirmation
    @State private var showResetConfirmation = false
    
    // Confidence Rating
    @State private var confidenceScore: Int = 50
    
    // Recording Sheets
    @State private var showRecordingChoice = false
    @State private var showAudioRecorder = false
    @State private var showVideoRecorder = false
    
    // Memoized Focus Sets
    var activeFoci: [PracticeFocus] {
        session.foci
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MeshBackground()
                
                ScrollView {
                    VStack(spacing: isResultMode ? 10 : 30) {
                        // Custom Header REMOVED - Using Native Navigation Bar
                        
                        // Focus Chips (Hidden when showing results to reduce clutter)
                        if !isResultMode {
                            HStack {
                                ForEach(activeFoci) { focus in
                                    Label(focus.title, systemImage: focus.icon)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.primary.opacity(0.05), in: Capsule())
                                        .overlay(Capsule().stroke(.primary.opacity(0.2), lineWidth: 1))
                                        .foregroundStyle(.primary)
                                }
                                Spacer()
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                        
                        // Standard Platform Tab Control
                        Picker("Session Mode", selection: $selectedTab) {
                             Text("New Attempt").tag("New")
                             Text("History").tag("Past")
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Hidden logic for Reset Confirmation transition
                        .onChange(of: selectedTab) { _, newValue in
                            if newValue == "New" && isResultMode {
                                // If switching back to New while active result, we might want to confirm reset?
                                // Actually, 'New Attempt' tab usually shows current attempt.
                                // If they want a FRESH attempt, they use the reset button.
                                // Switching tabs shouldn't destructively reset unless intended.
                                // Existing logic was: if selectedTab == "New" && isResultMode { showResetConfirmation }
                                // but with Picker, selection changes immediately.
                                // We'll trigger the alert if they switch TO New while having results,
                                // but maybe just showing the results is fine?
                                // Let's keep it simple: Show the results view. "New Attempt" means "Current Session".
                            }
                        }
                        .confirmationDialog("Practice Another Time?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
                            Button("Reset & Record", role: .destructive) {
                                resetAnalysisState()
                                showRecordingChoice = true
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This will reset the current lesson, warning you to submit another recording for analysis.")
                        }
                        
                        // Content Switching
                        if selectedTab == "New" {
                            startNewSessionView
                        } else {
                            pastAttemptsList
                        }
                    }
                    .padding()
                }
            }
            // Glass Loading Overlay
            .overlay {
                if isAnalyzing {
                    AnalyzingOverlayView(statusText: analysisStatus)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .disabled(isAnalyzing)
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: session.foci.contains(where: { $0.requiresVideo }) ? [.movie, .video] : [.audio],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $showFullTranscript) {
                if let filename = session.recordingFileName,
                   let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    
                    FullTranscriptView(
                        text: speechManager.transcript,
                        audioUrl: docDir.appendingPathComponent(filename),
                        transcription: speechManager.transcriptionResult
                    )
                } else {
                    FullTranscriptView(text: speechManager.transcript, audioUrl: nil, transcription: nil)
                }
            }
            .fullScreenCover(isPresented: $showAudioRecorder) {
                LiveSessionView(
                    onFinish: { result in
                        showAudioRecorder = false
                        handleRecordingResult(result)
                    },
                    onCancel: {
                         showAudioRecorder = false
                    }
                )
            }
            .fullScreenCover(isPresented: $showVideoRecorder) {
                CameraRecordingSheet(externalAnalysisStatus: $analysisStatus) { result in
                    handleRecordingResult(result)
                }
            }
            // Logic handled explicitly by "Analyze" button now
            // .onChange(of: speechManager.transcriptionResult) removed to prevent dupe analysis
        }
        .alert("Analysis Issue", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                resetAnalysisState()
                isImporting = true 
            }
        } message: {
            Text(errorAlertMessage)
        }
        .onAppear {
            // ALWAYS default to choice screen when entering
            showRecordingChoice = true
            
            // Pre-warm Audio Session to reduce recorder lag
            DispatchQueue.global(qos: .userInitiated).async {
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
                try? session.setActive(true)
            }
            
            if let filename = session.recordingFileName {
                guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
                let url = docDir.appendingPathComponent(filename)
                
                if speechManager.transcript.isEmpty {
                     speechManager.transcribeAudioFile(url: url)
                }
            }
        }
    }
    
    // MARK: - Logic
    
    func deleteAttempt(_ attempt: PracticeAttempt) {
        if let index = session.history.firstIndex(where: { $0.id == attempt.id }) {
            withAnimation {
                session.history.remove(at: index)
                onSave(session)
            }
        }
    }
    
    // ... existing funcs ...

    

    
    func handleRecordingResult(_ result: Result<URL, Error>) {
        // Reuse import logic by wrapping URL in array
        handleFileImport(result.map { [$0] })
    }

    func handleFileImport(_ result: Result<[URL], Error>) {

        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            let ext = url.pathExtension.isEmpty ? (session.foci.contains(where: { $0.requiresVideo }) ? "mov" : "m4a") : url.pathExtension
            let uniqueName = "\(UUID().uuidString).\(ext)"
            
            guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
