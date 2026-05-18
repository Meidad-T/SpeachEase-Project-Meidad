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
             
        case .interview:
             return [
                 Lesson(id: "int-1", title: "Research First", icon: "magnifyingglass", content: [
                     "Never walk into an interview blind.",
                     "Research the company's mission, recent news, and the interviewer's background. It allows you to ask targeted, smart questions."
                 ], quizQuestion: "Why should you research the interviewer?", quizOptions: ["To stalk them", "To ask targeted, smart questions", "To find their home address", "To verify their age"], correctOptionIndex: 1),

                 Lesson(id: "int-2", title: "Elevator Pitch", icon: "timer", content: [
                     "'Tell me about yourself' is not an invitation to recite your biography.",
                     "Keep it to 2 minutes: Past (Overview), Present (Current Role), and Future (Why you are here)."
                 ], quizQuestion: "What is a good structure for 'Tell me about yourself'?", quizOptions: ["Childhood -> School -> Now", "Past -> Present -> Future", "Listing every job you've had", "Just your hobbies"], correctOptionIndex: 1),

                 Lesson(id: "int-3", title: "The STAR Method", icon: "star.fill", content: [
                     "For behavioral questions ('Tell me about a time...'), use STAR.",
                     "Situation (Context), Task (Challenge), Action (What YOU did), Result (Outcome). Focus heavily on the Action and Result."
                 ], quizQuestion: "Which part of STAR should you focus on most?", quizOptions: ["Situation", "Task", "Action and Result", "None of them"], correctOptionIndex: 2),

                 Lesson(id: "int-4", title: "Weaknesses", icon: "exclamationmark.triangle", content: [
                     "Don't say 'I work too hard' (it's a cliché) or 'I'm lazy' (it's fatal).",
                     "Choose a real weakness that isn't critical to the job, and show how you are actively working to improve it."
                 ], quizQuestion: "What makes a good answer for 'What is your weakness'?", quizOptions: ["A generic cliché", "A fatal flaw", "A real weakness with an improvement plan", "Denying you have any"], correctOptionIndex: 2),

                 Lesson(id: "int-5", title: "Questions to Ask", icon: "questionmark.circle", content: [
                     "At the end, never say 'I have no questions'.",
                     "Ask about team culture, challenges they face, or what success looks like in this role. It shows you are thinking critically."
                 ], quizQuestion: "What does asking questions at the end show?", quizOptions: ["That you weren't listening", "Critical thinking and genuine interest", "That you are confused", "Nothing"], correctOptionIndex: 1),

                 Lesson(id: "int-6", title: "Body Language", icon: "figure.seated.side", content: [
                     "In an interview, mirror the energy of your interviewer.",
                     "Sit up straight, make eye contact, and don't fidget. If they lean in, you lean in."
                 ], quizQuestion: "What is 'mirroring' in an interview context?", quizOptions: ["Copying every move exactly", "Matching their energy and posture", "Using a literal mirror", "Repeating their words back"], correctOptionIndex: 1),
                 
                 Lesson(id: "int-7", title: "Zoom Etiquette", icon: "video.fill", content: [
                     "For virtual interviews, look at the CAMERA, not the screen.",
                     "Eye contact happens through the lens. Use a simple background and ensure good lighting (light in front of you, not behind)."
                 ], quizQuestion: "Where should you look during a Zoom interview to make eye contact?", quizOptions: ["The screen", "The keyboard", "The camera lens", "Your own reflection"], correctOptionIndex: 2),

                 Lesson(id: "int-8", title: "Salary Talk", icon: "dollarsign.circle", content: [
                     "Don't bring up salary in the first screening unless asked.",
                     "If asked for a number, give a range based on market research, or ask 'What is the budget for this role?'"
                 ], quizQuestion: "What is a good strategy when asked for salary expectations?", quizOptions: ["Give a specific low number", "Give a researched range", "Refuse to answer", "Ask for a million dollars"], correctOptionIndex: 1),
                 
                 Lesson(id: "int-9", title: "The Follow-Up", icon: "envelope.fill", content: [
                     "Send a Thank You email within 24 hours.",
                     "Personalize it. Mention something specific you discussed to show you were paying attention."
                 ], quizQuestion: "When should you send a Thank You email?", quizOptions: ["Within 24 hours", "Next week", "Before the interview", "Never"], correctOptionIndex: 0),
                 
                 Lesson(id: "int-10", title: "Handling Rejection", icon: "arrow.turn.up.forward.iphone", content: [
                     "Rejection is not failure; it's redirection.",
                     "Ask for feedback politely. Even if they don't hire you now, a graceful exit keeps the door open for future opportunities."
                 ], quizQuestion: "Why should you ask for feedback after a rejection?", quizOptions: ["To argue with them", "To learn and keep the door open", "To make them feel guilty", "To sue them"], correctOptionIndex: 1)
             ]
             
        case .vocab:
            return [
                Lesson(id: "vocab-1", title: "Killer Fillers", icon: "scissors", content: [
                    "Filler words like 'um', 'like', and 'basically' dilute your message.",
                    "They usually happen when your brain is searching for a word. Train yourself to just PAUSE instead."
                ], quizQuestion: "What should you do instead of saying 'um'?", quizOptions: ["Say 'like'", "Pause silently", "Cough", "Apologize"], correctOptionIndex: 1),
                
                Lesson(id: "vocab-2", title: "Power Verbs", icon: "bolt.fill", content: [
                    "Weak verbs need adverbs (e.g., 'ran quickly'). Power verbs stand alone (e.g., 'sprinted').",
                    "Replace 'talked about' with 'discussed', 'debate', or 'outlined'. Be precise."
                ], quizQuestion: "Which is a 'Power Verb'?", quizOptions: ["Walked slowly", "Looked at", "Scrutinized", "Said"], correctOptionIndex: 2),
                
                Lesson(id: "vocab-3", title: "Jargon Busting", icon: "hammer.fill", content: [
                    "Jargon alienates anyone who isn't an expert.",
                    "Explain complex concepts in simple terms (The Feynman Technique). If an 8-year-old wouldn't get it, simplify it."
                ], quizQuestion: "Why should you avoid heavy jargon?", quizOptions: ["It makes you look smart", "It alienates non-experts", "It is required for business", "It uses more words"], correctOptionIndex: 1),
                
                Lesson(id: "vocab-4", title: "The Rule of Three", icon: "3.circle.fill", content: [
                    "The human brain loves patterns of three (e.g., 'Life, Liberty, and the pursuit of Happiness').",
                    "Group your points, lists, or adjectives in threes for maximum memorability."
                ], quizQuestion: "Why is the Rule of Three effective?", quizOptions: ["It's a magic number", "It's memorable and rhythmic", "It's odd", "It's shorter than two"], correctOptionIndex: 1),
                
                Lesson(id: "vocab-5", title: "Active vs Passive", icon: "arrow.right.circle.fill", content: [
                    "Passive voice: 'The ball was thrown by John.' Active voice: 'John threw the ball.'",
                    "Active voice is stronger, clearer, and shorter. Use it for impact."
                ], quizQuestion: "Which sentence is in Active Voice?", quizOptions: ["Mistakes were made", "The report was written by me", "I wrote the report", "It was decided"], correctOptionIndex: 2),
                
                Lesson(id: "vocab-6", title: "Metaphors", icon: "paintpalette.fill", content: [
                    "Metaphors create pictures in the listener's mind.",
                    "Don't just say 'it's complicated'. Say 'it's a tangled knot'. Imagery sticks."
                ], quizQuestion: "What is the primary benefit of using metaphors?", quizOptions: ["They sound poetic", "They create visual imagery/understanding", "They confuse people", "They take longer to explain"], correctOptionIndex: 1),
                
                Lesson(id: "vocab-7", title: "Conciseness", icon: "arrow.down.right.and.arrow.up.left", content: [
                    "If you can say it in 5 words, don't use 10.",
                    "Edit your speech. Cut 'I think that', 'sort of', 'in my opinion'. Just state the fact."
                ], quizQuestion: "What phrase dilutes your message?", quizOptions: ["I will", "Sort of", "Therefore", "However"], correctOptionIndex: 1),
                
                Lesson(id: "vocab-8", title: "Transition Words", icon: "link", content: [
                    "Don't jump abruptly between topics. Use bridges.",
                    "Words like 'Consequently', 'However', 'Furthermore', and 'On the other hand' guide the listener safely to your next point."
                ], quizQuestion: "What is the purpose of transition words?", quizOptions: ["To sound smart", "To connect ideas smoothly", "To fill time", "To confuse the audience"], correctOptionIndex: 1),
                
                Lesson(id: "vocab-9", title: "Sensory Language", icon: "nose.fill", content: [
                    "Engage the senses. Don't just explain logic; verify how it FEELS, LOOKS, or SOUNDS.",
                    "Instead of 'it was a bad day', say 'it was a heavy, grinding day'."
                ], quizQuestion: "What does sensory language appeal to?", quizOptions: ["Logic only", "Sight, sound, touch, etc.", "Math skills", "Grammar"], correctOptionIndex: 1),
                
                Lesson(id: "vocab-10", title: "Audience Adaptation", icon: "person.2.wave.2.fill", content: [
                    "Vocabulary is not one-size-fits-all.",
                    "You speak differently to a Board of Directors than to a kindergarten class. Adapt your complexity to your audience."
                ], quizQuestion: "What is the most important factor in choosing vocabulary?", quizOptions: ["Showing off", "The dictionary size", "The audience", "The length of words"], correctOptionIndex: 2)
            ]
            
        default:
             // Generate generic but meaningful structure for others to avoid crash
            return (1...10).map { i in
                Lesson(
                    id: "\(focus.rawValue)-\(i)",
                    title: "\(focus.title) Step \(i)",
                    icon: focus.icon,
                    content: ["This is a focused lesson on \(focus.title). Keep practicing!"],
                    quizQuestion: "Are you improving?",
                    quizOptions: ["Yes!", "Not yet"],
                    correctOptionIndex: 0
                )
            }
        }
    }
}
