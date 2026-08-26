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
    let color: Color
    let size: BentoSize

    var isiPad: Bool {
        sizeClass == .regular
    }

    

    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(isiPad ? .largeTitle : .title)
                    .frame(width: isiPad ? 50 : 40, height: isiPad ? 50 : 40) // Fixed frame for consistent alignment
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(isiPad ? 16 : 12)
                    .background(.white.opacity(0.2), in: Circle())
                
                Spacer()
                
                // Optional arrow or indicator
                Image(systemName: "arrow.up.right")
                    .font(isiPad ? .headline : .subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(title)
