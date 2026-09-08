import SwiftUI

struct LiveSessionView: View {
    @Environment(\.dismiss) var dismiss
    
    var onFinish: (Result<URL, Error>) -> Void
    var onCancel: () -> Void
    
    @StateObject private var recorder = LiveAudioRecorder()
    @State private var isCameraEnabled = false
    @State private var isMicEnabled = true
    
    private let buttonSize: CGFloat = 72
    
    var body: some View {
        ZStack {
            // GLOBAL BACKGROUND
            Color.black.ignoresSafeArea()
            
            // BACKGROUND GLOW
            AnimatedGlowWaveView()
                .frame(height: 900)
                .blur(radius: 100)
                .scaleEffect(x: 1.5, y: 1.2)
                .opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // MARK: - Main Top Container
                ZStack(alignment: .bottom) {
                    
                    // A. Background (Camera or Black)
                    // FIX: Changed to ZStack so Color.black is ALWAYS behind.
                    // Added transition to CameraPreview for the "Wave Up" effect.
                    ZStack {
                        Color.black
