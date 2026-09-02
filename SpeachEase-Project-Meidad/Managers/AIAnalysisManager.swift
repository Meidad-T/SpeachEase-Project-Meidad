import Foundation
import SwiftUI

// MARK: - AI Manager
@MainActor
class AIAnalysisManager: ObservableObject {
    static let shared = AIAnalysisManager()
    
    // In a real app, this should be in Keychain or Settings
    // For this Playground, we'll likely need a manual input or just a placeholder
    // If empty, we use the advanced local simulation (Wizard of Oz style for smooth demo)
    @AppStorage("gemini_api_key") var apiKey: String = ""
    
    // MARK: - Public Interface
    
    func performAnalysis(
        transcript: String,
        metrics: SpeechMetrics, // Struct defined below
        onUpdate: @escaping (String) -> Void // Callback for typewriter effect "thinking" logs
    ) async -> SpeechReport {
        
        // 1. Simulate "Reading" delay
        onUpdate("Reading transcript...")
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        // 2. Simulate "Analyzing" delay
        onUpdate("Analyzing pacing and tone...")
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        
        // 3. AI Call or Fallback
        if !apiKey.isEmpty {
            onUpdate("Connecting to AI Brain...")
            do {
                return try await fetchGeminiAnalysis(transcript: transcript, metrics: metrics)
            } catch {
                print("AI Error: \(error). Falling back to local.")
                onUpdate("AI busy. Using local expert...")
                return await generateLocalReport(metrics: metrics)
            }
        } else {
            onUpdate("Generating insights...")
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return await generateLocalReport(metrics: metrics)
        }
    }
    
    // MARK: - Internal Logic (Local Fallback)
    
    private func generateLocalReport(metrics: SpeechMetrics) async -> SpeechReport {
        // Use the existing purely heuristic logic but wrapped in a "SpeechReport"
        // This effectively delegates back to the logic we had, but we spice up the text descriptions
        
        var report = SpeechReport(
            overallScore: metrics.overallScore,
            pacingScore: metrics.pacingScore,
            vocabularyScore: metrics.vocabularyScore,
            toneScore: metrics.toneScore,
            engagementScore: metrics.engagementScore,
            pauseScore: metrics.pauseScore,
            feedback: "", // Will generate below
            insights: metrics.insights,
            narrativeReport: "" // Will generate below
        )
        
        // Generate Better Text using Templates
        report.feedback = generateHeadline(score: metrics.overallScore)
        report.narrativeReport = generateNarrative(metrics: metrics)
        report.detailedAnalysis = generateDeepDive(metrics: metrics, transcript: "")
        
        return report
    }
    
    // MARK: - API Logic (Gemini)
    
    private func fetchGeminiAnalysis(transcript: String, metrics: SpeechMetrics) async throws -> SpeechReport {
        // TODO: Implement actual HTTP Request to Gemini API
        // For now, we will throw to force fallback, or implement a mock if user provides key later.
        // The structure would be:
        // POST https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=YOUR_API_KEY
        // Body: { "contents": [{ "parts": [{ "text": PROMPT }] }] }
        
        // Since we cannot rely on external network in all Swift Playgrounds without permission configuration,
        // and to keep it robust:
        throw NSError(domain: "AI", code: 404, userInfo: [NSLocalizedDescriptionKey: "API not implemented in this step"])
    }
    
    // MARK: - Helpers
    
    private func generateHeadline(score: Int) -> String {
        switch score {
        case 95...100: return "Outstanding! TED Talk Ready."
        case 85..<95: return "Excellent Delivery. Very Polished."
        case 75..<85: return "Great Job. A Few Refinements Needed."
        case 60..<75: return "Good Effort. Focus on Flow."
        default: return "Keep Practicing. You're Improving."
        }
    }
    
    private func generateNarrative(metrics: SpeechMetrics) -> String {
        // Short Summary (1-2 lines max)
        var narrative = "Your pacing (\(Int(metrics.pacingWPM)) WPM) "
        if metrics.pacingWPM > 160 {
            narrative += "was quite fast, which reduced clarity. "
        } else if metrics.pacingWPM < 110 {
            narrative += "was a bit slow, lacking energy. "
        } else {
            narrative += "was excellent and easy to follow. "
        }
        
        if metrics.toneScore > 80 {
            narrative += "Combined with your engaging tone, this was a strong performance."
        } else {
             narrative += "Try adding more vocal variety to keep the listener hooked."
        }
        return narrative
    }
    
    private func generateDeepDive(metrics: SpeechMetrics, transcript: String) -> String {
        return """
        # Detailed Analysis
        
        ## ⏱️ Pacing & Flow
        You spoke at an average of **\(Int(metrics.pacingWPM)) words per minute**.
        \(metrics.pacingWPM > 160 ? "- **Issue**: High speed can make complex ideas hard to grasp.\n- **Tip**: Slow down on key transitions." : "- **Strength**: Your pace allows the audience to digest information.")
        
        ## 🗣️ Tone & Delivery
        Your tone variance score was **\(Int(metrics.toneScore))/100**.
