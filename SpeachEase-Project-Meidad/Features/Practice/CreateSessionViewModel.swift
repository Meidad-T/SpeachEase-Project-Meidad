import SwiftUI
import Combine

class CreateSessionViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case details
        case focus
        case config
    }
    
    @Published var currentStep: Step = .details
    @Published var sessionName: String = ""
    @Published var selectedColor: Color = .blue // Default, will be random or user selected
    @Published var selectedFoci: Set<PracticeFocus> = []
    @Published var timeLimitText: String = ""
    @Published var enforceTimeLimit: Bool = false
    
    @Published var createdSession: PracticeSession? = nil
    
    // Edit Mode State
    private var editingSessionId: UUID? = nil
    
    init(sessionToEdit: PracticeSession? = nil) {
        if let session = sessionToEdit {
            self.sessionName = session.name
            // Initialize with existing foci
            self.selectedFoci = Set(session.foci)
            self.selectedColor = session.displayColor 
            
            if let limit = session.timeLimitMinutes {
                self.timeLimitText = String(limit)
            }
            self.enforceTimeLimit = session.enforceTimeLimit
            self.editingSessionId = session.id
        } 
    }
    
    // Validation
    var isDetailsValid: Bool {
        !sessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isFocusValid: Bool {
        !selectedFoci.isEmpty
    }
    
    var isConfigValid: Bool {
        // If enforcement is on, text must be a valid number
        if enforceTimeLimit {
            return Int(timeLimitText) != nil
        }
        return true
    }
    
    var canGoNext: Bool {
        switch currentStep {
        case .details: return isDetailsValid
        case .focus: return isFocusValid
        case .config: return isConfigValid
        }
    }
    
    // Focus Management
    func toggleFocus(_ focus: PracticeFocus) {
        if selectedFoci.contains(focus) {
            selectedFoci.remove(focus)
        } else {
            selectedFoci.insert(focus)
        }
    }
    
    func selectAllFoci() {
        if selectedFoci.count == PracticeFocus.allCases.count {
            selectedFoci.removeAll()
        } else {
            selectedFoci = Set(PracticeFocus.allCases)
        }
    }
    
    func nextStep() {
        if let next = Step(rawValue: currentStep.rawValue + 1) {
            withAnimation {
                currentStep = next
            }
        } else {
            // Finish
            finishCreation()
        }
    }
    
    func previousStep() {
        if let prev = Step(rawValue: currentStep.rawValue - 1) {
            withAnimation {
                currentStep = prev
            }
        }
    }
    
    func finishCreation() {
        guard !selectedFoci.isEmpty else { return }
        
        // Sort for consistent order if needed, or just array
        // We'll sort by the order they appear in allCases to exclude random set ordering
        let sortedFoci = PracticeFocus.allCases.filter { selectedFoci.contains($0) }
        
        let limit = Int(timeLimitText)
        let color = SavedColor(selectedColor)
        
        var newSession = PracticeSession(
            name: sessionName,
            foci: sortedFoci,
            timeLimitMinutes: limit,
            enforceTimeLimit: enforceTimeLimit,
            customColor: color
        )
        
        // Use existing ID if editing
        if let id = editingSessionId {
            newSession.id = id
        }
        
        // Save logic to be handled by parent view or a DataStore
        createdSession = newSession
    }
    
    func randomizeColor() {
        selectedColor = Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}
