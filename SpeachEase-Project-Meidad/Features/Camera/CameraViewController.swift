import UIKit
@preconcurrency import AVFoundation
import Vision

protocol CameraControllerDelegate: AnyObject {
    func didFinishRecording(url: URL)
    func didFailRecording(error: Error)
}

class CameraRecordingViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer!
    var movieOutput = AVCaptureMovieFileOutput()
    private var videoDataOutput = AVCaptureVideoDataOutput() // Changed to var for background setup assignment
    
    // Vision - Requests are created locally in captureOutput to avoid threading issues
    private var overlayView: VisionOverlayView!
    
    // Audio
    private var audioInput: AVCaptureDeviceInput?
    
    weak var delegate: CameraControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOverlay()
        setupCamera()
        
        // Optional: optimize logic 
        // handPoseRequest.maximumHandCount = 2 
    }
    
    private func setupOverlay() {
        overlayView = VisionOverlayView(frame: view.bounds)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlayView)
        // Bring to front later after preview layer is added, or ensure z-order
    }
    
    func updateOverlaySettings(hands: Bool, body: Bool, face: Bool, handColor: UIColor, bodyColor: UIColor, faceColor: UIColor) {
        // Ensure overlayView is loaded
        guard overlayView != nil else { return }
        overlayView.showHandLines = hands
        overlayView.showBodyLines = body
        overlayView.showFaceLines = face
        
        overlayView.handColor = handColor
        overlayView.bodyColor = bodyColor
        overlayView.faceColor = faceColor
    }
    
    func updateAudioSettings(enabled: Bool) {
        guard let session = captureSession, let audioInput = audioInput else { return }
        
        let isAudioAdded = session.inputs.contains(audioInput)
        
        // Only reconfigure if state mismatches request
        if enabled && !isAudioAdded {
            session.beginConfiguration()
            if session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }
            session.commitConfiguration()
        } else if !enabled && isAudioAdded {
            session.beginConfiguration()
            session.removeInput(audioInput)
            session.commitConfiguration()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let connection = previewLayer?.connection {
            // FORCE PORTRAIT - DO NOT ADAPT TO LANDSCAPE
            if #available(iOS 17.0, *) {
                connection.videoRotationAngle = 90
            } else {
                connection.videoOrientation = .portrait
            }
        }
        previewLayer?.frame = view.bounds
        overlayView.previewLayer = previewLayer 
        view.bringSubviewToFront(overlayView)
    }
    
    func setupCamera() {
        // Run on background to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Note: setupAudioSession likely touches AVAudioSession.sharedInstance(), which is generally thread-safe but strictly speaking often main-thread bound in UI contexts? 
            // Actually AVAudioSession is generally thread safe. But if it was isolated to main actor we'd have an issue.
            // The warning said: "Call to main actor-isolated instance method 'setupAudioSession()' in a synchronous nonisolated context"
            // So we must call it on MainActor.
            
            Task { @MainActor in
                self.setupAudioSession()
            }
            
            let session = AVCaptureSession()
            session.beginConfiguration()
            session.sessionPreset = .high
            
            // Local outputs for configuration
            let movieOut = AVCaptureMovieFileOutput()
            let videoDataOut = AVCaptureVideoDataOutput()
            
            // Camera Input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                print("No front camera available")
                return
            }
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if session.canAddInput(videoInput) {
                    session.addInput(videoInput)
                }
            } catch {
                print("Camera Input Error: \(error)")
                return
            }
            
            // Audio Input
            var audioIn: AVCaptureDeviceInput?
            if let audioDevice = AVCaptureDevice.default(for: .audio) {
                do {
                    let input = try AVCaptureDeviceInput(device: audioDevice)
                    audioIn = input
                    if session.canAddInput(input) {
                        session.addInput(input)
                    }
                } catch {
                    print("Audio Input Error: \(error)")
                }
            }
            
            // Movie Output
            if session.canAddOutput(movieOut) {
                session.addOutput(movieOut)
            }
            
            // Video Data Output (for Vision)
            if session.canAddOutput(videoDataOut) {
                // Delegate needs to be self (Weakly captured above, but 'self' is the VC).
                // AVCaptureVideoDataOutputSampleBufferDelegate methods are nonisolated, so passing 'self' is fine from background.
                videoDataOut.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
                videoDataOut.alwaysDiscardsLateVideoFrames = true
                session.addOutput(videoDataOut)
                
                // Force Portrait and Mirroring to match the Preview's standard Front Camera behavior
                if let connection = videoDataOut.connection(with: .video) {
                    if #available(iOS 17.0, *) {
                        if connection.isVideoRotationAngleSupported(90) {
                            connection.videoRotationAngle = 90
                        }
                    } else {
                        if connection.isVideoOrientationSupported {
                            connection.videoOrientation = .portrait
                        }
                    }
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true
                    }
                }
            }
            
            session.commitConfiguration()
            
            // Start Running
            session.startRunning()
            
            DispatchQueue.main.async {
                self.captureSession = session
                self.movieOutput = movieOut
                self.videoDataOutput = videoDataOut
                self.audioInput = audioIn
                
                self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
                self.previewLayer.videoGravity = .resizeAspectFill
                self.previewLayer.frame = self.view.bounds
                self.view.layer.insertSublayer(self.previewLayer, at: 0) // Insert behind overlay
                self.overlayView.previewLayer = self.previewLayer
            }
        }
    }
    
    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func startRecording() {
        guard let output = captureSession?.outputs.first(where: { $0 is AVCaptureMovieFileOutput }) as? AVCaptureMovieFileOutput else { return }
        
        // Remove old file
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("temp_camera_recording.mov")
        try? FileManager.default.removeItem(at: tempUrl)
        
        output.startRecording(to: tempUrl, recordingDelegate: self)
    }
    
    func stopRecording() {
        movieOutput.stopRecording()
    }
    
    // MARK: - Vision Delegate
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let size = CGSize(width: Double(width), height: Double(height))
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        let handPoseRequest = VNDetectHumanHandPoseRequest()
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
        let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
        
        do {
            try handler.perform([handPoseRequest, faceLandmarksRequest, bodyPoseRequest])
            
            // Extract Data
            var bodyChains: [[CGPoint]] = []
            var handChains: [[CGPoint]] = []
            var faceChains: [OverlayData.FacePath] = []
            
            // Body
            if let bodyResults = bodyPoseRequest.results {
                for body in bodyResults {
                    if let points = try? body.recognizedPoints(.all) {
                         let chains: [[VNHumanBodyPoseObservation.JointName]] = [
                            [.leftWrist, .leftElbow, .leftShoulder],
                            [.rightWrist, .rightElbow, .rightShoulder],
                            [.leftShoulder, .neck, .rightShoulder]
                         ]
                         for chain in chains {
                             let pts = chain.compactMap { joint -> CGPoint? in
                                 guard let p = points[joint], p.confidence > 0.3 else { return nil }
                                 return p.location
                             }
                             if !pts.isEmpty { bodyChains.append(pts) }
                         }
                    }
                }
            }
            
            // Hands
            if let handResults = handPoseRequest.results {
                for hand in handResults {
                    if let points = try? hand.recognizedPoints(.all) {
                         let fingers: [[VNHumanHandPoseObservation.JointName]] = [
                             [.thumbTip, .thumbIP, .thumbMP, .thumbCMC, .wrist],
                             [.indexTip, .indexDIP, .indexPIP, .indexMCP, .wrist],
                             [.middleTip, .middleDIP, .middlePIP, .middleMCP, .wrist],
                             [.ringTip, .ringDIP, .ringPIP, .ringMCP, .wrist],
                             [.littleTip, .littleDIP, .littlePIP, .littleMCP, .wrist]
                         ]
                         for finger in fingers {
                             let pts = finger.compactMap { joint -> CGPoint? in
                                 guard let p = points[joint], p.confidence > 0.3 else { return nil }
                                 return p.location
                             }
                             if !pts.isEmpty { handChains.append(pts) }
                         }
                    }
                }
            }
            
            // Faces
            if let faceResults = faceLandmarksRequest.results {
                for face in faceResults {
                    if let landmarks = face.landmarks {
                        let box = face.boundingBox
                        
                        func extract(region: VNFaceLandmarkRegion2D?) -> [CGPoint] {
                            guard let r = region else { return [] }
                            return r.normalizedPoints.map { p in
                                CGPoint(
                                    x: box.minX + (CGFloat(p.x) * box.width),
                                    y: box.minY + (CGFloat(p.y) * box.height)
                                )
                            }
                        }
                        
                        if let c = landmarks.faceContour { faceChains.append(.init(points: extract(region: c), isClosed: false)) }
                        if let e = landmarks.leftEye { faceChains.append(.init(points: extract(region: e), isClosed: true)) }
                        if let e = landmarks.rightEye { faceChains.append(.init(points: extract(region: e), isClosed: true)) }
                        if let l = landmarks.outerLips { faceChains.append(.init(points: extract(region: l), isClosed: true)) }
                    }
                }
            }
            
            let data = OverlayData(
                bodyChains: bodyChains,
                handChains: handChains,
                faceChains: faceChains,
                imageSize: size
            )
            
            Task { @MainActor in
                self.overlayView?.update(with: data)
            }
        } catch {
            print("Vision failed: \(error)")
        }
    }
    
    // MARK: - Delegate
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("Error recording: \(error.localizedDescription)")
            }
            self.delegate?.didFinishRecording(url: outputFileURL)
        }
    }
}
