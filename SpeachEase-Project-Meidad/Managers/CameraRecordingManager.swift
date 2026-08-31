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
    
    init() {
        loadColors()
    }
    
    // MARK: - Themes
    struct CameraTheme: Identifiable {
        let id = UUID()
        let name: String
        let hand: Color
        let body: Color
        let face: Color
        
        static let themes: [CameraTheme] = [
            // Dark / Stealth
            CameraTheme(name: "Midnight", hand: Color.black, body: Color(white: 0.2), face: Color(white: 0.4)),

            // Light / Airy
            CameraTheme(name: "Cloud", hand: Color.white, body: Color(white: 0.9), face: Color(white: 0.8)),

            // Girly Pop / Fun
            CameraTheme(name: "Girly Pop", hand: Color(red: 1.0, green: 0.7, blue: 0.8), body: Color(red: 0.8, green: 0.6, blue: 1.0), face: .white),
            CameraTheme(name: "Barbie", hand: .pink, body: .white, face: Color(red: 1.0, green: 0.4, blue: 0.7)),
            CameraTheme(name: "Fairy", hand: Color(red: 0.8, green: 1.0, blue: 0.8), body: Color(red: 1.0, green: 0.8, blue: 0.9), face: Color(red: 0.8, green: 0.8, blue: 1.0)),
            CameraTheme(name: "Sparkle", hand: Color.yellow.opacity(0.8), body: Color.cyan.opacity(0.7), face: Color.pink.opacity(0.7)),

            // Classic / Traffic
            CameraTheme(name: "Traffic", hand: .green, body: .yellow, face: .red),
            CameraTheme(name: "Signal", hand: .red, body: .orange, face: .green),
            CameraTheme(name: "Stoplight", hand: .green, body: .red, face: .orange),

            // Vibrant / Pop
            CameraTheme(name: "Berry", hand: .pink, body: .purple, face: .white),
            CameraTheme(name: "Sunset", hand: .orange, body: .yellow, face: .blue),
            CameraTheme(name: "Ocean", hand: .blue, body: .cyan, face: .white),
            CameraTheme(name: "Forest", hand: .green, body: .brown, face: .yellow),
            CameraTheme(name: "Candy", hand: .cyan, body: .pink, face: .yellow),
            CameraTheme(name: "Neon", hand: .green, body: .pink, face: .orange),
            CameraTheme(name: "Cyber", hand: .cyan, body: .purple, face: .brown),
            
            // Pastel / Soft
            CameraTheme(name: "Cotton Candy", hand: .blue.opacity(0.5), body: .pink.opacity(0.5), face: .white),
            CameraTheme(name: "Mint", hand: .green.opacity(0.6), body: .cyan.opacity(0.6), face: .white),
            CameraTheme(name: "Lavender", hand: .purple.opacity(0.6), body: .blue.opacity(0.4), face: .white),
            CameraTheme(name: "Peach", hand: .orange.opacity(0.6), body: .pink.opacity(0.6), face: .yellow.opacity(0.6)),
            CameraTheme(name: "Sky", hand: .blue.opacity(0.5), body: .white, face: .cyan.opacity(0.5)),

            // Earth / Nature
            CameraTheme(name: "Earth", hand: .green, body: .brown, face: .blue),
            CameraTheme(name: "Sand", hand: .yellow, body: .orange, face: .brown),
            CameraTheme(name: "Stone", hand: .gray, body: Color(white: 0.3), face: Color(white: 0.6)),
            CameraTheme(name: "Fire", hand: .red, body: .orange, face: .yellow),
            CameraTheme(name: "Ice", hand: .cyan, body: .blue, face: .white),
            
            // Exotic
            CameraTheme(name: "Royalty", hand: .purple, body: .yellow, face: .white),
            CameraTheme(name: "Toxic", hand: .green, body: .purple, face: .orange),
            CameraTheme(name: "Retro", hand: .orange, body: .brown, face: .cyan),
            CameraTheme(name: "Matrix", hand: .green, body: Color(white: 0.1), face: .green.opacity(0.5)),
            CameraTheme(name: "Vampire", hand: .red, body: .black, face: .white),
            CameraTheme(name: "Gold", hand: .yellow, body: .orange, face: .white),
            CameraTheme(name: "Silver", hand: .gray, body: .white, face: Color(white: 0.8))
        ]
    }
    
    func applyTheme(_ theme: CameraTheme) {
