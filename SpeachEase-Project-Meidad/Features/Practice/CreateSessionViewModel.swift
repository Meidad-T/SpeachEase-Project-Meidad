import SwiftUI

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
