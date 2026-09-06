import SwiftUI

struct AnimatedGlowWaveView: View {
    
    // Config: Massive heights and "Pop" colors
    private let waves: [WaveConfig] = [
        // 1. Back Wave (The Highlighter Yellow)
        // Tallest, widest, provides the "Atmosphere"
        WaveConfig(
            color: Color(red: 1.0, green: 1.0, blue: 0.0), // Bright Neon Yellow
            horizontalSpeed: 16,
            baseAmplitude: 100, // Doubled height roughly
            amplitudeRange: 35,
            baseBaselineOffset: -20,
            baselineRange: 40,
            intervalMultiplier: 1.0
        ),
        
        // 2. Middle Wave (Glowing Peach)
        WaveConfig(
            color: Color(red: 1.0, green: 0.6, blue: 0.3), // Neon Peach
            horizontalSpeed: 10,
            baseAmplitude: 140,
            amplitudeRange: 50,
            baseBaselineOffset: -10,
            baselineRange: 30,
            intervalMultiplier: 0.7
        ),
        
        // 3. Front Wave (Electric Orange)
        // Sharpest, lowest, but still tall
        WaveConfig(
            color: Color(red: 1.0, green: 0.45, blue: 0.1),
            horizontalSpeed: 6,
            baseAmplitude: 90,
            amplitudeRange: 30,
            baseBaselineOffset: 25,
            baselineRange: 20,
            intervalMultiplier: 0.4
        )
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Base Ambient Glow (Fills the bottom half)
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.5, blue: 0.0).opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .bottom,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                // The 3 Dynamic Waves
                ForEach(0..<waves.count, id: \.self) { index in
                    SingleWaveView(
                        config: waves[index],
                        screenSize: geo.size
                    )
                }
            }
            // METAL ACCELERATION
            // Essential for 60fps with multiple blurs. 
            // We use .clipped() to prevent the "vertical artifact" glitch.
            .drawingGroup()
            .clipped()
        }
    }
}

// MARK: - Configuration
struct WaveConfig {
    let color: Color
    let horizontalSpeed: Double
    let baseAmplitude: CGFloat
    let amplitudeRange: CGFloat
    let baseBaselineOffset: CGFloat
    let baselineRange: CGFloat
    let intervalMultiplier: CGFloat
}

// MARK: - Single Wave View
struct SingleWaveView: View {
    let config: WaveConfig
    let screenSize: CGSize

    @State private var offset: CGFloat = 0
    @State private var currentAmplitude: CGFloat
    @State private var currentBaselineOffset: CGFloat

    init(config: WaveConfig, screenSize: CGSize) {
        self.config = config
        self.screenSize = screenSize
        _currentAmplitude = State(initialValue: config.baseAmplitude)
        _currentBaselineOffset = State(initialValue: config.baseBaselineOffset)
    }

    var body: some View {
        let interval = screenSize.width * config.intervalMultiplier
        
        // FIX: Baseline at 85% down the screen, allowing ample room for tall waves
        let baseline = screenSize.height * 0.85
        
        let waveShape = SineWaveShape(
            interval: interval,
            amplitude: currentAmplitude,
            baseline: baseline + currentBaselineOffset
        )
        
        ZStack {
            // LAYER 1: UNIFIED GLOW (Optimization)
            // Replaces the separate "Atmosphere" and "Bloom" layers with one high-quality blur.
            // This reduces the rendering cost significantly (3 passes -> 2 passes).
            waveShape
                .fill(
                    LinearGradient(
                        colors: [config.color.opacity(0.5), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .blur(radius: 60) // "One large layer of blur"
                .offset(y: -50)
            
            // LAYER 2: THE CORE & STROKE
            // Provides the definition
            waveShape
                .fill(
                    LinearGradient(
                        colors: [config.color.opacity(0.8), config.color.opacity(0.0)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .blur(radius: 10)
                .overlay(
                    // White-hot crest
                    waveShape
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 3
                        )
                        .blur(radius: 5)
                )
        }
        .offset(x: offset)
        .onAppear {
            withAnimation(
                .linear(duration: config.horizontalSpeed)
                .repeatForever(autoreverses: false)
            ) {
                offset = -interval
            }
            randomizeWaveMotion()
        }
    }
    
    private func randomizeWaveMotion() {
        let randomDuration = Double.random(in: 2.5...5.0)
        
        let newAmplitude = config.baseAmplitude + CGFloat.random(in: -config.amplitudeRange...config.amplitudeRange)
        let newBaselineOffset = config.baseBaselineOffset + CGFloat.random(in: -config.baselineRange...config.baselineRange)
        
        withAnimation(.easeInOut(duration: randomDuration)) {
            currentAmplitude = newAmplitude
            currentBaselineOffset = newBaselineOffset
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + randomDuration * 0.9) {
            randomizeWaveMotion()
        }
    }
}

// MARK: - Shape Logic
struct SineWaveShape: Shape {
