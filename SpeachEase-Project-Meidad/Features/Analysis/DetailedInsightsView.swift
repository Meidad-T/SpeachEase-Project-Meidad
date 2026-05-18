import SwiftUI

struct DetailedInsightsView: View {
    let insights: [SpeechInsight]
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var isPad: Bool { sizeClass == .regular }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isPad ? 24 : 16) {
                Text("All Insights")
                    .font(isPad ? .largeTitle : .title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                ForEach(insights) { insight in
                    HStack(alignment: .top, spacing: isPad ? 24 : 16) {
                        Image(systemName: insight.type.icon)
                            .font(isPad ? .largeTitle : .title2)
                            .foregroundStyle(insight.type.color)
                            .frame(width: isPad ? 50 : 32)
                        
                        VStack(alignment: .leading, spacing: isPad ? 8 : 4) {
                            Text(insight.title)
                                .font(isPad ? .title2 : .headline)
                            
                            Text(insight.description)
                                .font(isPad ? .title3 : .subheadline)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(isPad ? .body : .caption2)
                                Text(formatTime(insight.timestamp))
                                    .font(isPad ? .body : .caption)
                                    .monospacedDigit()
                            }
                            .foregroundStyle(.secondary.opacity(0.8))
                            .padding(.top, 4)
                        }
                    }
                    .padding(isPad ? 24 : 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(isPad ? 24 : 16)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Detailed Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
