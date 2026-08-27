import SwiftUI
import Speech
import AVFoundation

// MARK: - 1. Score Header (Activity Ring Style)
struct ResultsScoreHeader: View {
    let score: Int
    let feedback: String
    @State private var animatedScore: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 20)
                    .frame(width: 220, height: 220)

                // Ring
                ActivityRing(progress: animatedScore / 100, color: scoreColor(Int(animatedScore)))
                    .frame(width: 220, height: 220)
                    // Removed explicit animation modifier to respect easeOut curve from onAppear's withAnimation take control
                
                // Text
                VStack(spacing: 4) {
                    CountingText(
                        value: animatedScore,
                        font: .system(size: 70, weight: .heavy, design: .rounded)
                    )
                    .foregroundStyle(.primary)
                    
                    Text("Out of 100")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
            }
            .padding(.top, 10)
            
            Text(feedback)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.primary.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
        .onAppear {
            // Small delay to let the transition finish before filling
            withAnimation(.easeOut(duration: 1.5).delay(0.2)) {
                animatedScore = Double(score)
            }
        }
        .onChange(of: score) { _, newScore in
            // Handle updates if score changes while view is alive
             withAnimation(.easeOut(duration: 1.5)) {
                animatedScore = Double(newScore)
            }
        }
    }
    
    func scoreColor(_ score: Int) -> Color {
        if score >= 90 { return .green }
        if score >= 70 { return .cyan }
        if score >= 50 { return .orange }
        return .red
    }
}

// MARK: - 2. AI Summary Card (Glass)
// MARK: - 2. AI Summary Card (Glass)
struct ResultsAISummary: View {
    let report: SpeechReport?
    var isLoading: Bool = false
    @State private var showDetails = false
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.purple)
                        .scaleEffect(isLoading ? 1.1 : 1.0)
                        .opacity(isLoading ? 0.5 : 1.0)
                        .animation(isLoading ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default, value: isLoading)

                    Text(isLoading ? "Generating Insights..." : "AI Summary")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                
                if isLoading {
                    // Skeleton Lines
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(0..<2) { _ in
                            Capsule()
                                .fill(Color.primary.opacity(0.1))
                                .frame(height: 16)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .transition(.opacity)
                } else {
                    // Streaming Text
                    VStack(alignment: .leading, spacing: 12) {
                        TypewriterText(text: report?.narrativeReport ?? "No analysis available.")
                            .font(.body)
                            .lineSpacing(4)
                            .foregroundStyle(.secondary)
                        
                        // View More Button
                        if let analysis = report?.detailedAnalysis, !analysis.isEmpty {
                            Button {
                                showDetails = true
                            } label: {
                                HStack {
                                    Text("View Detailed Analysis")
                                        .fontWeight(.semibold)
                                    Image(systemName: "chevron.right")
                                }
                                .font(.subheadline)
                                .foregroundStyle(Color.purple)
                                .padding(.top, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showDetails) {
            DetailedAnalysisView(analysis: report?.detailedAnalysis ?? "")
        }
    }
}

struct DetailedAnalysisView: View {
    let analysis: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            MeshBackground()
                .overlay(
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(parseMarkdown(analysis), id: \.id) { element in
                                switch element.type {
                                case .header1(let text):
                                    Text(text)
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                        .padding(.top, 10)
                                case .header2(let text):
                                    Text(text)
                                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.primary)
                                        .padding(.top, 8)
                                case .listItem(let text):
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .font(.headline)
                                            .foregroundStyle(.secondary)
                                        Text(try! AttributedString(markdown: text))
                                            .font(.body)
                                            .foregroundStyle(.primary.opacity(0.9))
                                    }
                                    .padding(.leading, 8)
                                case .paragraph(let text):
                                    Text(try! AttributedString(markdown: text))
                                        .font(.body)
                                        .lineSpacing(4)
                                        .foregroundStyle(.primary.opacity(0.9))
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 40)
                    }
                )
                .navigationTitle("AI Breakdown")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
    
    // Simple Parser Types
    struct ParsedElement: Identifiable {
        let id = UUID()
        let type: ElementType
    }
    
    enum ElementType {
        case header1(String)
        case header2(String)
        case listItem(String)
        case paragraph(String)
    }
    
    func parseMarkdown(_ text: String) -> [ParsedElement] {
        var elements: [ParsedElement] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            if trimmed.hasPrefix("# ") {
                elements.append(ParsedElement(type: .header1(String(trimmed.dropFirst(2)))))
            } else if trimmed.hasPrefix("## ") {
                elements.append(ParsedElement(type: .header2(String(trimmed.dropFirst(3)))))
            } else if trimmed.hasPrefix("- ") {
                elements.append(ParsedElement(type: .listItem(String(trimmed.dropFirst(2)))))
            } else {
                elements.append(ParsedElement(type: .paragraph(trimmed)))
            }
        }
        return elements
    }
}

// MARK: - 3. Metrics Grid (Glass Rows)
// MARK: - 3. Metrics Grid (Glass Rows)
struct ResultsMetricsGrid: View {
    let report: SpeechReport
    var foci: [PracticeFocus] = [] // Defaults to empty implies showing default set or all
    
    // Dynamic Cards State
    @State private var cards: [MetricItem] = []
    
    struct MetricItem: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let score: Double
        let icon: String
        let color: Color
        var delay: Double
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Render in rows of 2
            ForEach(chunkedCards(), id: \.self) { row in
                HStack(spacing: 16) {
                    ForEach(row) { item in
                        MetricCard(title: item.title, score: item.score, icon: item.icon, color: item.color, delay: item.delay)
                    }
                    // Spacer if odd number
                    if row.count == 1 {
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            computeCards()
        }
    }
    
    func computeCards() {
        var newCards: [MetricItem] = []
        var delay = 0.0
        let step = 0.1
        
        // Helper to add card
        func add(_ title: String, _ score: Double, _ icon: String, _ color: Color) {
            newCards.append(MetricItem(title: title, score: score, icon: icon, color: color, delay: delay))
            delay += step
        }
        
        // 1. Determine what to show based on Foci
        // If no foci (legacy) or just generic, show standard set: Pacing, Tone, Vocab, Engagement
        let showStandard = foci.isEmpty
        
        if showStandard {
            add("Pacing", Double(report.pacingScore), "hare.fill", .cyan)
            add("Tone", Double(report.toneScore), "waveform", .purple)
            add("Vocabulary", Double(report.vocabularyScore), "text.book.closed.fill", .orange)
            add("Engagement", Double(report.engagementScore), "person.wave.2.fill", .pink)
        } else {
            // Dynamic Mapping
            var addedTypes = Set<String>()
            
            for focus in foci {
                switch focus {
                case .pacing:
                    if !addedTypes.contains("Pacing") {
                        add("Pacing", Double(report.pacingScore), "hare.fill", .cyan)
                        addedTypes.insert("Pacing")
                    }
                case .vocal:
                    if !addedTypes.contains("Tone") {
                        add("Tone", Double(report.toneScore), "waveform", .purple)
                        addedTypes.insert("Tone")
                    }
                case .vocab:
                    if !addedTypes.contains("Vocabulary") {
                        add("Vocabulary", Double(report.vocabularyScore), "text.book.closed.fill", .orange)
                        addedTypes.insert("Vocabulary")
                    }
                case .facial, .eye:
                    if !addedTypes.contains("Eye Contact") {
                        add("Eye Contact", report.eyeContactScore ?? 0.0, "eye.fill", .teal)
                        addedTypes.insert("Eye Contact")
                    }
                case .body:
                    if !addedTypes.contains("Body Language") {
                        add("Body Language", report.bodyLanguageScore ?? 0.0, "figure.stand", .blue)
                        addedTypes.insert("Body Language")
                    }
                case .interview:
                    // Interview is complex, maybe show Engagement & Clarity (Tone)?
                    if !addedTypes.contains("Engagement") {
                        add("Engagement", Double(report.engagementScore), "person.wave.2.fill", .pink)
                        addedTypes.insert("Engagement")
                    }
                }
            }
        }
        
        self.cards = newCards
    }
    
    func chunkedCards() -> [[MetricItem]] {
        stride(from: 0, to: cards.count, by: 2).map {
            Array(cards[$0..<min($0 + 2, cards.count)])
        }
    }
}

// MARK: - 4. Insights List
// MARK: - 4. Insights List
struct ResultsInsightsList: View {
    let userInsights: [SpeechInsight]
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Top Insights")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(userInsights.prefix(4).enumerated()), id: \.element.id) { index, insight in
                        InsightMiniCard(insight: insight)
                            .transition(.scale.combined(with: .opacity).animation(.spring().delay(Double(index) * 0.1)))
                    }
                }
            }
        }
    }
}

struct InsightMiniCard: View {
    let insight: SpeechInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: insight.type.icon)
                .foregroundStyle(insight.type.color)
                .font(.title2)
                .frame(width: 32, height: 32)
                .background(insight.type.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(insight.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - 5. Glass Loading View
struct GlassLoadingView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.primary)
                
                Text("Listening & Analyzing...")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
    }
}

// MARK: - Helpers

// Shared Metric Card (Now Glass Style)
struct MetricCard: View {
    let title: String
    let score: Double
    let icon: String
    let color: Color
    var delay: Double = 0.5
    @State private var showBar = false
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.title3)
                    Spacer()
                    
                    Text("\(Int(score))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                .padding(.bottom, 4)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                // Gradient Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.1))
                        
                        Capsule()
                            .fill(LinearGradient(colors: [color.opacity(0.5), color], startPoint: .leading, endPoint: .trailing))
                            .frame(width: showBar ? geo.size.width * (score / 100) : 0)
                    }
                }
                .frame(height: 6)
            }
        }
        .onAppear {
            withAnimation(.spring().delay(delay + 0.3)) { // Wait for card to appear + small buffer
                showBar = true
            }
        }
    }
}

struct TypewriterText: View {
    let text: String
    @State private var displayText = ""
    
    var body: some View {
        Text(displayText)
            .task(id: text) {
                // Prevent re-animation if text is already fully displayed
                if displayText == text { return }
                
                displayText = ""
                try? await Task.sleep(nanoseconds: 100_000_000)
                for char in text {
                    displayText.append(char)
                    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s as requested
                }
            }
    }
}

// Re-add CountingText just in case needed elsewhere, though ActivityRing handles transition now
struct CountingText: View, Animatable {
    var value: Double
    var font: Font
    
    nonisolated var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    var body: some View {
        Text("\(Int(value))")
            .font(font)
    }
}

// MARK: - 6. Progress Trend Graph
struct ProgressTrendGraph: View {
    let history: [PracticeAttempt]
    let currentScore: Int?
    let currentConfidence: Int?
    var extraDataMap: [UUID: String]? = nil // Map of Attempt ID -> Lesson Name
    
    @State private var animationProgress: CGFloat = 0
    @State private var showDots: Bool = false // Separate trigger for staggered dots
    @State private var selectedPointID: UUID?
    
    // 1. Prepare Data
    var dataPoints: [PracticeAttempt] {
        history.sorted(by: { $0.date < $1.date })
    }
    
    // Constants
    let animDuration: Double = 2.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Performance History")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                
                // Legend
                HStack(spacing: 12) {
                    Label("Score", systemImage: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                    
                    Label("Confidence", systemImage: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal)
            
            // Chart Container
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground).opacity(0.5))
                    // Tap anywhere on background to dismiss
                    .onTapGesture {
                        withAnimation { selectedPointID = nil }
                    }
                
                if dataPoints.isEmpty {
                     VStack(spacing: 8) {
                        Image(systemName: "chart.xyaxis.line")
                        // ... (omitted)
                        Text("No data yet. Complete a session!")
                            // ... (omitted)
                    }
                } else {
                    GeometryReader { geo in
                        let chartHeight = geo.size.height - 30 // reserve space for X labels
                        let chartWidth = geo.size.width - 40   // reserve space for Y labels
                        
                        ZStack(alignment: .topLeading) {
                            // A. Grid & Y-Axis Labels
                            GridBackground(width: chartWidth, height: chartHeight)
                            
                            // B. The Line Graphs
                            if dataPoints.count > 1 {
                                // 1. Score Line (Cyan)
                                GraphPath(width: chartWidth, height: chartHeight, keyPath: \.score)
                                    .trim(from: 0, to: animationProgress)
                                    .stroke(
                                        LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing),
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                    )
                                    .shadow(color: .cyan.opacity(0.3), radius: 4, x: 0, y: 2)
                                
                                // 2. Confidence Line (Orange) - only if data exists
                                if dataPoints.contains(where: { $0.confidenceScore != nil }) {
                                    GraphPath(width: chartWidth, height: chartHeight, keyPath: \.confidenceScore)
                                        .trim(from: 0, to: animationProgress)
                                        .stroke(
                                            LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing),
                                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                        )
                                        .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                            }
                            
                            // C. Data Points (Dots)
                            ForEach(Array(dataPoints.enumerated()), id: \.element.id) { index, point in
                                let x = getX(index: index, width: chartWidth, count: dataPoints.count)
                                let y = getY(score: point.score, height: chartHeight)
                                let delay = animDuration * (Double(index) / Double(max(dataPoints.count - 1, 1)))
                                
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 8, height: 8)
                                    .overlay(Circle().stroke(Color.cyan, lineWidth: 2))
                                    // Make hit area larger (30x30 invisible)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Circle())
                                    .onTapGesture {
                                        selectedPointID = point.id
                                    }
                                    .position(x: x, y: y)
                                    .scaleEffect(showDots ? 1 : 0) // Triggered by showDots
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6).delay(delay), value: showDots) // Staggered delay
                                
                                // Confidence Dots
                                if let conf = point.confidenceScore {
                                    let yConf = getY(score: conf, height: chartHeight)
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 6, height: 6)
                                        .overlay(Circle().stroke(Color.orange, lineWidth: 2))
                                        .frame(width: 44, height: 44)
                                        .contentShape(Circle())
                                        .onTapGesture {
                                            selectedPointID = point.id
                                        }
                                        .position(x: x, y: yConf)
                                        .scaleEffect(showDots ? 1 : 0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6).delay(delay), value: showDots)
                                }
                                
                                // Selected Label
                                if selectedPointID == point.id {
                                    VStack(spacing: 4) {
                                        // Lesson Name (if available)
                                        if let map = extraDataMap, let name = map[point.id] {
                                            Text(name)
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.primary)
                                                .multilineTextAlignment(.center)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        
                                        // Date & Time
                                        Text(point.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        
                                        HStack(spacing: 6) {
                                            ScoreLabel(score: point.score, color: .cyan)
                                            if let conf = point.confidenceScore {
                                                ScoreLabel(score: conf, color: .orange)
                                            }
                                        }
                                    }
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.1), radius: 4)
                                    // Apply offset directly to position X
                                    .position(x: x + tooltipOffset(index: index, count: dataPoints.count), y: y - 55)
