import SwiftUI

struct SectionDetailView: View {
    let focus: PracticeFocus
    
    var body: some View {
        TabView {
            SectionAboutView(focus: focus)
                .tabItem {
                    Label("About", systemImage: "info.circle.fill")
                }
            
            SectionLearnView(focus: focus)
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
            
            SectionPlayView(focus: focus)
                .tabItem {
                    Label("Play", systemImage: "play.circle.fill")
                }
        }
        // This is the magic line that hides the main app tab bar
        .toolbar(.hidden, for: .tabBar) 
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Sub Views

struct SectionAboutView: View {
    let focus: PracticeFocus
    
    var body: some View {
        ZStack {
            // 1. Base Background
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            // 2. Top Color Splash (Subtle ambience)
            GeometryReader { proxy in
                Circle()
                    .fill(focus.defaultColor.opacity(0.2))
                    .blur(radius: 60)
                    .frame(width: proxy.size.width * 1.2)
                    .offset(x: -proxy.size.width * 0.2, y: -proxy.size.width * 0.5)
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // 3. Open Hero Header (No Container)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(focus.subtitle.uppercased())
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(focus.defaultColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(focus.defaultColor.opacity(0.1), in: Capsule())
                            
                            Text(focus.title)
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundStyle(Color.primary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                        
                        // Floating 3D-ish Icon
                        Image(systemName: focus.icon)
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [focus.defaultColor, focus.defaultColor.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: focus.defaultColor.opacity(0.4), radius: 10, x: 0, y: 10)
                            .rotationEffect(.degrees(-10))
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // 4. Vibrant Highlight Banner
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.title3)
                                .foregroundStyle(.yellow)
                            Text("PRO TIP")
                                .font(.caption)
                                .fontWeight(.heavy)
                                .foregroundStyle(.white.opacity(0.9))
                                .tracking(1)
                            Spacer()
                        }
                        
                        Text(focus.highlightTitle)
                            .font(.system(.title, design: .rounded, weight: .heavy))
                            .foregroundStyle(.white)
                        
                        Text(focus.highlightDescription)
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.95))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(24)
                    .background(
                        LinearGradient(
                            colors: [focus.defaultColor, focus.defaultColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: focus.defaultColor.opacity(0.4), radius: 15, y: 8)
                    .padding(.horizontal)
                    
                    // 5. Chunked Info Cards
                    VStack(spacing: 20) {
                        let chunks = focus.description.components(separatedBy: "\n\n")
                        
                        ForEach(Array(chunks.enumerated()), id: \.offset) { index, chunk in
                            HStack(alignment: .top, spacing: 16) {
                                // Decorative Number/Dot
                                Circle()
                                    .fill(focus.defaultColor.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(focus.defaultColor)
                                    )
                                
                                Text(chunk)
                                    .font(.system(.body, design: .rounded))
                                    .lineSpacing(5)
                                    .foregroundStyle(.primary.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                            }
                            .padding(20)
                            .background(Color.adaptiveCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
            }
        }
    }
}

struct SectionLearnView: View {
    let focus: PracticeFocus
    @ObservedObject var learningManager = LearningManager.shared
    @State private var selectedLesson: Lesson?
    
    var depthColor: Color {
        switch focus {
        case .vocal: return Color(red: 0.0, green: 0.5, blue: 0.4) // Darker Green/Teal for Green
        case .vocab: return .orange // Orange for Yellow
        case .interview: return .red // Red for Orange
        case .pacing: return Color(red: 0.6, green: 0.1, blue: 0.2) // Dark Red/Maroon for Pink
        case .facial: return .indigo // Indigo for Purple
        case .body: return Color(red: 0.0, green: 0.0, blue: 0.5) // Dark Blue for Blue
        case .eye: return .blue // Blue for Teal

        }
    }
    
    var body: some View {
        let lessons = learningManager.lessons(for: focus)
        // Determine active lesson for auto-scrolling
        let activeId = lessons.first { learningManager.isLessonUnlocked(id: $0.id, allLessons: lessons) && !learningManager.isLessonCompleted(id: $0.id) }?.id 
            ?? lessons.last(where: { learningManager.isLessonCompleted(id: $0.id) })?.id 
            ?? lessons.first?.id 
            ?? ""
            
        GeometryReader { geo in
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .bottom) {
                        // 1. Calculate Heights
                        let lessonCount = lessons.count
                        let gemIndex = lessonCount
                        // Path ends at the last lesson, Gem floats above
                        // Reduced buffers: 
                        // Top was + 350, now + 140 (approx 60% cut)
                        // Bottom margin logic separate below.
                        let totalHeight = CGFloat(lessonCount * 140) + 140
                        
                        // 1.5. Dynamic Scenery Background
                        // 1.5. Dynamic Scenery Background
                        // 1.5. Dynamic Scenery Background
                        // Map focus to theme based on color group & Feedback
                        let theme: PathTheme = {
                            // Green (Vocal) -> Forest
                            // Yellow (Vocab) -> Forest (Requested "Trees")
                            if focus.id == "vocal" || focus.id == "vocab" { return .forest }
                            
                            // Orange (Interview) -> Autumn
                            if focus.id == "interview" { return .autumn }
                            
                            // Red (Pacing) -> Energy (New)
                            if focus.id == "pacing" { return .energy }
                            
                            // Purple (Facial) -> Mystic
                            if focus.id == "facial" { return .mystic }
                            
                            // Blue (Body) -> Ocean (New, no ice)
                            if focus.id == "body" { return .ocean }
                            
                            // Teal (Eye) -> Frost (More icons)
                            if focus.id == "eye" { return .frost }
                            
                            return .forest // Fallback
                        }()
                        
                        PathBackgroundView(totalHeight: totalHeight, color: focus.defaultColor, theme: theme)
                        
                        // 2. The Winding Path Line (Drawn Bottom-Up)
                        PathShape(lessonCount: lessonCount, spacing: 140)
                            .stroke(
                                style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round, dash: [10, 15])
                            )
                            .foregroundStyle(focus.defaultColor.opacity(0.3))
                            .frame(height: totalHeight)
                        
                        // 3. The Goal/Treasure Chest (At the Top)
                        // Using reduced bottom padding of 50
                        let gemYOffset = totalHeight - 50 - CGFloat(gemIndex * 140)
                        let gemXOffset: CGFloat = 0 // Centered
                        
                        ZStack {
                            // Large Crown (Colored)
                            ZStack {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 100))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [focus.defaultColor.opacity(0.8), focus.defaultColor],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: focus.defaultColor.opacity(0.5), radius: 10, x: 0, y: 5)
                                    .overlay(
                                        // Subtle shine
                                        Image(systemName: "crown")
                                            .font(.system(size: 100))
                                            .foregroundStyle(.white.opacity(0.3))
                                    )
                            }
                            .scaleEffect(1.2)
                        }
                        .position(x: geo.size.width / 2 + gemXOffset, y: gemYOffset)
                        
                        // 4. Lesson Nodes (Placed Bottom-Up)
                        ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                            // Calculation: Index 0 is at the BOTTOM. 
                            // Reduced bottom padding to 50
                            let bottomPadding: CGFloat = 50 
                            let yOffset = totalHeight - bottomPadding - CGFloat(index * 140)
                            let xOffset = getOffset(for: index)
                            
                            ZStack {
                                // The Label (Side Signpost) - Hidden if Locked
                                if getStatus(for: lesson, allLessons: lessons) != .locked {
                                    Text(lesson.title)
                                        .font(.system(.caption, design: .rounded, weight: .bold))
                                        .multilineTextAlignment(index % 2 == 0 ? .leading : .trailing)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.adaptiveCardBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        .offset(x: xOffset > 0 ? 90 : -90)
                                        .frame(width: 120, alignment: xOffset > 0 ? .leading : .trailing)
                                }
                                
                                // The Node Button
                                LessonNode(
                                    lesson: lesson,
                                    index: index,
                                    focusColor: focus.defaultColor,
                                    depthColor: depthColor,
                                    status: getStatus(for: lesson, allLessons: lessons)
                                ) {
                                    if getStatus(for: lesson, allLessons: lessons) != .locked {
                                        selectedLesson = lesson
                                    }
                                }
                            }
                            .position(x: geo.size.width / 2 + xOffset, y: yOffset)
                            .id(lesson.id) // For ScrollViewReader
                        }
                        
                        // 5. Invisible Bottom Anchor
                        // Allows scrolling to the extreme bottom
                        Color.clear
                            .frame(width: 1, height: 1)
                            .position(x: geo.size.width / 2, y: totalHeight)
                            .id("bottom-anchor")
                    }
                    .frame(height: CGFloat((lessons.count) * 140) + 140)
                    .padding(.bottom, 50) 
                }
                .onAppear {
                    // Scroll to the active lesson with a slight delay
                    let target = activeId.isEmpty ? lessons.first?.id ?? "" : activeId
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if let index = lessons.firstIndex(where: { $0.id == target }) {
                            // Scroll Logic:
                            // Index 0: Scroll to absolute bottom anchor to show full padding.
                            // Index < 3: Anchor Lesson to bottom.
                            // Others: Center.
                            withAnimation(.easeInOut(duration: 0.5)) {
                                if index == 0 {
                                    proxy.scrollTo("bottom-anchor", anchor: .bottom)
                                } else if index < 3 {
                                    proxy.scrollTo(target, anchor: .bottom)
                                } else {
                                    proxy.scrollTo(target, anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
            }
            .fullScreenCover(item: $selectedLesson) { lesson in
                LessonView(lesson: lesson, focusColor: focus.defaultColor)
            }
        }
    }
    
    // Wave Logic
    func getOffset(for index: Int) -> CGFloat {
        let amplitude: CGFloat = 80
        return amplitude * sin(Double(index) * 2.0)
    }
    
    func getStatus(for lesson: Lesson, allLessons: [Lesson]) -> LessonStatus {
        if focus == .interview { return .locked }
        
        if learningManager.isLessonCompleted(id: lesson.id) {
            return .completed
        } else if learningManager.isLessonUnlocked(id: lesson.id, allLessons: allLessons) {
            return .active
        } else {
            return .locked
        }
    }
}

enum LessonStatus {
    case locked, active, completed
}

// Refined LessonNode
struct LessonNode: View {
    let lesson: Lesson

    let index: Int
    let focusColor: Color
    let depthColor: Color
    let status: LessonStatus
    let action: () -> Void
    
    @State private var pulse: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Active Pulse Ring
            if status == .active {
                Circle()
                    .stroke(focusColor.opacity(0.5), lineWidth: 4)
                    .frame(width: 86, height: 86)
                    .scaleEffect(pulse)
                    .opacity(2 - pulse)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                            pulse = 1.5
                        }
                    }
            }
            
            // Main Circle
            Circle()
                .fill(backgroundColor)
                .frame(width: 74, height: 74)
                .shadow(color: shadowColor, radius: 0, x: 0, y: 6)
                
                // Inner Highlight/Bevel
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .padding(2)
                )
            
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
        }
        .onTapGesture {
            action()
        }
        .contextMenu {
            Button {
                // Edit Logic Placeholder
            } label: {
                Label("Edit Lesson", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                // Delete Logic Placeholder
            } label: {
                Label("Delete Lesson", systemImage: "trash")
            }
        }
    }
    
    var iconName: String {
        switch status {
        case .locked: return "lock.fill"
        case .completed: return "checkmark"
        case .active: return "star.fill"
        }
    }
    
    var backgroundColor: Color {
        switch status {
        case .locked: return Color(UIColor.systemGray4)
        case .active: return focusColor
        case .completed: return focusColor
        }
    }
    
    var shadowColor: Color {
        switch status {
        case .locked: return Color(UIColor.systemGray3)
        case .active: return depthColor
        case .completed: return depthColor
        }
    }
}

struct PathShape: Shape {
    let lessonCount: Int
    let spacing: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard lessonCount > 1 else { return path }
        
        let centerX = rect.width / 2
        // Use the frame height provided by the parent view
        let totalHeight = rect.height
        
        // High-resolution drawing for "Waxy" smooth curve
        // We draw from Bottom (Lesson 0) to Top (Lesson N)
        // Reduced bottom padding to 50
        
        let startY = totalHeight - 50
        let endY = startY - CGFloat((lessonCount - 1) * Int(spacing))
        
        // Start point
        path.move(to: CGPoint(x: centerX + getOffset(y: startY, totalHeight: totalHeight), y: startY))
        
        // Step size for smoothness (smaller = smoother)
        let step: CGFloat = 5
        
        // Iterate upwards (decreasing Y)
        var currentY = startY
        while currentY > endY {
            currentY -= step
            let x = centerX + getOffset(y: currentY, totalHeight: totalHeight)
            path.addLine(to: CGPoint(x: x, y: currentY))
        }
        
        return path
    }
    
    func getOffset(y: CGFloat, totalHeight: CGFloat) -> CGFloat {
        // Reverse engineer the index from Y to keep consistency
        // Y = totalHeight - 50 - (index * 140)
        // index = (totalHeight - 50 - Y) / 140
        let indexLike = (totalHeight - 50 - y) / 140.0
        let amplitude: CGFloat = 80
        return amplitude * sin(Double(indexLike) * 2.0)
    }
}

struct SectionPlayView: View {
    let focus: PracticeFocus
    @State private var isGamePresented = false
    
    var body: some View {
        ZStack {
            // Consistent BG style
            LinearGradient(
                colors: [focus.defaultColor.opacity(0.6), Color(UIColor.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(focus.defaultColor)
                
                Text(focus == .vocab ? "Vocabulary Tower" : "Interactive Exercises")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(focus == .vocab ? "Stack the crates by answering grammar questions correctly!" : "Put your \(focus.title.lowercased()) skills to the test with these games.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundStyle(.primary.opacity(0.8))
                
                if focus == .vocab {
                    Button {
                        isGamePresented = true
                    } label: {
                        Text("Play Now")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(focus.defaultColor)
                            .cornerRadius(30)
                            .shadow(radius: 5)
                            .padding(.top, 20)
                    }
                } else {
                    Text("(Coming Soon)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 10)
                }
            }
        }
        .fullScreenCover(isPresented: $isGamePresented) {
            VocabularyTowerGameView()
        }
    }
}

enum PathTheme {
    case forest, autumn, energy, mystic, ocean, frost
}

struct PathBackgroundView: View {
    let totalHeight: CGFloat
    let color: Color
    let theme: PathTheme
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            // Increased density slightly for "lots of things"
            // Frost/Eye needs more density per request
            let baseDensity: CGFloat = theme == .frost ? 50 : 70
            let density: Int = Int(totalHeight / baseDensity)
            
            ZStack {
                ForEach(0..<density, id: \.self) { index in
                    let itemType = index % 5
                    // Randomized positioning
                    let yPos = CGFloat(index) * baseDensity + CGFloat.random(in: -30...30)
                    let side = index % 2 == 0 ? "left" : "right"
                    let xOffset = CGFloat.random(in: 10...120)
                    let xPos = side == "left" ? xOffset : (width - xOffset)
                    let scale = CGFloat.random(in: 0.7...1.5)
                    let randomRotation = Double.random(in: -20...20)
                    
                    Group {
                        switch theme {
                        case .forest:
                            if itemType == 0 {
                                Image(systemName: "tree.fill")
                                    .foregroundStyle(color)
                                    .scaleEffect(1.2)
                            } else if itemType == 1 {
                                Image(systemName: "laurel.leading")
                                    .foregroundStyle(color.opacity(0.8))
                                    .rotationEffect(.degrees(side == "left" ? -45 : 45))
                                    .scaleEffect(1.5)
                            } else {
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(color.opacity(0.6))
                                    .rotationEffect(.degrees(randomRotation))
                            }
                            
                        case .autumn:
                            if itemType == 0 {
                                Image(systemName: "sun.max.fill")
                                    .foregroundStyle(.yellow.opacity(0.8))
                                    .shadow(color: .orange, radius: 10)
                            } else if itemType == 1 {
                                Image(systemName: "wind")
                                    .foregroundStyle(.gray.opacity(0.3))
                                    .scaleEffect(1.5)
                            } else {
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(index % 3 == 0 ? .orange : (index % 3 == 1 ? .red : .brown))
                                    .rotationEffect(.degrees(Double.random(in: 0...360)))
                            }
                        
                        case .energy:
                            // Pacing/Red: Fire, Bolts, Hearts
                            if itemType == 0 {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange)
                                    .shadow(color: .red, radius: 5)
                            } else if itemType == 1 {
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(.yellow)
                                    .shadow(color: .orange, radius: 5)
                            } else if itemType == 2 {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(Color.red.opacity(0.8))
                            } else {
                                // Dynamic shapes
                                Image(systemName: "triangle.fill")
                                    .foregroundStyle(color.opacity(0.5))
                                    .scaleEffect(0.6)
                                    .rotationEffect(.degrees(Double.random(in: 0...360)))
                            }

                        case .mystic:
                            if itemType == 0 {
                                Image(systemName: "suit.diamond.fill")
                                    .foregroundStyle(color.opacity(0.8))
                                    .shadow(color: .white.opacity(0.6), radius: 5)
                            } else if itemType == 1 {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.white) // White sparkles
                            } else if itemType == 2 {
                                Image(systemName: "camera.macro")
                                    .foregroundStyle(Color.purple.opacity(0.7))
                            } else {
                                // Stars - PINK now, not yellow
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.pink.opacity(0.6))
                                    .scaleEffect(0.5)
                            }
                            
                        case .ocean:
                            // Body/Blue: Water drops, distinct from ice
                            if itemType == 0 {
                                Image(systemName: "drop.fill")
                                    .foregroundStyle(Color.blue.opacity(0.9)) // Darker blue
                            } else if itemType == 1 {
                                Circle() // Bubbles
                                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                    .frame(width: 20, height: 20)
                            } else {
                                // Waves
                                Image(systemName: "water.waves")
                                    .foregroundStyle(color.opacity(0.7))
                            }

                        case .frost:
                            // Eye/Teal: Ice and Snow
                            if itemType == 0 {
                                Image(systemName: "snowflake")
                                    .foregroundStyle(.cyan.opacity(0.8))
                                    .shadow(color: .white, radius: 2)
                            } else if itemType == 1 {
                                Image(systemName: "wind.snow")
                                    .foregroundStyle(.white.opacity(0.5))
                            } else {
                                // Ice crystals
                                Image(systemName: "sparkle")
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                    .font(.system(size: 40)) // Base size
                    .scaleEffect(scale)
                    .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 4)
                    .position(x: xPos, y: totalHeight - yPos)
                }
            }
        }
        .frame(height: totalHeight)
        .allowsHitTesting(false)
    }
}
