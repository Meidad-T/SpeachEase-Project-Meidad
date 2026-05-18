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
        var leftWristMoves: [Double] = []
        for i in 1..<data.count {
            if let p1 = data[i-1].leftWrist, let p2 = data[i].leftWrist {
                leftWristMoves.append(hypot(p2.x - p1.x, p2.y - p1.y))
            }
        }
        let avgMove = leftWristMoves.reduce(0, +) / Double(max(1, leftWristMoves.count))
        
        for frame in data {
            if let l = frame.leftWrist, let r = frame.rightWrist, let root = frame.root {
                // Expansive: High & Wide
                let isHigh = l.y < root.y && r.y < root.y
                let isWide = abs(l.x - r.x) > 0.4
                if isHigh || isWide { expansiveCount += 1 }
            }
        }
        
        // Goldilocks Zone for Movement
        if avgMove < 0.012 {
            // Too Little (Stiff)
            score -= 25
            insights.append(SpeechInsight(title: "Low Energy", description: "Your hands were stiff. Use gestures to emphasize points.", timestamp: 0, type: .negative))
        } else if avgMove > 0.09 {
            // Too Much (Distracting/Manic)
            score -= 30
            insights.append(SpeechInsight(title: "Distracting Gestures", description: "Your hand movements were excessive and distracting. Slow down.", timestamp: 0, type: .negative))
        } else {
            // Optimal Range (0.012 - 0.09)
            insights.append(SpeechInsight(title: "Good Gesture Frequency", description: "You used a natural amount of hand movement.", timestamp: 0, type: .positive))
        }
        
        // Power Posing Bonus (only if not manic)
        let expansiveRatio = Double(expansiveCount) / total
        if expansiveRatio > 0.2 && avgMove <= 0.09 {
            insights.append(SpeechInsight(title: "Power Posing", description: "You used expansive, confident gestures.", timestamp: 0, type: .positive))
        } else if expansiveRatio < 0.05 && avgMove > 0.012 {
             // Moved but kept small?
             score -= 5
             insights.append(SpeechInsight(title: "Expand Your Space", description: "Your gestures were small. Don't be afraid to take up space.", timestamp: 0, type: .neutral))
        }
        
        return (min(100, max(0, score)), insights)
    }
    
    private func analyzeHead(data: [FrameData]) -> (Double, [SpeechInsight]) {
        var score = 100.0
        var insights: [SpeechInsight] = []
        
        var faceCount = 0
        var yaws: [Double] = []
        let total = Double(data.count)
        
        for frame in data {
            if frame.hasFace {
                faceCount += 1
                if let y = frame.headYaw {
                    yaws.append(y)
                }
            }
        }
        
        let presenceRatio = Double(faceCount) / total
        if presenceRatio < 0.5 {
            return (50, [SpeechInsight(title: "Face Hidden", description: "Ensure your face is clearly visible.", timestamp: 0, type: .negative)])
        }
        
        // Scanning Variance (Using Native Yaw in Radians)
        let yawVariance = calculateVariance(yaws)
        
        // 0.01 variance roughly means +/- 0.1 radians (approx 6 degrees) standard deviation
        // A good scan is probably +/- 30 degrees (0.5 rad), variance ~ 0.12?
        // Let's set Stiff lower bound at 0.005 (very subtle motion)
        // Wandering upper bound at 0.45 (relaxed from 0.3)
        
        if yawVariance < 0.005 {
            // Stiff
            score -= 20
            insights.append(SpeechInsight(title: "Stiff Gaze", description: "You stared straight ahead. Scan the room to engage everyone.", timestamp: 0, type: .negative))
        } else if yawVariance > 0.45 {
            // Wandering / Shifty
            score -= 25
            insights.append(SpeechInsight(title: "Wandering Eyes", description: "Your gaze swung too wildly. Maintain controlled scanning.", timestamp: 0, type: .negative))
        } else {
            // Optimal (0.005 - 0.45)
            insights.append(SpeechInsight(title: "Good Engagement", description: "You scanned the audience naturally.", timestamp: 0, type: .positive))
        }
        
        return (min(100, max(0, score)), insights)
    }
    
    private func transcribeAudio(url: URL) async -> String {
        // Check for audio track presence first
        let asset = AVURLAsset(url: url)
        if let tracks = try? await asset.loadTracks(withMediaType: .audio), tracks.isEmpty {
            return "Mic is turned off in video settings."
        }
        
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            return "Speech recognition not authorized."
        }
        
        let recognizer = SFSpeechRecognizer()
        if recognizer?.isAvailable != true {
             return "Speech recognizer not available."
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        return await withCheckedContinuation { continuation in
            recognizer?.recognitionTask(with: request) { result, error in
                if error != nil {
                    // If errors occur (often because file has no audio even if track exists, or recognizer error), return safe fallback
                    continuation.resume(returning: "No speech detected.")
                    return
                }
                
                if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
    
    // Helpers
    private func calculateVariance(_ data: [Double]) -> Double {
        guard data.count > 1 else { return 0 }
        let mean = data.reduce(0, +) / Double(data.count)
        let sumSq = data.reduce(0) { $0 + ($1 - mean) * ($1 - mean) }
        return sumSq / Double(data.count)
    }
    
    // Existing Helpers
    private func getDuration(url: URL) async -> Double {
        let asset = AVURLAsset(url: url)
        if let duration = try? await asset.load(.duration) {
            return CMTimeGetSeconds(duration)
        }
        return 0
    }
    
    private func generateFrames(url: URL, duration: Double, fps: Double) async -> [UIImage] {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        
        var images: [UIImage] = []
        let interval = 1.0 / fps
        
        var times: [NSValue] = []
        for t in stride(from: 0.0, to: duration, by: interval) {
            times.append(NSValue(time: CMTime(seconds: t, preferredTimescale: 600)))
        }
        
        // Limit to 50 frames max to avoid OOM for now
        let limitedTimes = Array(times.prefix(50))
        
        for timeVal in limitedTimes {
            let time = timeVal.timeValue
            if let image = try? await generator.image(at: time).image {
                images.append(UIImage(cgImage: image))
            }
        }
        
        return images
    }
}
