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
