import SwiftUI

// MARK: - App Theme
struct AppTheme {
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let accent = Color(red: 0.2, green: 0.8, blue: 1.0) // Cyan-ish
    
    // Gradients
    static let darkMeshColors: [Color] = [
        Color(hex: "0F2027"), // Dark
        Color(hex: "203A43"), // Teal-Dark
        Color(hex: "2C5364"), // Blue-Dark
        Color.purple.opacity(0.5)
    ]
    
    static let lightMeshColors: [Color] = [
        Color.white,
        Color(hex: "E0F7FA"), // Light Cyan
        Color(hex: "E1BEE7"), // Light Purple
        Color.blue.opacity(0.1)
    ]
}

// MARK: - Glass Card Container
struct GlassCard<Content: View>: View {
    var content: Content
    var padding: CGFloat = 20
    @Environment(\.colorScheme) var colorScheme
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                colorScheme == .dark ? .ultraThinMaterial : .regularMaterial
            )
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(
                        colorScheme == .dark ? .white.opacity(0.15) : .black.opacity(0.05),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05),
                radius: 20,
                x: 0,
                y: 10
            )
    }
}

// MARK: - Mesh Background
struct MeshBackground: View {
    @State private var animate = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Base Layer
            (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
            
            // Moving Orbs
            GeometryReader { geo in
                ZStack {
                    // Blob 1: Deep Orange (was Purple)
                    Circle()
                        .fill(colorScheme == .dark ? Color(hex: "D84315").opacity(0.5) : Color.purple.opacity(0.2))
                        .frame(width: geo.size.width * 0.8)
                        .blur(radius: 60)
                        .offset(x: animate ? -30 : 50, y: animate ? -50 : 20)
                    
                    // Blob 2: Vibrant Orange (was Blue)
                    Circle()
                        .fill(colorScheme == .dark ? Color(hex: "EF6C00").opacity(0.4) : Color.blue.opacity(0.2))
                        .frame(width: geo.size.width * 0.8)
                        .blur(radius: 60)
                        .offset(x: animate ? 50 : -20, y: animate ? 20 : -50)
                    
                    // Blob 3: Peach (was Cyan)
                    Circle()
                        .fill(colorScheme == .dark ? Color(hex: "FFCC80").opacity(0.3) : Color.cyan.opacity(0.2))
                        .frame(width: geo.size.width * 0.6)
                        .blur(radius: 50)
                        .offset(x: animate ? -20 : 100, y: animate ? 100 : -20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

// MARK: - Activity Ring
struct ActivityRing: View {
    var progress: Double // 0.0 to 1.0
    var color: Color = .blue
    
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 20)
