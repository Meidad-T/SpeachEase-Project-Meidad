import SwiftUI

// MARK: - Grain Overlay
struct GrainOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: generateNoiseImage(size: CGSize(width: 256, height: 256))) // Generate small tile
                .resizable(resizingMode: .tile) // Tile it
                .ignoresSafeArea()
        }
    }
    
    func generateNoiseImage(size: CGSize) -> UIImage {
        let width = Int(size.width)
        let height = Int(size.height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        var data = [UInt8](repeating: 0, count: width * height)
        for i in 0..<data.count {
            data[i] = UInt8.random(in: 0...255)
        }
        
        guard let provider = CGDataProvider(data: Data(data) as CFData),
              let cgImage = CGImage(
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bitsPerPixel: 8,
                  bytesPerRow: width,
                  space: colorSpace,
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                  provider: provider,
                  decode: nil,
                  shouldInterpolate: false,
                  intent: .defaultIntent
              ) else {
            return UIImage()
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Animated Processing Text
struct AnimatedProcessingText: View {
    let text: String
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    // Clean text by removing any trailing dots
    var cleanText: String {
        var t = text
        while t.hasSuffix(".") {
            t.removeLast()
        }
        return t
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(cleanText)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text(String(repeating: ".", count: dotCount))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, alignment: .leading) // Fixed width for 3 dots
        }
        .onReceive(timer) { _ in
            withAnimation {
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

// MARK: - Animated Gradient Overlay
struct AnalysisGradientOverlay: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Background Warmth (Peach)
            Color(hex: "FFCC80")
            
            // Moving Blobs
            GeometryReader { geo in
                ZStack {
                    // Blob 1: Dark Orange (was Yellow)
                    Circle()
                        .fill(Color(hex: "E65100").opacity(0.8))
                        .frame(width: geo.size.width * 1.5, height: geo.size.width * 1.5)
                        .position(x: animate ? geo.size.width * 0.2 : geo.size.width * 0.8,
                                  y: animate ? geo.size.height * 0.2 : geo.size.height * 0.8)
                        .blur(radius: 80)
                    
                    // Blob 2: Deep Red/Orange
                    Circle()
                        .fill(Color(hex: "BF360C").opacity(0.6))
                        .frame(width: geo.size.width * 1.2, height: geo.size.width * 1.2)
                        .position(x: animate ? geo.size.width * 0.9 : geo.size.width * 0.1,
                                  y: animate ? geo.size.height * 0.8 : geo.size.height * 0.1)
