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
