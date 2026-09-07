import SwiftUI

struct AnalyzingView: View {
    @State private var logText: String = ""
    @State private var currentStepIndex = 0
    @State private var timer: Timer?
    @State private var scale: CGFloat = 1.0
    
    // Passed from parent
    var statusMessage: String // "Reading...", "Analyzing..."
    
    private let steps = [
        "Initializing Audio Engine...",
        "Extracting Phonemes...",
        "Analyzing Pitch Variance...",
        "Detecting Filler Words...",
        "Measuring Speech Rate...",
        "Evaluating Emotional Tone...",
        "Compiling Insights...",
        "Finalizing Report..."
    ]
    
    var body: some View {
        ZStack {
            // Background Animation
            Color.black.opacity(0.9).ignoresSafeArea()
            
            // Faint Grid/Nodes Background
            GeometryReader { geo in
                ZStack {
                    ForEach(0..<20) { i in
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: CGFloat.random(in: 20...100))
                            .position(
                                x: CGFloat.random(in: 0...geo.size.width),
                                y: CGFloat.random(in: 0...geo.size.height)
                            )
                            .blur(radius: 10)
                            .animation(
                                Animation.easeInOut(duration: Double.random(in: 2...4))
                                    .repeatForever(autoreverses: true),
                                value: scale
                            )
                    }
                }
            }
            .onAppear { scale = 1.2 }
            
            VStack(spacing: 40) {
                // Central "Brain" / Pulse
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        .frame(width: 150, height: 150)
                        .scaleEffect(scale)
                        .opacity(2 - scale)
                        .animation(
                            Animation.easeOut(duration: 2)
                                .repeatForever(autoreverses: false),
                            value: scale
                        )
                    
                    Circle()
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        .frame(width: 150, height: 150)
                        .scaleEffect(scale)
                        .opacity(2 - scale)
                        .animation(
                            Animation.easeOut(duration: 2).delay(0.5)
                                .repeatForever(autoreverses: false),
                            value: scale
                        )
                    
                    Image(systemName: "waveform.path")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                
                // Typewriter Text
                VStack(spacing: 12) {
                    Text("ANALYZING")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(4)
                        .foregroundStyle(.gray)
                    
                    Text(statusMessage.isEmpty ? steps[currentStepIndex] : statusMessage)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        // Typewriter logic handled by parent passing different strings, 
                        // or we auto-cycle if parent provides a generic "Analyzing..."
