import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct MicTestView: View {
    @StateObject private var speechManager = SpeechRecognizerManager()
    @State private var audioFileUrl: URL? // Holds the local temp file URL
    @State private var fileName: String = ""
    @State private var isImporting: Bool = false
    @State private var isAnalyzing: Bool = false
    @State private var showAnalysis: Bool = false
    @State private var analysisReport: SpeechReport?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                HStack {
                    Text("Speech Tools")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.top, 20)
                
                // 1. Upload Section
                if let _ = audioFileUrl {
                    // State: File Uploaded
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(speechManager.isProcessing ? AnyShapeStyle(Color.orange.gradient) : AnyShapeStyle(Color.blue.gradient))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Selected File")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                
                                Text(fileName)
                                    .font(.headline)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                if speechManager.isProcessing {
                                    Text("Processing...")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                } else if speechManager.transcript.isEmpty == false {
                                    Text("Ready")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: { isImporting = true }) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        // Options Grid (Revealed after upload)
                        VStack(spacing: 20) {
                            // Transcript Option
                            NavigationLink(destination: TranscriptionResultView(speechManager: speechManager, audioUrl: audioFileUrl)) {
                                MicTestCard(
                                    title: "Transcript",
                                    subtitle: speechManager.isProcessing ? "Transcribing..." : "View full text transcription",
                                    actionText: "View",
                                    icon: "doc.text.viewfinder",
                                    color: Color("AccentColor"),
                                    isLoading: speechManager.isProcessing
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // Analysis Option
                            Button {
                                if let url = audioFileUrl, let transcription = speechManager.transcriptionResult {
                                    Task {
                                        isAnalyzing = true
                                        let analyzer = SpeechAnalyzer()
                                        let report = await analyzer.analyze(transcript: transcription, audioFile: url)
                                        self.analysisReport = report
                                        isAnalyzing = false
                                        showAnalysis = true
                                    }
                                }
                            } label: {
                                MicTestCard(
                                    title: "Analysis",
                                    subtitle: "Get AI feedback on tone & pacing",
                                    actionText: isAnalyzing ? "Analyzing..." : "Analyze",
                                    icon: "waveform.path.ecg",
                                    color: .purple,
                                    isLoading: isAnalyzing
                                )
                            }
                            .disabled(isAnalyzing || speechManager.transcriptionResult == nil)
                            .buttonStyle(.plain)
                            .navigationDestination(isPresented: $showAnalysis) {
                                if let report = analysisReport {
                                    AnalysisResultView(report: report)
                                }
                            }
                        }
                    }
                } else {
                    // State: No File (Upload First)
                    Button {
                        isImporting = true
                    } label: {
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "arrow.up.doc.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.blue)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Import Audio File")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                
                                Text("Tap to select a recording to analyze")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                                .foregroundStyle(.secondary.opacity(0.3))
                        )
                    }
                }
            }
            .padding()
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                self.fileName = url.lastPathComponent
                
                // Copy to temp directory to ensure persistent access during async processing
                let tempDir = FileManager.default.temporaryDirectory
                let tempUrl = tempDir.appendingPathComponent(url.lastPathComponent)
                
                do {
                    // Remove existing if any
                    if FileManager.default.fileExists(atPath: tempUrl.path) {
                        try FileManager.default.removeItem(at: tempUrl)
                    }
                    
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        try FileManager.default.copyItem(at: url, to: tempUrl)
                    } else {
                        // Try copying even if scope claim fails (sometimes works for local non-sandboxed debug)
                        try FileManager.default.copyItem(at: url, to: tempUrl)
                    }
                    
                    DispatchQueue.main.async {
                        self.audioFileUrl = tempUrl
                        // AUTO START TRANSCRIPTION
                        self.speechManager.transcribeAudioFile(url: tempUrl)
                    }
                    
                } catch {
                    print("File copy failed: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("Import failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Reusable Card Component
struct MicTestCard: View {
    let title: String
    let subtitle: String
    let actionText: String
    let icon: String
    let color: Color
    var isLoading: Bool = false
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var isPad: Bool {
        sizeClass == .regular
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: isPad ? 28 : 20) {
                VStack(alignment: .leading, spacing: isPad ? 8 : 4) {
                    Text(title)
                        .font(isPad ? .largeTitle : .title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(isPad ? .title3 : .subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                
                // Action Pill
                HStack(spacing: 6) {
                    if isLoading {
                        ProgressView()
                            .tint(color)
                    } else {
                        Image(systemName: actionText == "Coming Soon" ? "lock.fill" : "arrow.right.circle.fill")
                        Text(actionText)
                    }
                }
                .font(isPad ? .headline : .footnote)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .padding(.horizontal, isPad ? 16 : 12)
                .padding(.vertical, isPad ? 12 : 8)
                .background(Color.white)
                .clipShape(Capsule())
            }
            
            Spacer()
            
            // Large Icon
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: isPad ? 120 : 80, height: isPad ? 120 : 80)
                .foregroundStyle(.white.opacity(0.3))
                .rotationEffect(.degrees(-10))
                .offset(x: 10, y: 10)
        }
        .padding(isPad ? 32 : 24)
        .frame(height: isPad ? 240 : 160)
        .background(color.gradient)
        .cornerRadius(isPad ? 32 : 24)
        .shadow(color: color.opacity(0.3), radius: 10, y: 8)
    }
}

// MARK: - Transcription View
struct TranscriptionResultView: View {
    @ObservedObject var speechManager: SpeechRecognizerManager
    let audioUrl: URL?
    var timeLimit: TimeInterval? = nil
    
    // Playback State
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying: Bool = false
    @State private var currentTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var totalDuration: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 24) {
            
            // Transcript Area
            VStack(alignment: .leading, spacing: 8) {
                ScrollViewReader { proxy in
                    ScrollView {
                        if speechManager.isProcessing {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Transcribing audio...")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 50)
                        } else if let error = speechManager.errorMessage {
                             VStack(spacing: 16) {
                                 Image(systemName: "exclamationmark.triangle.fill")
                                     .font(.largeTitle)
                                     .foregroundStyle(.red)
                                Text(error)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                             .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // Success Content
                            VStack(alignment: .leading, spacing: 20) {
