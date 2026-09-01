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
