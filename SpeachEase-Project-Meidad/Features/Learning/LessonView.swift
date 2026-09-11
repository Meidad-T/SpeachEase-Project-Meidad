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
                    
                    // Speaker Toggle
                    Button {
                        speakerManager.toggle()
                        if speakerManager.isEnabled {
                            // If turned on, read current content immediately
                            readCurrentContent()
                        }
                    } label: {
                        Image(systemName: speakerManager.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title2)
                            .foregroundStyle(speakerManager.isEnabled ? focusColor : .gray)
                            .padding(8)
                            .background(speakerManager.isEnabled ? focusColor.opacity(0.1) : Color.clear, in: Circle())
                    }
                    .contextMenu {
                        Button {
                            speakerManager.selectedGender = .female
                            speakerManager.speak("Voice changed to Female")
                        } label: {
                            Label("Female Voice", systemImage: speakerManager.selectedGender == .female ? "checkmark" : "")
                        }
                        
                        Button {
                            speakerManager.selectedGender = .male
                            speakerManager.speak("Voice changed to Male")
                        } label: {
                            Label("Male Voice", systemImage: speakerManager.selectedGender == .male ? "checkmark" : "")
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                if !isQuizMode {
                    // Content Page
                    VStack(spacing: 30) {
                        Image(systemName: lesson.icon)
                            .font(.system(size: 80))
                            .foregroundStyle(focusColor)
                            .padding()
                            .background(focusColor.opacity(0.1), in: Circle())
                        
                        Text(lesson.content[currentPage])
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.scale.combined(with: .opacity))
                            .id(currentPage) // Force transition
                    }
                } else if !showSuccess {
                    // Quiz Mode
                    VStack(spacing: 30) {
                        Text("Quiz Time!")
                            .font(.headline)
                            .foregroundStyle(focusColor)
                        
                        Text(lesson.quizQuestion)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(0..<lesson.quizOptions.count, id: \.self) { index in
                                Button {
                                    selectedOption = index
                                } label: {
                                    HStack {
                                        Text(lesson.quizOptions[index])
                                            .fontWeight(.medium)
                                        Spacer()
                                        if selectedOption == index {
                                            Image(systemName: "checkmark.circle.fill")
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedOption == index ? focusColor : Color.gray.opacity(0.3), lineWidth: 2)
                                            .background(selectedOption == index ? focusColor.opacity(0.05) : Color(UIColor.systemBackground))
                                    )
                                    .foregroundStyle(.primary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .transition(.move(edge: .trailing))
                } else {
                    // Success View
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(.yellow)
                            .shadow(radius: 10)
                            .rotationEffect(.degrees(isCompleted ? 360 : 0))
                            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: isCompleted)
                        
                        Text("Lesson Complete!")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundStyle(focusColor)
                        
                        Text("+10 XP")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .onAppear {
                        isCompleted = true
                    }
                }
                
                Spacer()
                
                // Footer
                VStack {
                    Button {
                        handleNext()
                    } label: {
                        Text(showSuccess ? "Finish" : (selectedOption != nil && isQuizMode ? "Check" : "Continue"))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                CapsuledButtonBackground(focusColor: focusColor, isEnabled: canProceed())
                            )
                    }
                    .disabled(!canProceed())
                }
                .padding()
            }
        }
        .onChange(of: currentPage) { _, _ in
            readCurrentContent()
        }
        .onChange(of: isQuizMode) { _, newValue in
            if newValue {
                readCurrentContent()
            }
        }
        .onDisappear {
            speakerManager.stop()
        }
    }
    
    // View Helper for Button Background
    struct CapsuledButtonBackground: View {
        let focusColor: Color
        let isEnabled: Bool
        
        var body: some View {
            Capsule()
                .fill(isEnabled ? focusColor : Color.gray.opacity(0.3))
                .shadow(color: isEnabled ? focusColor.opacity(0.4) : .clear, radius: 10, y: 5)
        }
    }
    
    func canProceed() -> Bool {
        if isQuizMode && !showSuccess {
            return selectedOption != nil
        }
        return true
    }
    
    func handleNext() {
        if showSuccess {
            // Finish
            learningManager.completeLesson(id: lesson.id)
            dismiss()
        } else if isQuizMode {
            // Check Answer
            if selectedOption == lesson.correctOptionIndex {
                withAnimation {
                    showSuccess = true
                    speakerManager.stop() // Stop reading quiz
                }
            } else {
                // Wrong answer animation/feedback (simple shaker could go here)
                // For now just clear selection to retry
                selectedOption = nil
            }
        } else {
            // Next Page
            if currentPage < lesson.content.count - 1 {
                withAnimation {
                    currentPage += 1
                }
            } else {
                // Enter Quiz Mode
                withAnimation {
                    isQuizMode = true
                }
            }
        }
    }
    
    // MARK: - TTS Logic
    
    private func readCurrentContent() {
        guard speakerManager.isEnabled else { return }
        
        if isQuizMode {
            // Read Quiz formatted
            let text = "Okay, time to test what we learned! \(lesson.quizQuestion) " +
            lesson.quizOptions.enumerated().map { index, option in
                "Option \(Character(UnicodeScalar(65 + index)!)): \(option)"
            }.joined(separator: ". ")
            
            speakerManager.speak(text)
        } else {
            // Read Slide
            let text = lesson.content[currentPage]
            speakerManager.speak(text)
        }
    }
}
