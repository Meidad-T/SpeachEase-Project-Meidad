import SwiftUI
import AVFoundation
import Vision

struct BodyLanguageReport {
    let score: Double
    let eyeContactScore: Double
    let insights: [SpeechInsight]
}

actor BodyLanguageAnalyzer {
    
    // Normalized Keypoint tracking
    struct FrameData {
        let timestamp: Double
        let leftWrist: CGPoint?
        let rightWrist: CGPoint?
        let root: CGPoint? // Approx center of body
        let nose: CGPoint?
        let faceLeft: CGPoint?
        let faceRight: CGPoint?
        let hasFace: Bool
    }
    
    func analyzeVideo(url: URL) async -> BodyLanguageReport {
        // 1. Extract Frames (Higher sampling rate for motion: 4 FPS)
        let duration = await getDuration(url: url)
        let frames = await generateFrames(url: url, duration: duration, fps: 4)
        
        // 2. Run Vision Analysis
        var frameDataList: [FrameData] = []
        
        for (index, image) in frames.enumerated() {
            let timestamp = Double(index) * 0.25 // 4 FPS = 0.25s interval
            if let data = await processFrame(image: image, timestamp: timestamp) {
                frameDataList.append(data)
            }
        }
        
        // 3. Score & Insight Logic
        return generateReport(data: frameDataList, duration: duration)
    }
    
    // MARK: - Vision Processing
    
    private func processFrame(image: UIImage, timestamp: Double) async -> FrameData? {
        guard let cgImage = image.cgImage else { return nil }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        let bodyRequest = VNDetectHumanBodyPoseRequest()
        let faceRequest = VNDetectFaceLandmarksRequest()
        
