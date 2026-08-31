import SwiftUI
import AVFoundation

@MainActor
class VideoTestManager: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var videoFileUrl: URL?
