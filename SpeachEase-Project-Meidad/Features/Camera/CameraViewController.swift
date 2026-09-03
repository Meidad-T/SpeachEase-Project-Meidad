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
