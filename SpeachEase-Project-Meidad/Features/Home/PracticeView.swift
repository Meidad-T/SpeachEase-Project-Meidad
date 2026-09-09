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
        editingSession = session
    }
    
    private func deleteSession(_ session: PracticeSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            // 1. Archive History before deletion
            if !session.history.isEmpty {
                var historyToArchive = session.history
                // Tag with session name
                for i in 0..<historyToArchive.count {
                    historyToArchive[i].sessionName = session.name
                }
                
                // Load existing archive
                var archived: [PracticeAttempt] = []
                if let data = UserDefaults.standard.data(forKey: "archivedPracticeHistory"),
                   let decoded = try? JSONDecoder().decode([PracticeAttempt].self, from: data) {
                    archived = decoded
                }
                
                // Append and Save
                archived.append(contentsOf: historyToArchive)
                if let encoded = try? JSONEncoder().encode(archived) {
                    UserDefaults.standard.set(encoded, forKey: "archivedPracticeHistory")
                }
            }
            
            withAnimation {
                sessions.remove(at: index)
                saveSessions()
            }
        }
    }
    
    // MARK: - Persistence
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "savedPracticeSessions")
        }
    }
    
    private func loadSessions() {
        // Only load if empty to prevent overwriting active state and destabilizing IDs
        guard sessions.isEmpty else { return }
        
        if let data = UserDefaults.standard.data(forKey: "savedPracticeSessions"),
           let decoded = try? JSONDecoder().decode([PracticeSession].self, from: data) {
            sessions = decoded
        }
    }
}

// MARK: - Session Display Card
struct SessionCard: View {
    let session: PracticeSession
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        let isIPad = sizeClass == .regular
        // Use primary focus for background color if multiple, or maybe a neutral one?
        // User didn't specify color change, just icon.
        let primaryFocus = session.foci.first ?? .vocal 
        
        let displayIcon = session.foci.count > 1 ? "square.grid.2x2.fill" : primaryFocus.icon
        
        ZStack {
            // Background Texture (Watermark)
            GeometryReader { proxy in
                Image(systemName: displayIcon)
                    .font(.system(size: proxy.size.height * 0.8))
                    .foregroundColor(.white.opacity(0.1))
                    .rotationEffect(.degrees(-15))
                    .offset(x: proxy.size.width * 0.6, y: proxy.size.height * 0.2)
            }
            .clipped()
            
            HStack(spacing: 20) {
                // Modified content layout for taller cards?
                // Actually the user just said "twice the height", maybe we stack things better if tall?
                // For now, keep HStack but align top if tall.
                
                // Icon
                Image(systemName: displayIcon)
                    .font(.system(size: isIPad ? 48 : 32)) 
                    .foregroundColor(.white)
                    .padding(.leading, 10)
                    .frame(width: isIPad ? 80 : 50)
                
                VStack(alignment: .leading, spacing: isIPad ? 12 : 6) {
                    Text(session.name)
                        .font(isIPad ? .title : .title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        // Focus Label
                        HStack(spacing: 4) {
                            Image(systemName: "target")
                                .font(.caption2)
                            
                            // Check if multiple
                            if session.foci.count > 1 {
                                Text("Mixed (\(session.foci.count))")
