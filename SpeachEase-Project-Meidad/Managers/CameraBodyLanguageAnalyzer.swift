import SwiftUI
import AVFoundation
import Vision
import Speech

struct CameraBodyLanguageReport {
    let score: Double
    let eyeContactScore: Double
    let insights: [SpeechInsight]
    let transcript: String
}

actor CameraBodyLanguageAnalyzer {
    
    // Normalized Keypoint tracking
    struct FrameData {
        let timestamp: Double
        // Arms
        let leftWrist: CGPoint?
        let rightWrist: CGPoint?
        let leftElbow: CGPoint?
        let rightElbow: CGPoint?
        let leftShoulder: CGPoint?
        let rightShoulder: CGPoint?
        
        // Torso / Head
        let root: CGPoint? // Approx center of body (Root/Pelvis)
        let neck: CGPoint?
        
        // Face
        let nose: CGPoint?
        let faceLeft: CGPoint?
        let faceRight: CGPoint?
        let headYaw: Double? // Native 3D Rotation (Radians)
        let hasFace: Bool
    }
    
    // MARK: - Vision Processing
    
    private func processFrame(image: UIImage, timestamp: Double) async -> FrameData? {
        guard let cgImage = image.cgImage else { return nil }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        let bodyRequest = VNDetectHumanBodyPoseRequest()
        let faceRequest = VNDetectFaceLandmarksRequest()
        
        do {
            try requestHandler.perform([bodyRequest, faceRequest])
            
            // Extract Body Points
            var leftWrist: CGPoint?
            var rightWrist: CGPoint?
            var leftElbow: CGPoint?
            var rightElbow: CGPoint?
            var leftShoulder: CGPoint?
            var rightShoulder: CGPoint?
            var root: CGPoint?
            var neck: CGPoint?
            
            if let observation = bodyRequest.results?.first {
                let points = try? observation.recognizedPoints(.all)
                
                func getPoint(_ key: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
                    guard let p = points?[key], p.confidence > 0.3 else { return nil }
                    // Vision origin is bottom-left. Convert to top-left (0,0) for intuitive calc
                    return CGPoint(x: p.location.x, y: 1 - p.location.y)
                }
                
                leftWrist = getPoint(.leftWrist)
                rightWrist = getPoint(.rightWrist)
                leftElbow = getPoint(.leftElbow)
                rightElbow = getPoint(.rightElbow)
                leftShoulder = getPoint(.leftShoulder)
                rightShoulder = getPoint(.rightShoulder)
                root = getPoint(.root)
                neck = getPoint(.neck)
            }
            
            // Extract Face Points
            var nose: CGPoint?
            var faceLeft: CGPoint?
            var faceRight: CGPoint?
            var headYaw: Double?
