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
