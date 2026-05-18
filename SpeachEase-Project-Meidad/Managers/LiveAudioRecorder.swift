import SwiftUI
import AVFoundation

@MainActor
class LiveAudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var duration: TimeInterval = 0
    @Published var audioLevel: Float = 0
    
    // Standard Recorder Only (No Engine)
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var recordingURL: URL?
    
    override init() {
        super.init()
    }
    
    func prepare() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Session error: \(error)")
        }
    }
    
    func startRecording() {
        // 1. Path
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docDir.appendingPathComponent("live_rec_\(Date().timeIntervalSince1970).m4a")
        self.recordingURL = url
        
        // 2. Settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            let newRecorder = try AVAudioRecorder(url: url, settings: settings)
            newRecorder.delegate = self
            newRecorder.isMeteringEnabled = true
            
            if newRecorder.record() {
                self.audioRecorder = newRecorder
                self.isRecording = true
                self.startTimer()
            }
        } catch {
            print("Recording failed: \(error)")
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        timer?.invalidate()
        let url = recordingURL
        recordingURL = nil
        return url
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let rec = self.audioRecorder else { return }
                
                // 1. Update Duration
                self.duration = rec.currentTime
                
                // 2. Update Metering for UI (Safe)
                rec.updateMeters()
                let power = rec.averagePower(forChannel: 0) // -160 ... 0
                
                // Normalize for visualizer (roughly -50db to 0db mapped to 0...1)
                let minDb: Float = -50.0
                let normalized = max(0.0, (power - minDb) / (0 - minDb))
                self.audioLevel = normalized
            }
        }
    }
}
