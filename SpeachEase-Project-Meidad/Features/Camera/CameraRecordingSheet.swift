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
                                
                                Spacer()
                                
                                // Gear Icon
                                Button {
                                    withAnimation {
                                        showSettings.toggle()
                                        currentSettingsPage = .main
                                    }
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .font(.title2)
                                        .foregroundStyle(.primary)
                                        .padding(10)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .shadow(radius: 2)
                                }
                                .disabled(cameraManager.isRecording)
                                .opacity(cameraManager.isRecording ? 0 : 1)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Camera Card
                        ZStack(alignment: .topTrailing) {
                            CameraViewWrapper(manager: cameraManager)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            if isAnalyzing {
                                ZStack {
                                    // Base dimming for camera visibility ("faintly")
                                    Color.black.opacity(0.3)
                                    
                                    // Animated Gradient + Grain
                                    AnalysisGradientOverlay()
                                        .opacity(0.85) // High opacity to dominate, but let some camera through
                                    
                                    VStack(spacing: 12) {
                                        LottieView(filename: "video-processing")
                                            .frame(width: 375, height: 375)
                                            .offset(y: 20) 

                                        if let statusBinding = externalAnalysisStatus {
                                            AnimatedProcessingText(text: statusBinding.wrappedValue)
                                                .transition(.opacity)
                                                .id("statusText")
                                                .padding(.bottom, 60)
                                        }
                                    }
                                    .offset(y: -20)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .transition(.opacity)
                                .zIndex(50) // Ensure it sits above camera
                            }
                            
                            // Countdown Overlay
                            if isCountingDown {
                                Text("\(countdownValue)")
                                    .font(.system(size: 150, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Timer Selection Click-off
                            if showTimerSelection {
                                Color.black.opacity(0.001)
                                    .onTapGesture { withAnimation { showTimerSelection = false } }
                            }
                            
                            // Settings Overlay
                            if showSettings {
                                ZStack(alignment: .topTrailing) {
                                    Color.black.opacity(0.001).ignoresSafeArea()
                                        .onTapGesture { withAnimation { showSettings = false; currentSettingsPage = .main } }
                                    settingsMenu.transition(.scale.combined(with: .opacity))
                                }
                                .zIndex(100)
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        
                        // Bottom Controls
                        VStack(spacing: 20) {
                            if let recordedURL = cameraManager.recordedVideoURL, !cameraManager.isRecording {
                                // Review / Finish State
                                HStack(spacing: 20) {
                                    Button {
                                        cameraManager.reset()
                                    } label: {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .frame(width: 56, height: 56)
                                            .background(Color.gray)
                                            .clipShape(Circle())
                                            .shadow(radius: 4)
                                    }
                                    
                                    // "Finish / Analyze" Button
                                    if isAnalyzing {
                                         ProgressView()
                                            .tint(.primary)
                                            .frame(maxWidth: .infinity)
                                    } else {
                                        SlideToFinishButton(text: "Slide to Finish") {
                                            withAnimation {
                                                isAnalyzing = true
                                            }
                                            
                                            if externalAnalysisStatus != nil {
                                                // Real Analysis: Pass URL and wait (don't dismiss)
                                                onFinish(.success(recordedURL))
                                            } else {
                                                // Simulated Analysis (Test Mode)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                                    onFinish(.success(recordedURL))
                                                    dismiss()
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(.horizontal, 40)
                                .padding(.bottom, 30)
                            } else {
                                // Setup / Recording State
                                HStack(spacing: 30) {
                                    if !cameraManager.isRecording && !isCountingDown {
                                        // Timer Button
                                        Button {
                                            withAnimation { showTimerSelection.toggle() }
                                        } label: {
                                            VStack(spacing: 2) {
                                                Image(systemName: "timer").font(.title2)
                                                Text(countdownDuration == .off ? "Off" : "\(countdownDuration.rawValue)s")
                                                    .font(.caption).fontWeight(.bold)
                                            }
                                            .foregroundStyle(.white)
                                            .frame(width: 50, height: 50)
                                            .background(Color.black.opacity(0.3))
                                            .clipShape(Circle())
                                        }
                                        .overlay(alignment: .bottom) {
                                            if showTimerSelection {
                                                timerSelectionMenu
                                                    .offset(y: -60)
                                                    .transition(.scale.combined(with: .opacity).animation(.spring(duration: 0.3)))
                                            }
                                        }
                                        .zIndex(100)
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                    
                                    // Record Button
                                    Button {
                                        if cameraManager.isRecording {
                                            cameraManager.stopRecordingTrigger = true
                                        } else if isCountingDown {
                                            cancelCountdown()
                                        } else {
                                            startRecordingSequence()
                                        }
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .stroke(Color.primary.opacity(0.2), lineWidth: 4)
                                                .frame(width: 80, height: 80)
                                            
                                            RoundedRectangle(cornerRadius: cameraManager.isRecording || isCountingDown ? 8 : 40)
                                                .fill(Color.red)
                                                .frame(width: cameraManager.isRecording || isCountingDown ? 32 : 64, height: cameraManager.isRecording || isCountingDown ? 32 : 64)
                                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: cameraManager.isRecording || isCountingDown)
                                        }
                                    }
                                    
                                    if !cameraManager.isRecording && !isCountingDown {
                                        Spacer().frame(width: 50) // Balance spacing
                                    }
                                }
                                .padding(.bottom, 30)
                            }
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                deviceOrientation = UIDevice.current.orientation
            }
            .onAppear {
                deviceOrientation = UIDevice.current.orientation
            }
        }
    }
    
    // MARK: - Helpers
    private var formattedDuration: String {
        let duration = Int(cameraManager.recordingDuration)
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        withAnimation {
            isCountingDown = false
        }
    }
    
    private func startRecordingSequence() {
        if countdownDuration == .off {
            cameraManager.startRecordingTrigger = true
        } else {
            // Start Countdown
            countdownValue = countdownDuration.rawValue
            isCountingDown = true
            
            countdownTask?.cancel()
            countdownTask = Task { @MainActor in
                while countdownValue > 0 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
                    if Task.isCancelled { return }
                    
                    if countdownValue > 1 {
                        withAnimation {
                            countdownValue -= 1
                        }
                    } else {
                        // Done
                        withAnimation {
                            isCountingDown = false
                        }
                        cameraManager.startRecordingTrigger = true
                        return
                    }
                }
            }
        }
    }
    
    // MARK: - Settings Menus
    var timerSelectionMenu: some View {
