import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PracticeView: View {
    @State private var sessions: [PracticeSession] = []
    @State private var showingCreateSheet = false
    @State private var editingSession: PracticeSession? = nil
    @State private var selectedSessionIdent: SessionIdent? = nil // Stable ID for launching practice
    
    // Search & Filter
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    
    // Responsive Grid
    @Environment(\.horizontalSizeClass) var sizeClass
    
    struct SessionIdent: Identifiable {
        let id: UUID
    }
    
    var columns: [GridItem] {
        if sizeClass == .regular {
            // iPad: 2 columns
            return [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]
        } else {
            // iPhone: 1 column
            return [GridItem(.flexible(), spacing: 20)]
        }
    }
    
    var filteredSessions: [PracticeSession] {
        var result = sessions
        
        // Filter by tag
        if selectedFilter != "All" {
            result = result.filter { session in
                // Map text tag back to focus enum or just match title
                // Simple matching:
                if selectedFilter == "Strict" {
                   return session.enforceTimeLimit
                } else {
                    return session.foci.contains { $0.title.contains(selectedFilter) }
                }
            }
        }
        
        // Search
        if !searchText.isEmpty {
            result = result.filter { session in
                session.name.localizedCaseInsensitiveContains(searchText) ||
                session.foci.contains { $0.title.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Search, Filters, New Button)
                VStack(spacing: 16) {
                    // Top Row: Title + New Button
                    HStack {
                        Text("Practice")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: { showingCreateSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .fontWeight(.bold)
                                Text("New")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search sessions...", text: $searchText)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Filter Tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            let filters = ["All", "Vocal Control", "Body Language", "Interview Prep", "Strict"]
                            ForEach(filters, id: \.self) { filter in
                                Text(filter)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == filter ? Color.accentColor : Color.accentColor.opacity(0.1))
                                    .foregroundStyle(selectedFilter == filter ? .white : Color.accentColor)
                                    .clipShape(Capsule())
                                    .onTapGesture {
                                        withAnimation {
                                            selectedFilter = filter
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
                .background(Color(UIColor.systemGroupedBackground)) // Sticky feel header bg
                .zIndex(1)
                
                // Main Content
                if sessions.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor.opacity(0.6))
                        Text("No Practice Sessions")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Create a custom session to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filteredSessions) { session in
                                // Video-only check
                                // unlocked now that video analysis is implemented
                                let isLocked = false
                                
                                Button {
                                    if isLocked {
                                        // Trigger shake or alert? Using simple alert via state might be cleaner, 
                                        // or just do nothing/shake. The user said "not clickable".
                                        // But users hate dead buttons. Let's show an alert.
                                        // Since we are in a Loop, we need a separate state or just ignore.
                                        // User said "have a lock on them meaning they are not clickable".
                                        // I will simply disable the interaction effectively or showing a lock overlay.
                                        // Actually, I'll trigger a simple "Coming Soon" alert if I can, but I need state for that.
                                        // Let's just create a local "locked" state? No, in ForEach that's hard.
                                        // I'll use a shared alert state.
                                        // For now, I'll just make it unclickable.
                                    } else {
                                        selectedSessionIdent = SessionIdent(id: session.id)
                                    }
                                } label: {
                                    SessionCard(session: session)
                                        .overlay(
                                            ZStack {
                                                if isLocked {
                                                    Color.black.opacity(0.4)
                                                        .cornerRadius(24)
                                                    
                                                    VStack(spacing: 8) {
                                                        Image(systemName: "lock.fill")
                                                            .font(.largeTitle)
                                                            .foregroundStyle(.white)
                                                        
                                                        Text("Coming Soon")
                                                            .font(.caption)
                                                            .fontWeight(.bold)
                                                            .foregroundStyle(.white)
                                                            .padding(.horizontal, 12)
                                                            .padding(.vertical, 6)
                                                            .background(.ultraThinMaterial, in: Capsule())
                                                    }
                                                }
                                            }
                                        )
                                }
                                .buttonStyle(.plain) // Standard button behavior
                                .disabled(isLocked) // Make it truly unclickable if locked
                                .contextMenu {
                                    Button {
                                        editSession(session)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        deleteSession(session)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        // Launch Session
        .fullScreenCover(item: $selectedSessionIdent) { ident in
            if let index = sessions.firstIndex(where: { $0.id == ident.id }) {
                PracticeSessionView(session: $sessions[index]) { updatedSession in
                    saveSessions()
                }
            } else {
                 Text("Error: Session not found")
            }
        }
        // Sheet for Create
        .sheet(isPresented: $showingCreateSheet) {
            CreatePracticeSessionView { newSession in
                sessions.append(newSession)
                saveSessions()
            }
        }
        // Sheet for Edit
        .sheet(item: $editingSession) { session in
            CreatePracticeSessionView(sessionToEdit: session) { updatedSession in
                if let index = sessions.firstIndex(where: { $0.id == updatedSession.id }) {
                    sessions[index] = updatedSession
                    saveSessions()
                }
            }
        }
        .onAppear(perform: loadSessions)
        // Hide default nav bar since we built a custom header
        .navigationBarHidden(true) 
    }
    
    // MARK: - Actions
    private func editSession(_ session: PracticeSession) {
