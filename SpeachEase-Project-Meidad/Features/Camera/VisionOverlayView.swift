import UIKit
import Vision
import AVFoundation

// MARK: - Safe Data Transfer
struct OverlayData: Sendable {
    let bodyChains: [[CGPoint]]
    let handChains: [[CGPoint]]
    let faceChains: [FacePath]
    let imageSize: CGSize
    
    struct FacePath: Sendable {
        let points: [CGPoint]
        let isClosed: Bool
    }
}

class VisionOverlayView: UIView {
    
    private var data: OverlayData?
    
    // Visibility Toggles
    var showHandLines: Bool = true { didSet { setNeedsDisplay() } }
    var showBodyLines: Bool = true { didSet { setNeedsDisplay() } }
    var showFaceLines: Bool = true { didSet { setNeedsDisplay() } }
    
    // Custom Colors
    var handColor: UIColor = .cyan { didSet { setNeedsDisplay() } }
    var bodyColor: UIColor = .green { didSet { setNeedsDisplay() } }
    var faceColor: UIColor = .yellow { didSet { setNeedsDisplay() } }
    
    weak var previewLayer: AVCaptureVideoPreviewLayer? 
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with data: OverlayData) {
        self.data = data
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let data = data else { return }
        guard data.imageSize.width > 0 && data.imageSize.height > 0 else { return }
        
        context.clear(rect)
        
        // Calculate Aspect Fill Rect
        let viewSize = bounds.size
        let imageSize = data.imageSize
        let imageAspectRatio = imageSize.width / imageSize.height
        let viewAspectRatio = viewSize.width / viewSize.height
        
        var scale: CGFloat
        if viewAspectRatio > imageAspectRatio {
             scale = viewSize.width / imageSize.width
        } else {
             scale = viewSize.height / imageSize.height
        }
        
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        let xOffset = (viewSize.width - scaledWidth) / 2
        let yOffset = (viewSize.height - scaledHeight) / 2
        
        let drawingRect = CGRect(x: xOffset, y: yOffset, width: scaledWidth, height: scaledHeight)
        
        // Draw Body
        if showBodyLines {
            context.setStrokeColor(bodyColor.cgColor)
            context.setLineWidth(3.0)
            for chain in data.bodyChains {
                drawChain(chain, context: context, drawingRect: drawingRect, drawDots: true, color: bodyColor)
            }
        }
        
        // Draw Hands
        if showHandLines {
            context.setStrokeColor(handColor.cgColor)
            context.setLineWidth(2.0)
            for chain in data.handChains {
                drawChain(chain, context: context, drawingRect: drawingRect, drawDots: true, color: handColor)
            }
        }
        
        // Draw Faces
        if showFaceLines {
            context.setStrokeColor(faceColor.cgColor)
            context.setLineWidth(1.5)
            for path in data.faceChains {
                drawPath(path.points, closed: path.isClosed, context: context, drawingRect: drawingRect)
            }
        }
    }
    
    private func convert(_ point: CGPoint, to drawingRect: CGRect) -> CGPoint {
        // Point is (0..1) with (0,0) at Bottom-Left (Vision standard)
        // Screen Y = Rect.minY + (1 - point.y) * Rect.height
        // Screen X = Rect.minX + point.x * Rect.width
        
        let screenX = drawingRect.minX + point.x * drawingRect.width
        let screenY = drawingRect.minY + (1 - point.y) * drawingRect.height
        return CGPoint(x: screenX, y: screenY)
    }
    
    private func drawChain(_ points: [CGPoint], context: CGContext, drawingRect: CGRect, drawDots: Bool, color: UIColor) {
        guard !points.isEmpty else { return }
        
        var previousPoint: CGPoint?
        
        for point in points {
            let screenPoint = convert(point, to: drawingRect)
            
            if let prev = previousPoint {
                context.move(to: prev)
                context.addLine(to: screenPoint)
                context.strokePath()
            }
            
            if drawDots {
                context.setFillColor(color.withAlphaComponent(0.6).cgColor)
                context.fillEllipse(in: CGRect(x: screenPoint.x - 4, y: screenPoint.y - 4, width: 8, height: 8))
            }
            
