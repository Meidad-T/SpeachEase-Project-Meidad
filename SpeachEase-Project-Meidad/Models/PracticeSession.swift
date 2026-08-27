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
    }
    
    // Using string representation for Codable colors if strictly needed,
    // but usually in a focus enum we just compute it.
    // However, the user wants "choose a color (if we dont, choose one for us)"
    // The focus implies a default color, but the user might override it?
    // The prompt says "choose between any of the things we have in the explore page... make sure these options are the same colors"
    // So the focus DETERMINES the color initially.
    var defaultColor: Color {
        switch self {
        case .vocal: return .green
        case .body: return .blue
        case .interview: return .orange
        case .pacing: return .pink
        case .facial: return .purple
        case .vocab: return .yellow
        case .eye: return .teal
        }
    }
    
    var description: String {
        switch self {
        case .vocal:
            return """
            Mastering vocal control is the foundation of powerful communication. It's not just about what you say, but how you say it. By learning to modulate your pitch, you can keep listeners engaged and emphasize key points effectively, avoiding the monotony that causes audiences to tune out.
            
            Proper tone conveys emotion and intent. Whether you need to sound authoritative, empathetic, or enthusiastic, your voice is the instrument that delivers that message. Regular practice in this area helps you find your natural resonance and project confidence in any setting.
            """
        case .body:
            return """
            Body language speaks before you say a word. Your posture, gestures, and overall physical presence communicate confidence, openness, and authority. A strong stance can make you feel more powerful, while appropriate hand gestures can help illustrate your ideas and make your storytelling more dynamic.
            
            Understanding body language also helps you read the room. By being aware of non-verbal cues, you can adjust your delivery to better connect with your audience. This section focuses on eliminating nervous tics and cultivating a presence that commands respect and attention.
            """
        case .interview:
            return """
            Interviews are high-stakes conversations where preparation is key. This isn't just about memorizing answers, but about developing the ability to think on your feet and structure your thoughts logically under pressure.
            
            We focus on the STAR method (Situation, Task, Action, Result) to tell compelling stories about your achievements. You'll also learn how to handle difficult questions with grace and turn potential weaknesses into opportunities to demonstrate learning and growth.
            """
        case .pacing:
            return """
            The speed at which you speak significantly impacts comprehension. Speak too fast, and your audience leads; speak too slow, and they lose interest. Mastering pacing involves finding a comfortable rhythm that allows your listeners to absorb your message.
            
            Strategic pauses are a superpower in public speaking. They give your audience time to reflect on a powerful statement and give you a moment to collect your next thought. This section trains you to use silence as effectively as you use words.
            """
        case .facial:
            return """
            Your face is the primary focal point for your audience. Micro-expressions can reveal nervousness or uncertainty even if your voice is steady. Learning to control your facial expressions ensures that your visual cues align with your verbal message.
            
            A genuine smile or a furrowed brow can drastically change the meaning of a sentence. We work on developing an expressive range that feels authentic to you, helping you connect emotionally with your listeners and appear more approachable and trustworthy.
            """
        case .vocab:
            return """
            A rich vocabulary allows you to express complex ideas with precision and clarity. It’s not about using big words to sound smart, but about choosing the *right* word to paint a vivid picture in your listener's mind.
            
            This section helps you expand your active vocabulary and eliminate filler words like "um," "like," and "you know" that dilute your message. You will learn to speak more concisely and persuasively, ensuring every word earns its place in your sentence.
            """
        case .eye:
            return """
            Eye contact is the strongest way to build a connection with your audience. It signals honesty, confidence, and interest. Avoiding eye contact can make you appear shifty or insecure, while staring can be aggressive.
            
            The goal is to maintain natural, engaging eye contact that makes every person in the room feel like you are speaking directly to them. We practice techniques to scan the room effectively and hold gaze just long enough to establish a bond without making it uncomfortable.
            """

        }
    }
    
    var highlightTitle: String {
        switch self {
        case .vocal: return "The Power of Pause"
        case .body: return "Power Posing"
        case .interview: return "The STAR Method"
        case .pacing: return "The 3-Second Rule"
        case .facial: return "The Duchenne Smile"
        case .vocab: return "Rule of Three"
        case .eye: return "The Lighthouse Technique"
        }
    }
    
    var highlightDescription: String {
        switch self {
        case .vocal: return "Silence is loud. Use it to let big ideas land."
        case .body: return "Stand like a superhero for 2 mins to boost confidence!"
        case .interview: return "Situation. Task. Action. Result. Your secret weapon."
        case .pacing: return "Count to three before answering. Own the time."
        case .facial: return "Real smiles reach your eyes. Fake ones don't."
        case .vocab: return "People remember things in threes. Use it."
        case .eye: return "Scan the room like a lighthouse, don't stare."
        }
    }
}

// Simple Color Codable wrapper or just save RGB components
struct SavedColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    init(_ color: Color) {
        // Need to extract components from Color. This is tricky in pure SwiftUI without UI/NSColor.
        // For simplicity, we'll assume we can serialize standard colors or just specific ones.
        // If the user picks a custom color, we might need a better way.
        // For now, let's just implement a basic initializer that might default if extraction fails,
        // or rely on predefined colors.
        // Actually, converting to UIColor/NSColor is safer for component extraction.
        
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }
