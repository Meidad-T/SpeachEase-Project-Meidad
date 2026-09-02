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
    
