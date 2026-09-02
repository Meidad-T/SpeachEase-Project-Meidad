import SwiftUI
import AVFoundation

struct CameraTestView: View {
    @StateObject private var cameraManager = CameraRecordingManager()
    @State private var analysisReport: CameraBodyLanguageReport?
    @State private var isAnalyzing = false
    @State private var showAnalysis = false
    @State private var showSettings = false
    
    // Navigation State for Settings
    enum SettingsPage {
        case main
        case motion
        case themes // New page
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
    
    @State private var deviceOrientation: UIDeviceOrientation = .portrait

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Use system background (dynamic)
                Color(uiColor: .systemBackground).ignoresSafeArea()
                
                let isUpsideDown = deviceOrientation == .portraitUpsideDown
                let isLandscape = geo.size.width > geo.size.height
                
                if isLandscape || isUpsideDown {
                    // LANDSCAPE OR UPSIDE DOWN DETECTED - LOCK SCREEN
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
                            
                            Text(isUpsideDown ? "Please turn your device right side up." : "The Camera Test requires Portrait mode\nfor accurate body language analysis.")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
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
                                    Text("Camera Test")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
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
                                    Color.black.opacity(0.7)
                                    GrainOverlay().opacity(0.2).blendMode(.overlay)
                                    LottieView(filename: "video-processing").frame(width: 375, height: 375)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .transition(.opacity)
                            }
                            
                            if isCountingDown {
                                Text("\(countdownValue)")
                                    .font(.system(size: 150, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
                            if showTimerSelection {
                                Color.black.opacity(0.001)
                                    .onTapGesture { withAnimation { showTimerSelection = false } }
                            }
                            
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
                                    
                                    if isAnalyzing {
                                        ProgressView().tint(.primary).frame(maxWidth: .infinity)
                                    } else {
                                        SlideToAnalyzeButton { performAnalysis(url: recordedURL) }
                                            .frame(maxWidth: .infinity)
                                            .disabled(isAnalyzing)
                                    }
                                }
                                .padding(.horizontal, 40)
                                .padding(.bottom, 30)
                            } else {
                                HStack(spacing: 30) {
                                    if !cameraManager.isRecording && !isCountingDown {
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
                                        Spacer().frame(width: 50)
                                    }
                                }
                                .padding(.bottom, 30)
                            }
                        }
                    }
                }
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showAnalysis) {
                if let report = analysisReport {
                    CameraAnalysisResultView(report: report)
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
    
    @State private var countdownTask: Task<Void, Never>?

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
        VStack(spacing: 0) {
            ForEach(CountdownOption.allCases, id: \.self) { option in
                Button {
                    withAnimation {
                        countdownDuration = option
                        showTimerSelection = false
                    }
                } label: {
                    HStack {
                        Text(option.display)
                            .fontWeight(countdownDuration == option ? .bold : .regular)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if countdownDuration == option {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .background(Color.primary.opacity(0.05)) // Subtle highlight
                }
                
                if option != CountdownOption.allCases.last {
                    Divider()
                }
            }
        }
        .frame(width: 150)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
    }
    
    var settingsMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Header (Back button if deep)
            if currentSettingsPage != .main {
                Button {
                    withAnimation {
                        // Back logic
                        if currentSettingsPage == .themes {
                            currentSettingsPage = .motion
                        } else {
                            currentSettingsPage = .main
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                }
                .padding(.bottom, 10)
            } else {
                Text("Settings")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding(.bottom, 10)
            }
            
            Divider().padding(.bottom, 10)
            
            switch currentSettingsPage {
            case .main:
                // Main Menu
                VStack(spacing: 8) {
                    settingsRow(title: "Motion Visualizers", icon: "hand.raised.fill", color: .purple) {
                        currentSettingsPage = .motion
                    }
                    
                    settingsRow(title: "Audio", icon: "mic.fill", color: .blue) {
                        currentSettingsPage = .audio
                    }
                }
                
            case .motion:
                // Motion Sub-menu
                VStack(alignment: .leading, spacing: 16) {
                    Text("Motion Visualizers")
                        .font(.headline)
                    
                    // Toggles
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Hand Lines", isOn: $cameraManager.showHandLines)
                            .tint(Color("AccentColor"))
