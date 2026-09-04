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
