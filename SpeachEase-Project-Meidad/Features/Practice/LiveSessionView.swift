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
                        
                        if isCameraEnabled {
                            CameraPreview()
                                .transition(.move(edge: .bottom))
                                .zIndex(1) // Ensure it sits on top of black
                        }
                    }
                    
                    AnimatedGlowWaveView()
                        .frame(height: 900)
                        .allowsHitTesting(false)
                        .mask(
                            LinearGradient(
                                colors: [.black, .black, .black.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .zIndex(2) // Waves on top of camera
                    
                    // Timer Overlay
                    VStack {
                        Text(formatTime(recorder.duration))
                            .font(.system(size: 36, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2)
                            .padding(.top, 60)
                        
                        Spacer()
                    }
                    .zIndex(3) // Timer on top of everything
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 40,
                        bottomTrailingRadius: 40,
                        topTrailingRadius: 0
                    )
                )
                .ignoresSafeArea(edges: .top)
                
                // MARK: - Bottom Controls
                ZStack {
                    HStack(spacing: 20) {
                        
                        // A. Cancel
                        Button {
                            onCancel()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 26, weight: .bold))
                                .frame(width: buttonSize, height: buttonSize)
                                .glassEffect()
                        }
                        
                        // B. Camera Toggle
                        Button {
                            // FIX: Custom Animation for the "Wave/Slide Up" effect
                            // Using a spring animation gives it a nice "organic" feel
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isCameraEnabled.toggle()
                            }
                        } label: {
                            Image(systemName: isCameraEnabled ? "video.fill" : "video.slash.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .frame(width: buttonSize, height: buttonSize)
                                .glassEffect()
                        }

                        // C. Mic Toggle
                        Button {
                            isMicEnabled.toggle()
                        } label: {
                            Image(systemName: isMicEnabled ? "mic.fill" : "mic.slash.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .frame(width: buttonSize, height: buttonSize)
                                .glassEffect()
                                .contentTransition(.symbolEffect(.replace))
                        }
                        
                        // D. Finish (Checkmark)
                        Button {
                            finishSession()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 26, weight: .bold))
                                .frame(width: buttonSize, height: buttonSize)
                                .glassEffect(
                                    tint: .accentColor
                                )
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 30)
                    .padding(.bottom, 10)
                }
                .background(Color.clear)
            }
        }
        .onAppear {
            recorder.prepare()
            recorder.startRecording()
        }
        .onDisappear {
            _ = recorder.stopRecording()
        }
    }
    
    // MARK: - Helpers
    func finishSession() {
        if let url = recorder.stopRecording() {
            onFinish(.success(url))
        }
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Liquid Glass Extension
extension View {
    func glassEffect(tint: Color = .white.opacity(0.1)) -> some View {
        self
            .background {
                ZStack {
                    // The "Icy" Material Base
                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    
                    // The Tint Layer
                    Circle()
                        .fill(tint)
                }
            }
            // Inner rim lighting
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 1)
                    .blendMode(.overlay)
            )
            // Soft drop shadow
            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)
    }
}
