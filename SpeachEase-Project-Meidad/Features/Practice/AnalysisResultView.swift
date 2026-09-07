import SwiftUI

import SwiftUI

import SwiftUI

struct AnalysisResultView: View {
    let report: SpeechReport
    var isLoading: Bool = false 
    var onOpenTranscript: (() -> Void)? = nil
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    var isPad: Bool { sizeClass == .regular }
    
    var body: some View {
        ZStack {
            MeshBackground()
            
            ScrollView {
                VStack(spacing: 30) {
                    // 1. Header (Activity Ring)
                    ResultsScoreHeader(score: report.overallScore, feedback: report.feedback)
                        .padding(.top, 20)
                    
                    // 2. Summary
                    VStack(alignment: .leading, spacing: 16) {
                        ResultsAISummary(report: report, isLoading: isLoading)
                        
                        if !isLoading {
                            Button {
                                onOpenTranscript?()
                            } label: {
                                HStack {
                                    Text("See Transcript")
                                        .fontWeight(.bold)
                                    Image(systemName: "arrow.right")
                                }
                                .font(.subheadline)
                                .foregroundStyle(Color.cyan)
                                .padding(.top, 8)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                    
                    // 3. Metrics & Insights
                    if !isLoading {
                        VStack(spacing: 30) {
                            ResultsMetricsGrid(report: report)
                                .padding(.horizontal)
                            
                            ResultsInsightsList(userInsights: report.insights)
                                .padding(.bottom, 40)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isLoading)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

