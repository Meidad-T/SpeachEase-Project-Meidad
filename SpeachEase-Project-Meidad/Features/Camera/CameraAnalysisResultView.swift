import SwiftUI

struct CameraAnalysisResultView: View {
    let report: CameraBodyLanguageReport
    var isLoading: Bool = false
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    var isPad: Bool { sizeClass == .regular }
    
    var body: some View {
        ZStack {
            // Mesh background (assuming it's globally available or I might need to copy/find it, usually it's in DesignSystem or similar)
            // If MeshBackground is not found, I'll fallback to a color.
            MeshBackground()
            
            ScrollView {
                VStack(spacing: 30) {
                    // 1. Header (Activity Ring)
                    CameraResultsScoreHeader(score: Int(report.score), feedback: getFeedback(score: report.score))
                        .padding(.top, 20)
                    
                    // 2. Summary
                    // For now, body language report doesn't have a generated text summary in the struct I created,
                    // so I'll create a simple one based on insights.
                    VStack(alignment: .leading, spacing: 16) {
                        CameraResultsSummary(report: report, isLoading: isLoading)
                    }
                    
                    // 3. Metrics & Insights
                    if !isLoading {
                        VStack(spacing: 30) {
                            CameraResultsMetricsGrid(report: report)
                                .padding(.horizontal)
                            
                            CameraResultsInsightsList(userInsights: report.insights)
                                .padding(.bottom, 40)
                            
                            CameraResultsTranscript(transcript: report.transcript)
                                .padding(.horizontal)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isLoading)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Analysis Result")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func getFeedback(score: Double) -> String {
        if score >= 90 { return "Excellent Body Language!" }
        if score >= 70 { return "Good Job!" }
        if score >= 50 { return "Getting There" }
        return "Needs Improvement"
    }
}

// MARK: - Components

struct CameraResultsScoreHeader: View {
    let score: Int
    let feedback: String
    @State private var animatedScore: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 20)
                    .frame(width: 220, height: 220)
                
                // Ring (Reuse ActivityRing if available, else simple Circle)
                // Assuming ActivityRing is available in the project context
                ActivityRing(progress: animatedScore / 100, color: scoreColor(Int(animatedScore)))
                    .frame(width: 220, height: 220)
                
                // Text
                VStack(spacing: 4) {
                    Text("\(Int(animatedScore))")
                        .font(.system(size: 70, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("Out of 100")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
            }
            .padding(.top, 10)
            
            Text(feedback)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.primary.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).delay(0.2)) {
                animatedScore = Double(score)
            }
        }
    }
    
    func scoreColor(_ score: Int) -> Color {
        if score >= 90 { return .green }
        if score >= 70 { return .cyan }
        if score >= 50 { return .orange }
        return .red
    }
}

struct CameraResultsSummary: View {
    let report: CameraBodyLanguageReport
    var isLoading: Bool = false
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.purple)
                    
                    Text("Analysis Summary")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                
                if report.insights.isEmpty {
                    Text("No significant insights found.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                } else {
                    Text(report.insights.map { $0.description }.joined(separator: " "))
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct CameraResultsMetricsGrid: View {
    let report: CameraBodyLanguageReport
    
    @State private var showCard1 = false
    @State private var showCard2 = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                MetricCard(title: "Eye Contact", score: report.eyeContactScore, icon: "eye.fill", color: .cyan, delay: 0.0)
                    .opacity(showCard1 ? 1 : 0)
                    .offset(y: showCard1 ? 0 : 20)
                
                // Placeholder for other metric if available, for now just duplicated or empty slot
                // Since report only has eyeContactScore explicitly breaking out, 
                // but generated score includes gesture/movement. 
                // Let's infer them roughly or just show Overall Score again as a placeholder/or just omit.
                // Actually, I'll just show Eye Contact big for now, or maybe add a "Confidence" placeholder.
                
                MetricCard(title: "Overall", score: report.score, icon: "chart.bar.fill", color: .purple, delay: 0.1)
                    .opacity(showCard2 ? 1 : 0)
                    .offset(y: showCard2 ? 0 : 20)
            }
        }
        .onAppear {
            let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
            withAnimation(spring.delay(0.0)) { showCard1 = true }
            withAnimation(spring.delay(0.1)) { showCard2 = true }
        }
    }
}

struct CameraResultsInsightsList: View {
    let userInsights: [SpeechInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Insights")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .padding(.horizontal)
            
            ForEach(Array(userInsights.enumerated()), id: \.element.id) { index, insight in
                GlassCard {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: insight.type.icon)
                            .foregroundStyle(insight.type.color)
                            .font(.title3)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(insight.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(insight.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity).animation(.spring().delay(Double(index) * 0.1)))
            }
        }
    }
}

struct CameraResultsTranscript: View {
    let transcript: String
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "quote.bubble.fill")
                        .foregroundStyle(Color.blue)
                    Text("Transcript")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                
                Text(transcript.isEmpty ? "No speech detected." : transcript)
                    .font(.body)
                    .italic()
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
