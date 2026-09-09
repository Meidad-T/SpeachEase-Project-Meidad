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
                                    let spacing: CGFloat = 50
                                    let totalSpacing = spacing * 3 // 3 gaps for 4 items
                                    let availableWidth = geo.size.width
                                    let itemSize = (availableWidth - totalSpacing) / 4
                                    
                                    VStack(spacing: 50) {
                                        let allFocuses = Array(PracticeFocus.allCases)
                                        let row1 = allFocuses.prefix(4)
                                        let row2 = allFocuses.dropFirst(4)
                                        
                                        HStack(spacing: spacing) {
                                            ForEach(row1, id: \.self) { focus in
                                                AchievementCrownView(focus: focus, learningManager: learningManager)
                                                    .frame(width: itemSize)
                                            }
                                        }
                                        
                                        HStack(spacing: spacing) {
                                            ForEach(row2, id: \.self) { focus in
                                                AchievementCrownView(focus: focus, learningManager: learningManager)
                                                    .frame(width: itemSize)
                                            }
                                        }
                                    }
                                }
                                .frame(height: 350) // Fixed height to accommodate the crowns
                                .padding(.horizontal, 40)
                                .padding(.bottom, 60)
                            }
                        }
                    }
                    .padding(.top, 0)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline) // Custom title inside ScrollView
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showResetAlert = true
                        } label: {
                            Label("Reset Progress", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .alert("Reset All Progress?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset Everything", role: .destructive) {
                    learningManager.resetAllProgress()
                }
            } message: {
                Text("This will permanently remove all your earned crowns and reset every learning path back to Stage 1.\n\nAre you sure?")
            }
        }
    }


struct AchievementCrownView: View {
    let focus: PracticeFocus
    @ObservedObject var learningManager: LearningManager
    @State private var shakeAttempts: Int = 0
    @State private var showLockedAlert = false
    
    var body: some View {
        let isCompleted = learningManager.isSectionCompleted(focus: focus)
        
        ZStack {
            if isCompleted {
                Image(systemName: "crown.fill")
                    .resizable()
                    .scaledToFit()
                    // Size controlled by parent
                    .foregroundStyle(
