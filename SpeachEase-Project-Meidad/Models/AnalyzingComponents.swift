import SwiftUI

// MARK: - Analyzing Overlay (Inspired by DreamAnalysis)
struct AnalyzingOverlayView: View {
    let statusText: String // "Reading...", "Analyzing..."
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            // The "Analyzing..." container
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
