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
            let destUrl = docDir.appendingPathComponent(uniqueName)
            
            do {
                if FileManager.default.fileExists(atPath: destUrl.path) {
                    try FileManager.default.removeItem(at: destUrl)
                }
                
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    try FileManager.default.copyItem(at: url, to: destUrl)
                } else {
                    try FileManager.default.copyItem(at: url, to: destUrl)
                }
                
                DispatchQueue.main.async {
                    session.recordingFileName = uniqueName
                    session.speechReport = nil
                    // onSave(session) // Removed to prevent potential list reload dismissal
                    
                    speechManager.transcribeAudioFile(url: destUrl)
                    
                    // Auto-Start Analysis once transcription is ready
                    // We need to wait for transcription, which is async in manager
                    // Since manager updates @Published, we can just set isAnalyzing=true and show UI
                    // But we actually need the result.
                    // Let's modify startAnalysis to check periodically or use the manager's published property in the view body to trigger.
                    // Actually, simpler: just trigger startAnalysis() which waits for result?
                    // No, startAnalysis() checks if result exists.
                    
                    // Better approach: Set a flag to auto-analyze when ready
                    self.startAnalysis()
                }
            } catch {
                print("Error: \(error)")
            }
            
        case .failure(let error):
            print("Import failed: \(error)")
        }
    }
    
    func startAnalysis() {
        guard let _ = session.recordingFileName else { return }
        
        // 1. Start UI Flow
        withAnimation {
            isAnalyzing = true
            // showTranscript = true // Removed: Show later for dramatic effect
            analysisStatus = "Transcribing..."
        }
        
        // Polling for transcription completion using Task (MainActor)
        Task { @MainActor in
            // Wait for processing to finish
            while speechManager.isProcessing {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            }
            
            if let error = speechManager.errorMessage {
                // System Error
                handleError("Transcribtion failed: \(error)")
            } else if let result = speechManager.transcriptionResult, 
                      !result.formattedString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // Success
                performAnalysis(transcript: result)
            } else {
                // No Words Detection
                handleError("No words detected! Please select another file!")
            }
        }
    }
    
    func handleError(_ message: String) {
        withAnimation {
            isAnalyzing = false
            errorAlertMessage = message
            showErrorAlert = true
        }
    }
    
    func performAnalysis(transcript: SFTranscription) {
        // Ensure isAnalyzing is true again
        isAnalyzing = true
        analysisStatus = "Analyzing Speech..."
        
        Task {
            guard let filename = session.recordingFileName,
                  let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let fileUrl = docDir.appendingPathComponent(filename)
            
            let timeLimit = session.enforceTimeLimit ? Double(session.timeLimitMinutes ?? 0) * 60.0 : nil
            
            let analyzer = SpeechAnalyzer()
            
            // 1. Run Analysis
            var report = await analyzer.analyze(
                transcript: transcript,
                audioFile: fileUrl,
                timeLimit: timeLimit,
                enforceStrict: session.enforceTimeLimit,
                onProgress: { status in
                    Task { @MainActor in
                        self.analysisStatus = status
                    }
                }
            )
            
            // 2. Video Analysis
            if session.foci.contains(where: { $0.requiresVideo }) {
                await MainActor.run { analysisStatus = "Analyzing Body Language..." }
                let videoAnalyzer = BodyLanguageAnalyzer()
                let videoReport = await videoAnalyzer.analyzeVideo(url: fileUrl)
                
                report.bodyLanguageScore = videoReport.score
                report.eyeContactScore = videoReport.eyeContactScore
                report.visualInsights = videoReport.insights
                report.insights.append(contentsOf: videoReport.insights)
                
                let combinedScore = (Double(report.overallScore) * 0.6) + (videoReport.score * 0.4)
                report.overallScore = Int(combinedScore)
            }
            
            // 3. Complete & Animate Reveal
            await MainActor.run {
                session.speechReport = report
                
                // Save History
                let newAttempt = PracticeAttempt(
                    date: Date(),
                    recordingFileName: filename,
                    speechReport: report,
                    confidenceScore: confidenceScore // Initialize with current default/adjusted score
                )
                session.history.append(newAttempt)
                session.practiceLog.append(Date())
                onSave(session)
                
                isAnalyzing = false
                
                // Close Sheet if present
                if showVideoRecorder {
                     showVideoRecorder = false
                }
                if showAudioRecorder {
                    showAudioRecorder = false
                }
                
                // TRIGGER HIDE of Input UI first
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isResultMode = true
                }
                
                // WAIT for hide animation to largely complete before showing results
                // We use a task delay on main actor or just dispatch async
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    
                    // Sequence of Reveals
                    withAnimation {
                        showTranscript = true
                    }
                    
                    // Staggered Reveal
                    withAnimation(.spring().delay(0.2)) {
                        showSummary = true
                    }
                    withAnimation(.spring().delay(0.6)) {
                        showMetrics = true
                    }
                    withAnimation(.spring().delay(1.0)) {
                        showScore = true
                    }
                }
            }
        }
    }
    
    func resetAnalysisState() {
        session.recordingFileName = nil
        session.speechReport = nil
        confidenceScore = 50 // Reset Confidence
        showScore = false
        showMetrics = false
        showSummary = false
        showTranscript = false
        isResultMode = false // Reset mode
        speechManager.reset()
    }
    
    // MARK: - Subcomponents (Extracted for Compiler Performance)
    
    @ViewBuilder
    private var startNewSessionView: some View {
        if showRecordingChoice {
            // Emulated Choice Screen logic from "else" block below
            // This ensures we always start here if flag is set, regardless of file state
            VStack(spacing: 20) {
                // Welcome Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ready to Practice?")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Choose how you want to start")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                }
                .padding(.bottom, 10)
                
                // 1. Primary Record Button
                Button {
                    // Reset existing state if they choose to record anew
                    if session.recordingFileName != nil {
                        resetAnalysisState()
                    }
                    
                    if session.foci.contains(where: { $0.requiresVideo }) {
                        showVideoRecorder = true
                    } else {
                        showAudioRecorder = true
                    }
                    showRecordingChoice = false // Exit choice mode once action taken
                } label: {
                    RecordLiveActionCard(
                        session: session,
                        requiresVideo: session.foci.contains(where: { $0.requiresVideo })
                    )
                }
                .buttonStyle(.plain)
                
                // 2. Secondary Upload Button
                Button {
                    if session.recordingFileName != nil {
                        resetAnalysisState()
                    }
                    isImporting = true
                    showRecordingChoice = false
                } label: {
                    UploadActionCard()
                }
                .buttonStyle(.plain)
                
                // 3. Return to Previous Attempt (if exists)
                if session.recordingFileName != nil {
                    Button {
                        withAnimation {
                            showRecordingChoice = false
                        }
                    } label: {
                        Text("Back to Selected File")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 10)
                }
            }
            .padding(.top, 20)
            
        } else if let filename = session.recordingFileName {
            // 1. File & Actions
            VStack(spacing: 0) { // Zero spacing to let inner elements control it
                if !isResultMode {
                    FileStatusCard(
                        filename: filename,
                        isProcessing: speechManager.isProcessing,
                        isReady: !speechManager.transcript.isEmpty,
                        onReplace: {
                            // Reset State on Replace
                            resetAnalysisState()
                            showRecordingChoice = true
                        }
                    )
                    .disabled(isAnalyzing)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .padding(.bottom, 20) // Only pad when visible
                }
            }
            
            // 2. Inline Results Stack (Reverse Order)
            LazyVStack(spacing: 15) { // Tighter spacing
                // A. Score (Last to appear, at top)
                if showScore, let report = session.speechReport {
                    ResultsScoreHeader(score: report.overallScore, feedback: report.feedback)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // B. Metrics (Mid Reveal)
                if showMetrics, let report = session.speechReport {
                    ResultsMetricsGrid(report: report, foci: activeFoci)
                        .transition(.scale.combined(with: .opacity))
                    
                    // C. Visual Insights (If available) - New Component
                    if let insights = report.visualInsights, !insights.isEmpty {
                        ResultsInsightsList(userInsights: insights)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.horizontal, 4) // Align with cards
                    }
                }
                
                // C. Summary (First Result Reveal)
                if showSummary {
                    ResultsAISummary(report: session.speechReport)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // D. Transcript (Always at bottom, visible first)
                if showTranscript {
                    TranscriptPreviewCard(
                        text: speechManager.transcript,
                        onViewFull: { showFullTranscript = true }
                    )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    // E. Progress Graph (New Feature)
                    if !session.history.isEmpty {
                        ProgressTrendGraph(
                            history: session.history,
                            currentScore: session.speechReport?.overallScore,
                            currentConfidence: confidenceScore
                        )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 10)
                    }
                    
                    // F. Confidence Rater (Moved to Bottom)
                    ConfidenceRater(score: $confidenceScore)
                        .transition(.scale.combined(with: .opacity))
                        .padding(.bottom, 20) // Extra padding at very bottom
                        .onChange(of: confidenceScore) { _, newValue in
                            // Update history live
                            if let lastIdx = session.history.indices.last {
                                session.history[lastIdx].confidenceScore = newValue
                                onSave(session)
                            }
                        }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showScore) // Faster
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showMetrics)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSummary)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showTranscript)
            
        } else {
            // Empty State - Split Options
            VStack(spacing: 20) {
                // Welcome Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ready to Practice?")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Choose how you want to start")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                }
                .padding(.bottom, 10)
                
                // 1. Primary Record Button
                Button {
                    if session.foci.contains(where: { $0.requiresVideo }) {
                        showVideoRecorder = true
                    } else {
                        showAudioRecorder = true
                    }
                } label: {
                    RecordLiveActionCard(
                        session: session,
                        requiresVideo: session.foci.contains(where: { $0.requiresVideo })
                    )
                }
                .buttonStyle(.plain)
                
                // 2. Secondary Upload Button
                Button {
                    isImporting = true
                } label: {
                    UploadActionCard()
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)
        }
    }
    
    @ViewBuilder
    private var pastAttemptsList: some View {
        PastAttemptsListView(
            history: session.history.sorted(by: { $0.date > $1.date }),
            onDelete: deleteAttempt
        )
    }
}


// MARK: - Subviews

struct TranscriptPreviewCard: View {
    let text: String
    var onViewFull: () -> Void
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Transcript", systemImage: "quote.opening")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(text.isEmpty ? "Transcribing..." : text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if !text.isEmpty {
                    Button(action: onViewFull) {
                        HStack {
                            Spacer()
                            Text("View Full")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.cyan)
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption)
                                .foregroundStyle(.cyan)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct FullTranscriptView: View {
    let text: String
    let audioUrl: URL?
    let transcription: SFTranscription?
    @Environment(\.dismiss) var dismiss
    
    // Audio State
    @State private var audioPlayer: AVPlayer?
    @State private var isPlaying: Bool = false
    @State private var currentTime: TimeInterval = 0
    @State private var totalDuration: TimeInterval = 0
    @State private var timeObserver: Any?
    
    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if let transcription = transcription, let _ = audioUrl {
                                // Interactive Flow Layout
                                FlowLayout(spacing: 6) {
                                    ForEach(transcription.segments.indices, id: \.self) { index in
                                        let segment = transcription.segments[index]
                                        let isHighlighted = currentTime >= segment.timestamp && currentTime < (segment.timestamp + segment.duration)
                                        
                                        Text(segment.substring)
                                            .font(.body)
                                            .fontWeight(isHighlighted ? .bold : .regular)
                                            .foregroundStyle(isHighlighted ? Color.accentColor : .primary) // Accent highlight
                                            .padding(.horizontal, 2)
                                            .padding(.vertical, 1)
                                            .background(
                                                isHighlighted ? Color.accentColor.opacity(0.1) : Color.clear
                                            )
                                            .cornerRadius(4)
                                            .onTapGesture {
                                                seek(to: segment.timestamp)
                                            }
                                    }
                                }
