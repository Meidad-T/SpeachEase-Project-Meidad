import SwiftUI

struct LessonView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var learningManager = LearningManager.shared
    @StateObject private var speakerManager = SpeakerManager.shared
    
    let lesson: Lesson
    let focusColor: Color
    
    @State private var currentPage = 0
    @State private var isQuizMode = false
    @State private var selectedOption: Int? = nil
    @State private var isCompleted = false
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                    
                    Spacer()
                    
                    // Progress Bar
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            // Calculate progress based on pages + quiz
                            let totalSteps = Double(lesson.content.count + 1)
                            let currentStep = Double(currentPage + (isQuizMode ? 1 : 0))
                            let progress = min(currentStep / totalSteps, 1.0)
                            
                            Capsule().fill(focusColor)
                                .frame(width: proxy.size.width * progress, height: 8)
                                .animation(.spring, value: progress)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal)
                    
                    Spacer()
                    
