import SwiftUI

struct AnalyzingView: View {
    @State private var logText: String = ""
    @State private var currentStepIndex = 0
    @State private var timer: Timer?
    @State private var scale: CGFloat = 1.0
    
    // Passed from parent
    var statusMessage: String // "Reading...", "Analyzing..."
    
    private let steps = [
        "Initializing Audio Engine...",
        "Extracting Phonemes...",
        "Analyzing Pitch Variance...",
        "Detecting Filler Words...",
        "Measuring Speech Rate...",
        "Evaluating Emotional Tone...",
        "Compiling Insights...",
        "Finalizing Report..."
    ]
    
