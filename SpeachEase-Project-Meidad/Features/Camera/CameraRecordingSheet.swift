import SwiftUI
import AVFoundation

struct CameraRecordingSheet: View {
    @Environment(\.dismiss) var dismiss
    var onFinish: (Result<URL, Error>) -> Void
    
    // Logic State (Reusing Manager)
    @StateObject private var cameraManager = CameraRecordingManager()
    
    // Optional: External Analysis Binding
    var externalAnalysisStatus: Binding<String>? = nil
    
    init(externalAnalysisStatus: Binding<String>? = nil, onFinish: @escaping (Result<URL, Error>) -> Void) {
        self.externalAnalysisStatus = externalAnalysisStatus
        self.onFinish = onFinish
    }
    
    // UI State from CameraTestView
    @State private var showSettings = false
    
    // Navigation State for Settings
    enum SettingsPage {
        case main
        case motion
        case themes
        case audio
    }
    @State private var currentSettingsPage: SettingsPage = .main
    
    // Countdown State
    enum CountdownOption: Int, CaseIterable {
        case off = 0
        case three = 3
        case five = 5
        case ten = 10
        case twenty = 20
        
        var display: String {
            switch self {
            case .off: return "Off"
            default: return "\(self.rawValue)s"
            }
        }
    }
    @State private var countdownDuration: CountdownOption = .off
    @State private var isCountingDown = false
    @State private var showTimerSelection = false
    @State private var countdownValue = 0
    @State private var countdownTask: Task<Void, Never>?
    @State private var isAnalyzing = false
    
    @State private var deviceOrientation: UIDeviceOrientation = .portrait

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Color(uiColor: .systemBackground).ignoresSafeArea()
                
                let isUpsideDown = deviceOrientation == .portraitUpsideDown
                let isLandscape = geo.size.width > geo.size.height
                
                if isLandscape || isUpsideDown {
                    // Orientation Guard
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        VStack(spacing: 30) {
                            Image(systemName: isUpsideDown ? "iphone.gen3" : "iphone.gen3.turn.right")
                                .font(.system(size: 100))
                                .foregroundStyle(.white)
                                .symbolEffect(.bounce, options: .repeating)
                            
                            Text(isUpsideDown ? "UPSIDE DOWN" : "PORTRAIT MODE ONLY")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Text(isUpsideDown ? "Please turn your device right side up." : "The Camera Lesson requires Portrait mode\nfor accurate body language analysis.")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                
                            Button {
                                dismiss()
                            } label: {
                                Text("Cancel")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 15)
                                    .background(.white.opacity(0.2), in: Capsule())
                            }
                            .padding(.top, 20)
                        }
                    }
                    .transition(.opacity)
                } else {
                    VStack {
                        // Header with Gear
                        ZStack {
                            // Centered Timer (when recording)
                            if cameraManager.isRecording {
                                Text(formattedDuration)
                                    .font(.system(size: 40, weight: .bold))
                                    .monospacedDigit()
                                    .foregroundStyle(.primary)
                            }
                            
                            HStack {
                                if !cameraManager.isRecording {
                                    Button {
                                        dismiss()
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.title2)
                                            .foregroundStyle(.primary)
                                            .padding(10)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Circle())
                                    }
                                } else {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 12, height: 12)
                                }
                                
