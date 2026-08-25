import SwiftUI

/// A custom layout that arranges subviews in a flow (left-to-right, wrapping to new lines).
struct FlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    init(spacing: CGFloat = 8, lineSpacing: CGFloat = 8) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = generateRows(proposal: proposal, subviews: subviews)
        
        // Calculate total height
        var totalHeight: CGFloat = 0
        if let lastRow = rows.last {
            totalHeight = lastRow.yOffset + lastRow.height
        }
        
        return CGSize(width: proposal.width ?? 0, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = generateRows(proposal: proposal, subviews: subviews)
        
        for row in rows {
            for item in row.items {
                let position = CGPoint(
                    x: bounds.minX + item.xOffset,
                    y: bounds.minY + row.yOffset
                )
                
                subviews[item.index].place(
                    at: position,
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: item.width, height: item.height)
                )
            }
        }
    }
    
    // Helper to calculate rows
    private func generateRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        let maxWidth = proposal.width ?? 0
        
        var currentRow = Row(yOffset: 0, height: 0, items: [])
        var currentX: CGFloat = 0
        
        for index in subviews.indices {
            let subview = subviews[index]
            let size = subview.sizeThatFits(ProposedViewSize(width: nil, height: nil))
            
            // Check if we need a new line
            if currentX + size.width > maxWidth && !currentRow.items.isEmpty {
                // Finish current row
