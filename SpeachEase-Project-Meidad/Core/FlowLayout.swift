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
