import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""

    @State private var blobAnimation = false
    @ObservedObject var learningManager = LearningManager.shared // Observe progress
    
    var body: some View {
        NavigationStack {
            ExploreContent()
        }
    }
}

struct ExploreContent: View {
    @State private var searchText = ""


    @State private var blobAnimation = false
    @ObservedObject var learningManager = LearningManager.shared
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var availableWidth: CGFloat = 0
    @State private var showResetAlert = false

    var body: some View {
        ZStack {
            // Base Background
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            // Foggy Gradient Animation

                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("Explore")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search topics...", text: $searchText)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        
                        // Filter Tags
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                let filters = ["All", "Popular", "New", "Beginner", "Advanced"]
                                ForEach(filters, id: \.self) { filter in
                                    Text(filter)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(filter == "All" ? Color.blue : Color.blue.opacity(0.1))
                                        .foregroundStyle(filter == "All" ? .white : .blue)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Bento Grid
                        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                            
                            // Row 1
                            GridRow {
                                NavigationLink(destination: SectionDetailView(focus: .vocal)) {
                                    BentoItem(
                                        id: "vocal",
                                        title: "Vocal Control",
                                        subtitle: "Pitch & Tone",
                                        icon: "mic.fill",
                                        color: .green,
                                        size: .square
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                NavigationLink(destination: SectionDetailView(focus: .body)) {
                                    BentoItem(
                                        id: "body",
                                        title: "Body Language",
                                        subtitle: "Posture & Gestures",
                                        icon: "figure.stand",
                                        color: .blue,
                                        size: .wide
                                    )
                                }
                                .buttonStyle(.plain)
                                .gridCellColumns(2)
                            }
                            
                            // Row 2
                            GridRow {
                                NavigationLink(destination: SectionDetailView(focus: .interview)) {
                                    BentoItem(
                                        id: "interview",
                                        title: "Interview Prep",
                                        subtitle: "Q&A Strategies",
                                        icon: "briefcase.fill",
                                        color: .orange,
                                        size: .wide
                                    )
                                }
                                .buttonStyle(.plain)
                                .gridCellColumns(2)
                                
                                NavigationLink(destination: SectionDetailView(focus: .pacing)) {
                                    BentoItem(
                                        id: "pacing",
                                        title: "Pacing",
                                        subtitle: "Speed & Pauses",
                                        icon: "speedometer",
                                        color: .pink,
                                        size: .square
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Row 3
                            GridRow {
                                NavigationLink(destination: SectionDetailView(focus: .facial)) {
                                    BentoItem(
                                        id: "facial",
                                        title: "Facial Aesthetics",
                                        subtitle: "Expressions",
                                        icon: "mouth",
                                        color: .purple,
                                        size: .square
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                NavigationLink(destination: SectionDetailView(focus: .vocab)) {
                                    BentoItem(
                                        id: "vocab",
                                        title: "Vocabulary",
                                        subtitle: "Word Choice",
                                        icon: "text.book.closed.fill",
                                        color: .yellow,
                                        size: .square
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                NavigationLink(destination: SectionDetailView(focus: .eye)) {
                                    BentoItem(
                                        id: "eye",
                                        title: "Eye Contact",
                                        subtitle: "Engagement",
                                        icon: "eye.fill",
                                        color: .teal,
                                        size: .square
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Achievements / Crowns Row (4 top, 3 bottom)
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Achievements")
                                .font(.title) // Even Larger (was title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                                .padding(.horizontal)
                                .padding(.top, 12) // Moved lower slightly
                            
                            // Layout Logic:
                            // iPhone (Compact): Adaptive Grid (Responsive)
                            // iPad (Regular): Custom VStack/HStack to achieve "Offset/Honeycomb" look (4 then 3)
                            if sizeClass == .compact {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 85), spacing: 10)], spacing: 30) {
                                    ForEach(PracticeFocus.allCases, id: \.self) { focus in
                                        AchievementCrownView(focus: focus, learningManager: learningManager)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 60)
                            } else {
                                // iPad Layout with Equal Sizing
                                GeometryReader { geo in
