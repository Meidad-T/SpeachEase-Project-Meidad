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
                        if viewModel.currentStep == .config {
                            viewModel.finishCreation()
                            if let session = viewModel.createdSession {
                                onSave(session)
                                dismiss()
                            }
                        } else {
                            viewModel.nextStep()
                        }
                    }) {
                        Text(viewModel.currentStep == .config ? (isEditing ? "Save Changes" : "Create Session") : "Next")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(viewModel.canGoNext ? viewModel.selectedColor : Color.gray)
                            .cornerRadius(20)
                    }
                    .disabled(!viewModel.canGoNext)
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Session" : "New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .onAppear {
            // Only randomize if creating fresh, otherwise use the loaded color
            if !isEditing {
                viewModel.randomizeColor()
            }
        }
    }
    
    // MARK: - Step 1: Details
    var detailsStep: some View {
        VStack(spacing: 24) {
            Text("Let's name your session")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            TextField("Session Name (e.g., Morning Warmup)", text: $viewModel.sessionName)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            
            Text("Choose a theme color")
                .font(.headline)
            
            ColorPicker("Custom Color", selection: $viewModel.selectedColor)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.randomizeColor()
            }) {
                HStack {
                    Image(systemName: "dice.fill")
                    Text("Randomize Color")
                }
                .font(.subheadline)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Step 2: Focus
    var focusStep: some View {
        VStack(spacing: 24) {
            Text("What do you want to focus on?")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
                .multilineTextAlignment(.center)
            
            ScrollView {
                // Adaptive layout: 2 columns on iPad/Regular, 1 on iPhone/Compact if desired or adaptive
                let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
                
                LazyVGrid(columns: columns, spacing: 16) {
                    
                    ForEach(PracticeFocus.allCases) { focus in
                        let isSelected = viewModel.selectedFoci.contains(focus)
                        
                        VStack(alignment: .leading) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(isSelected ? .white.opacity(0.2) : .gray.opacity(0.1))
                                        .frame(width: 64, height: 64)
                                    
                                    Image(systemName: focus.icon)
                                        .font(.title)
                                        .offset(x: focus == .pacing ? -2 : 0) // Optical nudging for speedometer
                                        .foregroundStyle(isSelected ? .white : .primary)
                                }
                                Spacer() // Forces icon to the left
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(focus.title)
                                    .font(.headline)
                                    .foregroundStyle(isSelected ? .white : .primary)
                                
                                Text(focus.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding()
                        .frame(height: 160)
                        .frame(maxWidth: .infinity, alignment: .leading) // Ensure card aligns content leading
                        .background(isSelected ? focus.defaultColor : Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .animation(.spring(), value: isSelected)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                viewModel.toggleFocus(focus)
                            }
                        }
                    }
                    
                    // "All" Button (Moved to bottom)
                    let isAllSelected = viewModel.selectedFoci.count == PracticeFocus.allCases.count
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            viewModel.selectAllFoci()
                        }
                    }) {
                        VStack(alignment: .leading) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(isAllSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.1))
                                        .frame(width: 64, height: 64)
                                    
                                    Image(systemName: "square.grid.2x2.fill")
                                        .font(.title)
                                        .foregroundStyle(isAllSelected ? Color.white : Color.primary)
                                }
                                Spacer() // Forces icon to the left
                            }
                            
                            Spacer()
                            
                            Text("All")
                                .font(.headline)
                                .foregroundStyle(isAllSelected ? Color.white : Color.primary)
                            
                            Text("Select everything")
                                .font(.caption)
                                .foregroundStyle(isAllSelected ? Color.white.opacity(0.8) : Color.secondary)
                        }
                        .padding()
                        .frame(height: 160)
                        .frame(maxWidth: .infinity, alignment: .leading) // Ensure card aligns content leading
                        .background(isAllSelected ? Color(red: 0.988, green: 0.655, blue: 0.980) : Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .scaleEffect(isAllSelected ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Step 3: Config
    var configStep: some View {
