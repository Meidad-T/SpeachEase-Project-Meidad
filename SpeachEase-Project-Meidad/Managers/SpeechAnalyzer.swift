import Foundation
import Speech
import NaturalLanguage
import AVFoundation
import SwiftUI

struct SpeechReport: Codable {
    var overallScore: Int
    var pacingScore: Double
    var vocabularyScore: Double
    var toneScore: Double
    var engagementScore: Double
    var pauseScore: Double
    var feedback: String
    var insights: [SpeechInsight] = []
    var narrativeReport: String?
    var detailedAnalysis: String? // Markdown content for deep dive
    
    // Video Analysis (Optional)
    var bodyLanguageScore: Double?
    var eyeContactScore: Double?
    var visualInsights: [SpeechInsight]?
    
    // Strict Mode
    var isStrictViolation: Bool = false
    var strictTimeLimit: TimeInterval? = nil
}

// MARK: - Data Structures
struct SpeechInsight: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let timestamp: TimeInterval
    let type: InsightType
}

enum InsightType: String, Codable {
    case positive
    case negative
    case neutral
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .positive: return "checkmark.circle.fill"
        case .negative: return "exclamationmark.triangle.fill"
        case .neutral: return "info.circle.fill"
        }
    }
}

@MainActor
class SpeechAnalyzer: ObservableObject {
    
    func analyze(
        transcript: SFTranscription,
        audioFile: URL,
        timeLimit: TimeInterval? = nil,
        enforceStrict: Bool = false,
        onProgress: @escaping (String) -> Void = { _ in }
    ) async -> SpeechReport {
        
        // --- STRICT MODE LOGIC ---
        var analysisSegments = transcript.segments
        var analysisText = transcript.formattedString
