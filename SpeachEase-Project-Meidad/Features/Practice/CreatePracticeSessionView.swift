import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CreatePracticeSessionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: CreateSessionViewModel
    var onSave: (PracticeSession) -> Void
    
    // Track if we are editing for UI labels
    private let isEditing: Bool
    
    init(sessionToEdit: PracticeSession? = nil, onSave: @escaping (PracticeSession) -> Void) {
        self._viewModel = StateObject(wrappedValue: CreateSessionViewModel(sessionToEdit: sessionToEdit))
        self.onSave = onSave
        self.isEditing = sessionToEdit != nil
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress Indicator
                HStack(spacing: 4) {
                    ForEach(CreateSessionViewModel.Step.allCases, id: \.self) { step in
                        Rectangle()
                            .fill(step.rawValue <= viewModel.currentStep.rawValue ? viewModel.selectedColor : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .animation(.spring(), value: viewModel.currentStep)
                    }
                }
                .padding(.top)
                
                TabView(selection: $viewModel.currentStep) {
                    detailsStep
                        .tag(CreateSessionViewModel.Step.details)
                    
                    focusStep
                        .tag(CreateSessionViewModel.Step.focus)
                    
                    configStep
                        .tag(CreateSessionViewModel.Step.config)
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // Disable default dots
                .animation(.easeInOut, value: viewModel.currentStep)
                
                // Navigation Buttons
                HStack {
                    if viewModel.currentStep != .details {
                        Button("Back") {
                            viewModel.previousStep()
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
