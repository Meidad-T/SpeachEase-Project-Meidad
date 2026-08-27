import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
typealias UIColor = NSColor
#endif

enum PracticeFocus: String, CaseIterable, Codable, Identifiable {
    case vocal
    case body
    case interview
    case pacing
    case facial
    case vocab
    case eye
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .vocal: return "Vocal Control"
        case .body: return "Body Language"
        case .interview: return "Interview Prep"
        case .pacing: return "Pacing"
        case .facial: return "Facial Aesthetics"
        case .vocab: return "Vocabulary"
        case .eye: return "Eye Contact"
        }
    }
    
    var subtitle: String {
        switch self {
        case .vocal: return "Pitch & Tone"
        case .body: return "Posture & Gestures"
        case .interview: return "Q&A Strategies"
        case .pacing: return "Speed & Pauses"
        case .facial: return "Expressions"
        case .vocab: return "Word Choice"
        case .eye: return "Engagement"
        }
    }
    
    var icon: String {
        switch self {
        case .vocal: return "mic.fill"
        case .body: return "figure.stand"
        case .interview: return "briefcase.fill"
        case .pacing: return "speedometer"
        case .facial: return "mouth"
        case .vocab: return "text.book.closed.fill"
        case .eye: return "eye.fill"
        }
    }
    
    var requiresVideo: Bool {
        switch self {
        case .body, .facial, .eye, .interview:
            return true
        case .vocal, .pacing, .vocab:
            return false
        }
