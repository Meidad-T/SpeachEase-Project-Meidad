import SwiftUI

extension Color {
    static var adaptiveCardBackground: Color {
        Color(UIColor { traitCollection in
            // Custom lighter dark color for better visibility: #2C2C2E (approx systemGray5)
            // Light mode: Pure white
            return traitCollection.userInterfaceStyle == .dark ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) : .white
        })
    }
}


extension View {
    // Helper to safely apply iOS 17 modifiers if available, or fallback
    @ViewBuilder
    func scrollBoundaries() -> some View {
        if #available(iOS 17.0, *) {
            self.environment(\.layoutDirection, .leftToRight) // Dummy example, actual anchor below
                 .defaultScrollAnchor(.bottom)
        } else {
            self
        }
    }
}
