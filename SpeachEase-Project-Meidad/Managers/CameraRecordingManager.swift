import SwiftUI
import Combine

@MainActor
class CameraRecordingManager: ObservableObject {
    @Published var isRecording = false
    @Published var recordedVideoURL: URL?
    @Published var errorMessage: String?
    
    @Published var recordingDuration: TimeInterval = 0
    
    // Triggers for View Controller
    @Published var startRecordingTrigger = false
    @Published var stopRecordingTrigger = false
    
    // Toggle States
    @Published var showHandLines = true
    @Published var showBodyLines = true
    @Published var showFaceLines = true
    @Published var isAudioEnabled = true
    
    // Color Preferences
    @Published var handColor: Color = .green {
        didSet { saveColor(handColor, key: "camera_handColor") }
    }
    @Published var bodyColor: Color = .blue {
        didSet { saveColor(bodyColor, key: "camera_bodyColor") }
    }
    @Published var faceColor: Color = .yellow {
        didSet { saveColor(faceColor, key: "camera_faceColor") }
    }
    
    private var timer: Timer?
