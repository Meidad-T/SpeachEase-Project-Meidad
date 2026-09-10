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
