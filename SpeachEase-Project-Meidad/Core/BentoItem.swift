import SwiftUI

enum BentoSize {
    case square
    case wide
    case tall // Added for flexibility, though main plan uses square/wide
}

struct BentoItem: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    let id: String
    let title: String
    let subtitle: String
    let icon: String
