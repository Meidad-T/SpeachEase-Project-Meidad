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
                rows.append(currentRow)
                
                // Start new row
                let nextY = currentRow.yOffset + currentRow.height + lineSpacing
                currentRow = Row(yOffset: nextY, height: 0, items: [])
                currentX = 0
            }
            
            // Add item to current row
            let item = RowItem(index: index, width: size.width, height: size.height, xOffset: currentX)
            currentRow.items.append(item)
            
            // Update row stats
            currentRow.height = max(currentRow.height, size.height)
            currentX += size.width + spacing
        }
        
        // Append the last row
        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    // Helper structures
    private struct Row {
        var yOffset: CGFloat
        var height: CGFloat
        var items: [RowItem]
    }
    
    private struct RowItem {
        let index: Int
        let width: CGFloat
        let height: CGFloat
        let xOffset: CGFloat
    }
}
