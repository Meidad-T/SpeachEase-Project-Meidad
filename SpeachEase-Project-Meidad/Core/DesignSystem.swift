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
