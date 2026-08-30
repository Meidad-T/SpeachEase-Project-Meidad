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
            var hasFace = false
            
            if let faceObs = faceRequest.results?.first {
                hasFace = true
                if let yaw = faceObs.yaw {
                    headYaw = Double(truncating: yaw)
                }
                
                if let nosePoints = faceObs.landmarks?.nose?.normalizedPoints, let firstNose = nosePoints.first {
                     nose = CGPoint(x: firstNose.x, y: 1 - firstNose.y)
                }
                 
                if let contour = faceObs.landmarks?.faceContour?.normalizedPoints {
                     if let l = contour.first, let r = contour.last {
                         faceLeft = CGPoint(x: l.x, y: 1 - l.y)
                         faceRight = CGPoint(x: r.x, y: 1 - r.y)
                     }
                }
            }
            
            return FrameData(
                timestamp: timestamp,
                leftWrist: leftWrist,
                rightWrist: rightWrist,
                leftElbow: leftElbow,
                rightElbow: rightElbow,
                leftShoulder: leftShoulder,
                rightShoulder: rightShoulder,
                root: root,
                neck: neck,
                nose: nose,
                faceLeft: faceLeft,
                faceRight: faceRight,
                headYaw: headYaw,
                hasFace: hasFace
            )
            
        } catch {
            print("Vision failed: \(error)")
            return nil
        }
    }

// ... (retain analyzeVideo as is or assume it calls these) ...

    // (Duplicate removed)
    
    // MARK: - Scoring & Insights
    
    func analyzeVideo(url: URL) async -> CameraBodyLanguageReport {
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
        async let transcript = transcribeAudio(url: url)
        return await generateReport(data: frameDataList, duration: duration, transcript: transcript)
    }

    // MARK: - Scoring & Insights
    
    private func generateReport(data: [FrameData], duration: Double, transcript: String) -> CameraBodyLanguageReport {
        var insights: [SpeechInsight] = []
        let totalFrames = Double(data.count)
        if totalFrames == 0 { return CameraBodyLanguageReport(score: 0, eyeContactScore: 0, insights: [], transcript: transcript) }
        
        // --- 1. Posture Analysis ---
        let (postureScore, postureInsights) = analyzePosture(data: data)
        insights.append(contentsOf: postureInsights)
        
        // --- 2. Hand/Gesture Analysis (Power Posing) ---
        let (gestureScore, gestureInsights) = analyzeHands(data: data)
        insights.append(contentsOf: gestureInsights)
        
        // --- 3. Head Engagement ---
        let (headScore, headInsights) = analyzeHead(data: data)
        insights.append(contentsOf: headInsights)
        
        // Weighted Final Score
        // Posture: 30%, Gestures: 40%, Head: 30%
        let finalScore = (postureScore * 0.3) + (gestureScore * 0.4) + (headScore * 0.3)
        
        return CameraBodyLanguageReport(
            score: finalScore,
            eyeContactScore: headScore, // Use head score as proxy for eye contact/engagement
            insights: insights,
            transcript: transcript
        )
    }
    
    // MARK: - Advanced Heuristics (Goldilocks Scoring)
    
    private func analyzePosture(data: [FrameData]) -> (Double, [SpeechInsight]) {
        var score = 100.0
        var insights: [SpeechInsight] = []
        
        var unevenShoulderCount = 0
        var leanCount = 0
        var rootXs: [Double] = []
        let total = Double(data.count)
        
        for frame in data {
            // Check Shoulder Level
            if let l = frame.leftShoulder, let r = frame.rightShoulder {
                let yDiff = abs(l.y - r.y)
                if yDiff > 0.05 { // > 5% screen height difference
                    unevenShoulderCount += 1
                }
            }
            
            // Check Body Lean (Neck vs Root X)
            if let neck = frame.neck, let root = frame.root {
                let xDiff = abs(neck.x - root.x)
                if xDiff > 0.1 { // Significant lean
                    leanCount += 1
                }
                rootXs.append(root.x)
            }
        }
        
        // 1. Static Posture Checks
        let unevenRatio = Double(unevenShoulderCount) / total
        let leanRatio = Double(leanCount) / total
        
        if unevenRatio > 0.3 {
            score -= 15
            insights.append(SpeechInsight(title: "Check Shoulder Alignment", description: "Your shoulders were often uneven. Stand tall.", timestamp: 0, type: .negative))
        }
        
        if leanRatio > 0.3 {
            score -= 15
            insights.append(SpeechInsight(title: "Avoid Leaning", description: "You leaned to the side frequently. Center your weight.", timestamp: 0, type: .negative))
        }
        
        // 2. Nervous Sway Check (Goldilocks: Stable is good, Swaying is bad)
        let swayVariance = calculateVariance(rootXs)
        if swayVariance > 0.02 {
            score -= 20
            insights.append(SpeechInsight(title: "Reduce Swaying", description: "You rocked back and forth significantly. Plant your feet.", timestamp: 0, type: .negative))
        } else if swayVariance < 0.001 {
             // Optional: "Statue" warning, but stability is generally good for posture.
             // We'll award points for stability.
        }
        
        if score > 90 {
            insights.append(SpeechInsight(title: "Strong Posture", description: "You stood tall and grounded throughout.", timestamp: 0, type: .positive))
        }
        
        return (max(0, score), insights)
    }
    
    private func analyzeHands(data: [FrameData]) -> (Double, [SpeechInsight]) {
        var score = 100.0 // Start high, penalize deviations
        var insights: [SpeechInsight] = []
        
        var expansiveCount = 0
        let total = Double(data.count)
        
        // Calculate Movement Intensity (Avg Displacement per Frame)
