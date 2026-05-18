import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    var filename: String
    var loopMode: LottieLoopMode = .loop
    var speed: CGFloat = 1.0
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        let animationView = LottieAnimationView()
        
        
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.animationSpeed = speed
        animationView.backgroundBehavior = .pauseAndRestore
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        // Async Load for DotLottie support
        Task {
            do {
                // Attempt to load .lottie file
                let dotLottie = try await DotLottieFile.named(filename)
                
                await MainActor.run {
                    // Remove the placeholder view
                    animationView.removeFromSuperview()
                    
                    // Create new view with DotLottie support
                    let newAnimationView = LottieAnimationView(dotLottie: dotLottie)
                    newAnimationView.contentMode = .scaleAspectFit
                    newAnimationView.loopMode = loopMode
                    newAnimationView.animationSpeed = speed
                    newAnimationView.backgroundBehavior = .pauseAndRestore
                    newAnimationView.translatesAutoresizingMaskIntoConstraints = false
                    
                    view.addSubview(newAnimationView)
                    
                    NSLayoutConstraint.activate([
                        newAnimationView.heightAnchor.constraint(equalTo: view.heightAnchor),
                        newAnimationView.widthAnchor.constraint(equalTo: view.widthAnchor)
                    ])
                    
                    newAnimationView.play()
                }
            } catch {
                // Fallback to standard .json Lottie on the existing view
                await MainActor.run {
                    if let animation = LottieAnimation.named(filename) {
                        animationView.animation = animation
                        animationView.play()
                    } else {
                        print("LottieView: Could not load animation '\(filename)' (neither .lottie nor .json found).")
                    }
                }
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        // No updates needed for now
    }
}
