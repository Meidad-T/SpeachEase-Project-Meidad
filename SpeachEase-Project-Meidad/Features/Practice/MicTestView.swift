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
