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
