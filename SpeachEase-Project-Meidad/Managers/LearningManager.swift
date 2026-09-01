import SwiftUI
import Combine

struct Lesson: Identifiable, Codable {
    let id: String
    let title: String
    let icon: String // SF Symbol
    let content: [String] // Pages of text
    let quizQuestion: String
    let quizOptions: [String]
    let correctOptionIndex: Int
}

@MainActor
class LearningManager: ObservableObject {
    static let shared = LearningManager()
    
    @Published var completedLessonIds: Set<String> = []
    
    private let userDefaultsKey = "completedLessonIds"
    
    init() {
        loadProgress()
    }
    
    func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedIds = try? JSONDecoder().decode(Set<String>.self, from: data) {
            completedLessonIds = savedIds
        }
    }
    
    func saveProgress() {
        if let data = try? JSONEncoder().encode(completedLessonIds) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func completeLesson(id: String) {
        withAnimation {
            completedLessonIds.insert(id)
            saveProgress()
        }
    }
    
    func isLessonCompleted(id: String) -> Bool {
        completedLessonIds.contains(id)
    }
    
    // Check if the previous lesson in the list is completed
    func isLessonUnlocked(id: String, allLessons: [Lesson]) -> Bool {

        
        guard let index = allLessons.firstIndex(where: { $0.id == id }) else { return false }
        if index == 0 { return true } // First one always unlocked
        let previousLesson = allLessons[index - 1]
        return isLessonCompleted(id: previousLesson.id)
    }
    
    // Check if the entire section is completed (i.e. the last lesson is done)
    func isSectionCompleted(focus: PracticeFocus) -> Bool {
        guard let lastLesson = lessons(for: focus).last else { return false }
        return isLessonCompleted(id: lastLesson.id)
    }
    
    // Reset all progress (Delete everything)
    func resetAllProgress() {
        withAnimation {
            completedLessonIds.removeAll()
            saveProgress()
        }
    }
    
    // MARK: - Comprehensive Curriculum Generation
    func lessons(for focus: PracticeFocus) -> [Lesson] {
        switch focus {
        case .vocal:
            return [
                Lesson(id: "vocal-1", title: "Breathing Basics", icon: "lungs.fill", content: [
                    "Breath is the fuel for your voice. Without deep breathing, your voice lacks power and stamina.",
                    "Practice 'Diaphragmatic Breathing': Inhale deeply through your nose, letting your belly expand like a balloon. Your shoulders should stay still."
                ], quizQuestion: "Where should you feel the expansion when inhaling for power?", quizOptions: ["In your chest", "In your shoulders", "In your belly (diaphragm)", "In your throat"], correctOptionIndex: 2),
                
                Lesson(id: "vocal-2", title: "Finding Pitch", icon: "music.note", content: [
                    "A monotone voice bores listeners. Varying your pitch keeps them engaged.",
                    "Think of your voice like a melody. Go higher for questions or excitement, and lower for serious statements or conclusions."
                ], quizQuestion: "When is it effective to lower your pitch?", quizOptions: ["When asking a question", "When making a serious point", "When you are excited", "At the start of every sentence"], correctOptionIndex: 1),
                
                Lesson(id: "vocal-3", title: "Warmth & Tone", icon: "sun.max.fill", content: [
                    "Your tone conveys emotion. A 'warm' tone builds trust and connection.",
                    "To sound warmer, smile slightly while speaking (even on the phone!) and relax your jaw. Tension creates a harsh, metallic sound."
                ], quizQuestion: "What physical action helps create a warmer vocal tone?", quizOptions: ["Clenching your fists", "Smiling slightly", "Frowning", "Raising your eyebrows"], correctOptionIndex: 1),
                
                Lesson(id: "vocal-4", title: "Projection 101", icon: "megaphone.fill", content: [
                    "Projection is NOT shouting. Shouting strains your cords; projection uses breath.",
                    "Imagine your voice is a physical object you are throwing to the back row of the room. Aim past your listener."
                ], quizQuestion: "What is the key difference between projection and shouting?", quizOptions: ["Projection is louder", "Projection uses breath support, not strain", "Shouting is better for speeches", "There is no difference"], correctOptionIndex: 1),
                
                Lesson(id: "vocal-5", title: "The Power Pause", icon: "pause.circle", content: [
                    "Silence is loud. Novice speakers rush to fill every second.",
                    "Pause BEFORE a key point to build suspense. Pause AFTER to let it sink in. Count to two in your head."
                ], quizQuestion: "Why should you pause AFTER a key point?", quizOptions: ["To remember what to say next", "To let the audience process the information", "To check your phone", "To take a drink of water"], correctOptionIndex: 1),
                
                Lesson(id: "vocal-6", title: "Articulation", icon: "mouth", content: [
                    "Mumbling kills credibility. Articulation is the crispness of your consonants.",
                    "Practice tongue twisters like 'Red Leather, Yellow Leather'. exaggerate the movement of your lips and tongue."
                ], quizQuestion: "What helps improve articulation?", quizOptions: ["Speaking faster", "Exaggerating lip and tongue movement", "Whispering", "Drinking coffee"], correctOptionIndex: 1),
                
                Lesson(id: "vocal-7", title: "Resonance", icon: "bell.fill", content: [
                    "Resonance makes your voice sound rich and full, not thin or nasal.",
                    "Humming is a great way to find resonance. Feel the vibration in your chest and mask (face), not just your nose."
                ], quizQuestion: "Where should you feel vibration for a resonant voice?", quizOptions: ["Only in the nose", "In the chest and face", "In the throat only", "In the ears"], correctOptionIndex: 1),
                
                Lesson(id: "vocal-8", title: "Pacing Control", icon: "speedometer", content: [
                    "Nervousness usually makes us speed up.",
                    "Practice speaking at half your normal speed during rehearsal. It will feel agonizingly slow, but to an audience, it sounds confident and deliberate."
                ], quizQuestion: "How does nervousness typically affect speaking speed?", quizOptions: ["It makes us slow down", "It has no effect", "It makes us speed up", "It makes us stutter"], correctOptionIndex: 2),
                
                Lesson(id: "vocal-9", title: "Vocal Fry", icon: "waveform.path.ecg", content: [
                    "'Vocal Fry' is that creaky, low rumbling sound at the end of sentences.",
                    "It often signals a lack of breath support or confidence. Push through the end of the sentence with energy."
                ], quizQuestion: "What usually causes 'Vocal Fry'?", quizOptions: ["Too much energy", "Lack of breath support", "Speaking too loudly", "Drinking too much water"], correctOptionIndex: 1),

                Lesson(id: "vocal-10", title: "Vocal Health", icon: "heart.fill", content: [
                    "Your voice is an instrument that needs care.",
                    "Hydrate constantly. Avoid screaming at concerts. If your voice hurts, stop speaking immediately and rest."
                ], quizQuestion: "What should you do if your voice hurts while speaking?", quizOptions: ["Push through it", "Whisper", "Stop and rest immediately", "Drink coffee"], correctOptionIndex: 2)
            ]
            
        case .body:
             return [
                 Lesson(id: "body-1", title: "The Power Stance", icon: "figure.stand", content: [
                     "How you stand affects how you feel (and look).",
                     "Feet shoulder-width apart. Knees slightly soft (not locked). Shoulders back but relaxed. This is the 'Neutral' position of stability."
                 ], quizQuestion: "What is the correct foot placement for a stable stance?", quizOptions: ["Feet touching", "Feet crossed", "Feet shoulder-width apart", "One foot raised"], correctOptionIndex: 2),

                 Lesson(id: "body-2", title: "Open Posture", icon: "arrow.left.and.right", content: [
                     "Crossing arms or legs signals defensiveness or closing off.",
                     "Keep your torso open to the audience. It subconsciously signals 'I have nothing to hide' and builds trust."
                 ], quizQuestion: "What does crossing your arms often signal to an audience?", quizOptions: ["Confidence", "Defensiveness or closing off", "Relaxation", "Intelligence"], correctOptionIndex: 1),

                 Lesson(id: "body-3", title: "Hand Gestures", icon: "hand.raised.fill", content: [
                     "Don't hide your hands in pockets or behind your back.",
                     "Use gestures to emphasize points (e.g., counting on fingers, showing size). When not gesturing, rest hands loosely at your sides."
                 ], quizQuestion: "What is a good use of hand gestures?", quizOptions: ["Fidgeting with a pen", "Hiding them in pockets", "Emphasizing points visually", "Clenching fists"], correctOptionIndex: 2),

                 Lesson(id: "body-4", title: "Eye Contact", icon: "eye.fill", content: [
                     "Scanning the room too fast looks shifty. Staring looks creepy.",
                     "Use the 'One Thought, One Person' rule. Deliver one full sentence to one person, then move to another."
                 ], quizQuestion: "What is the 'One Thought, One Person' rule?", quizOptions: ["Stare at one person for the whole speech", "Look at a new person for each sentence", "Look over everyone's heads", "Close your eyes while thinking"], correctOptionIndex: 1),

                 Lesson(id: "body-5", title: "The Fig Leaf", icon: "leaf.fill", content: [
                     "The 'Fig Leaf' is clasping your hands in front of your groin. It makes you look weak and protective.",
                     "Break the habit. Let your hands hang by your sides despite the urge to cover up."
                 ], quizQuestion: "Why should you avoid the 'Fig Leaf' position?", quizOptions: ["It looks too aggressive", "It signals weakness/protection", "It makes you look too tall", "It hides your tie"], correctOptionIndex: 1),

                 Lesson(id: "body-6", title: "Movement", icon: "figure.walk", content: [
                     "Don't pace like a caged tiger. Move with purpose.",
                     "Move to a new spot on stage to signal a transition to a new topic. Then plant your feet."
                 ], quizQuestion: "When should you move on stage?", quizOptions: ["Constantly to stay active", "When transitioning to a new topic", "When you are nervous", "Never"], correctOptionIndex: 1),

                 Lesson(id: "body-7", title: "Facial Expressions", icon: "face.smiling", content: [
                     "Your face must match your message. Don't deliver tragic news with a smile.",
                     "Practice in a mirror. Does your 'serious' face look angry? Does your 'happy' face reach your eyes?"
                 ], quizQuestion: "Why is mirror practice important for facial expressions?", quizOptions: ["To admire yourself", "To ensure your face matches your message", "To count your teeth", "To fix your hair"], correctOptionIndex: 1),

                 Lesson(id: "body-8", title: "Nervous Tics", icon: "bolt.fill", content: [
                     "We all have tics: fixing hair, adjusting glasses, swaying.",
                     "Record yourself to identify them. Awareness is 90% of the cure. Once you see it, you can stop it."
                 ], quizQuestion: "What is the best way to identify your unconscious nervous tics?", quizOptions: ["Ask your mom", "Record a video of yourself speaking", "Guess", "Ignore them"], correctOptionIndex: 1),

                 Lesson(id: "body-9", title: "Lean In", icon: "arrow.forward", content: [
                     "Leaning back can signal disinterest or arrogance.",
                     "Lean slightly forward (even on Zoom) to signal engagement and interest in your audience."
                 ], quizQuestion: "What does leaning slightly forward signal?", quizOptions: ["Aggression", "Engagement and interest", "Back pain", "Sleepiness"], correctOptionIndex: 1),
                 
                 Lesson(id: "body-10", title: "The Superhero", icon: "star.circle.fill", content: [
                     "Amy Cuddy's research suggests 'Power Posing' changes your hormones.",
                     "Before a big speech, stand like Wonder Woman or Superman for 2 minutes. It boosts testosterone (confidence) and lowers cortisol (stress)."
                 ], quizQuestion: "What is the purpose of 'Power Posing' before a speech?", quizOptions: ["To look cool", "To stretch your muscles", "To boost confidence hormones", "To practice for a movie role"], correctOptionIndex: 2)
             ]
             
