import SwiftUI
import Combine
import AVFoundation

@MainActor
class VideoTestManager: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var videoFileUrl: URL?
    
    func loadVideo(url: URL) {
        // Reset state
        self.errorMessage = nil
        
        Task {
            let tempDir = FileManager.default.temporaryDirectory
            let tempUrl = tempDir.appendingPathComponent(url.lastPathComponent)
            
            do {
                // Perform file operations in background
                try await Task.detached(priority: .userInitiated) {
                    // Remove existing if any
                    if FileManager.default.fileExists(atPath: tempUrl.path) {
                        try FileManager.default.removeItem(at: tempUrl)
                    }
                    
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        try FileManager.default.copyItem(at: url, to: tempUrl)
                    } else {
                        try FileManager.default.copyItem(at: url, to: tempUrl)
                    }
                }.value
                
                // Update state on MainActor
                self.videoFileUrl = tempUrl
                
            } catch {
                print("File copy failed: \(error.localizedDescription)")
                self.errorMessage = "Failed to load video: \(error.localizedDescription)"
            }
        }
    }
}
