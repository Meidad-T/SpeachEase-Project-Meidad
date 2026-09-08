import SwiftUI

struct DetailedInsightsView: View {
    let insights: [SpeechInsight]
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var isPad: Bool { sizeClass == .regular }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isPad ? 24 : 16) {
                Text("All Insights")
