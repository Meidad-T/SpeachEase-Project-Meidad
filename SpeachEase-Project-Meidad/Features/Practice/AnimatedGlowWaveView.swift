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
