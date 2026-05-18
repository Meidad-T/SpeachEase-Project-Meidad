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
                .font(isiPad ? .title : .title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(2)
            
            Text(subtitle)
                .font(isiPad ? .headline : .caption)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
        }
        .padding(isiPad ? 24 : 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        // Fixed heights based on desired grid look
        .frame(height: isiPad ? 240 : 160) 
        .background(
            LinearGradient(
                colors: [color.opacity(0.9), color],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: isiPad ? 32 : 24))
        .shadow(color: color.opacity(0.3), radius: isiPad ? 12 : 8, x: 0, y: isiPad ? 6 : 4)

        
        // Ensure the entire area is hoverable
        .contentShape(RoundedRectangle(cornerRadius: isiPad ? 32 : 24)) 


    }
}
