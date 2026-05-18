import SwiftUI
@preconcurrency import AVFoundation
import UIKit

struct CameraPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController()
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    // Fix layout when view bounds change (e.g. rotation)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("No front camera found")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: cameraDevice)
            if let session = captureSession, session.canAddInput(input) {
                session.addInput(input)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: session)
                previewLayer?.videoGravity = .resizeAspectFill
                previewLayer?.frame = view.bounds
                
                if let layer = previewLayer {
                    view.layer.addSublayer(layer)
                }
                
                // Start running on a background thread to allow UI to load faster
                DispatchQueue.global(qos: .userInitiated).async {
                    session.startRunning()
                }
            }
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
    }
}
