import SwiftUI
import SpriteKit
import GameplayKit

// MARK: - Game View
struct VocabularyTowerGameView: View {
    @StateObject private var engine = VocabGameEngine()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // 1. SpriteKit Scene (Background & Gameplay)
            SpriteView(scene: engine.scene)
                .ignoresSafeArea()
            
            // 2. UI Overlay
            VStack {
                // Top Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill") // Using iOS system icon
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    
                    Spacer()
                    
                    // Score
                    Text("\(engine.score)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                }
                .padding()
                
                // Question Area (Only if game active)
                if engine.gameState == .playing {
                    VStack(spacing: 20) {
                        // Question Card (Clickable for Help)
                        if let question = engine.currentQuestion {
                            Button {
                                engine.showHelp(for: question.text)
                            } label: {
                                Text(makeAttributedString(from: question.text))
                                    .font(.system(.title2, design: .rounded, weight: .bold)) // Slightly smaller to fit
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 24)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                            }
                            .alert("Hint", isPresented: $engine.showHint) {
                                Button("Got it", role: .cancel) { }
                            } message: {
                                Text(engine.hintText)
                            }
                        }
                        
                        // Options Grid
                        HStack(spacing: 16) {
                            if let question = engine.currentQuestion {
                                ForEach(0..<question.options.count, id: \.self) { index in
                                    Button {
                                        engine.submitAnswer(index)
                                    } label: {
                                        Text(question.options[index])
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(.regularMaterial) // Liquid Glass effect
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 300) // Moved down to clear the crane/box area
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
            }
            
            // 3. Start / Game Over Screens
            if engine.gameState == .ready {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Vocabulary Tower")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(.yellow)
                    
                    Text("Build the tallest tower by answering grammar questions correctly!")
                        .font(.body)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button {
                        withAnimation {
                            engine.startGame()
                        }
                    } label: {
                        Text("Start Game")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(Color.yellow)
                            .cornerRadius(30)
                    }
                }
            } else if engine.gameState == .gameOver {
                Color.black.opacity(0.7).ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Game Over")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Score: \(engine.score)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.yellow)
                    
                    Button {
                        withAnimation {
                            engine.resetGame()
                        }
                    } label: {
                        Text("Try Again")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
    
    // Attributed String Helper for Underlining keywords
    func makeAttributedString(from text: String) -> AttributedString {
        var attributed = AttributedString(text)
        
        if let range = attributed.range(of: "Synonym") {
            attributed[range].underlineStyle = .single
            attributed[range].foregroundColor = .yellow
        }
        if let range = attributed.range(of: "Antonym") {
            attributed[range].underlineStyle = .single
            attributed[range].foregroundColor = .yellow
        }
        
        return attributed
    }
}

// MARK: - Game Engine
@MainActor
class VocabGameEngine: ObservableObject {
    enum GameState {
        case ready, playing, gameOver
    }
    
    @Published var score = 0
    @Published var gameState: GameState = .ready
    @Published var currentQuestion: Question?
    @Published var showHint = false
    @Published var hintText = ""
    
    let scene: TowerScene
    private let generator = QuestionGenerator()
    
    init() {
        self.scene = TowerScene()
        self.scene.scaleMode = .resizeFill
        
        // Connect scene back to engine
        self.scene.onGameOver = { [weak self] in
            DispatchQueue.main.async {
                self?.gameState = .gameOver
            }
        }
    }
    
    func showHelp(for text: String) {
        if text.starts(with: "Synonym") {
            hintText = "A Synonym is a word that means exactly or nearly the same as another word.\n\nExample: 'Happy' is a synonym for 'Joyful'."
            showHint = true
        } else if text.starts(with: "Antonym") {
            hintText = "An Antonym is a word opposite in meaning to another.\n\nExample: 'Hot' is an antonym for 'Cold'."
            showHint = true
        }
    }
    
    func startGame() {
        score = 0
        gameState = .playing
        scene.resetScene()
        nextQuestion()
    }
    
    func resetGame() {
        startGame()
    }
    
    func nextQuestion() {
        currentQuestion = generator.generate()
    }
    
    func submitAnswer(_ index: Int) {
        guard let question = currentQuestion else { return }
        
        if index == question.correctIndex {
            // Correct! Drop box.
            scene.dropBox() // Drop at current crane position
            score += 1
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            nextQuestion()
        } else {
            // Incorrect
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            // Penalty? Maybe shake screen. defaulting to no penalty but no drop.
        }
    }
}

// MARK: - SpriteKit Scene
class TowerScene: SKScene, SKPhysicsContactDelegate {
    
    var onGameOver: (() -> Void)?
    
    private var crane: SKNode?
    private var craneBase: SKNode?
    private var hook: SKNode?
    
    // Physics Categories
    private let CategoryBox: UInt32 = 0x1 << 0
    private let CategoryGround: UInt32 = 0x1 << 1
    private let CategoryDeadZone: UInt32 = 0x1 << 2
    
    // State
    private var isGameActive = false
    private var lastBox: SKNode?
    private var camTargetY: CGFloat = 0
    
    // Camera
    private let cameraNode = SKCameraNode()
    
    // Config
    private let boxSize = CGSize(width: 150, height: 150)
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
        backgroundColor = .clear
        
        // Setup Camera
        addChild(cameraNode)
        camera = cameraNode
        // Default camera position is center of screen
        camTargetY = size.height/2
        cameraNode.position = CGPoint(x: size.width/2, y: camTargetY)
        
        // Background - Day City (Attached to Camera to stay static/parallax)
        setupBackground()
        
        // Ground - In World Space
        let ground = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: 100))
        ground.position = CGPoint(x: size.width/2, y: 50)
        ground.fillColor = UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
        ground.strokeColor = .clear
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 2, height: 100))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = CategoryGround
        ground.zPosition = 1
        ground.name = "ground"
        addChild(ground)
        
        setupCrane()
    }
    
    func setupBackground() {
        // Sky (Stays on Camera)
        let sky = SKSpriteNode(color: UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0), size: size) // Nice Blue
        sky.zPosition = -20
        cameraNode.addChild(sky)
        
        // Clouds (World Space - so we pass them)
        // Generate clouds up to a high height
        for i in 0..<20 {
            let cloud = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 100...200), height: CGFloat.random(in: 40...80)))
            cloud.fillColor = .white.withAlphaComponent(0.6)
            cloud.strokeColor = .clear
            let yPos = CGFloat.random(in: 100 ... 5000) // Spread way up
            cloud.position = CGPoint(
                x: CGFloat.random(in: -size.width/2 ... size.width/2),
                y: yPos
            )
            cloud.zPosition = -15
            addChild(cloud) // Add to Scene, not Camera
        }
        
        // City Skyline (World Space - Anchored at bottom)
        // This means as camera goes up, city goes down/off-screen. Correct.
        let cityNode = SKNode()
        cityNode.position = CGPoint(x: size.width/2, y: 50) // On Ground
        cityNode.zPosition = -10
        addChild(cityNode) // Add to Scene
        
        for i in -2...2 { // 5 buildings covering width centered at X
            let w = size.width / 4
            let h = CGFloat.random(in: 150...400)
            let x = CGFloat(i) * w
            
            let building = SKShapeNode(rectOf: CGSize(width: w * 0.9, height: h))
            building.fillColor = UIColor(white: 0.3 + CGFloat.random(in: 0...0.2), alpha: 1.0) // Varied Grey
            building.strokeColor = .clear
            building.position = CGPoint(x: x, y: h/2) // Anchor bottom
            
            // Windows
            let rows = Int(h / 30)
            let cols = Int(w / 30)
            for r in 0..<rows {
                for c in 0..<cols {
                    if Double.random(in: 0...1) > 0.3 {
                        let win = SKShapeNode(rectOf: CGSize(width: 10, height: 15))
                        win.fillColor = .yellow.withAlphaComponent(0.3) // Lit windows
                        win.strokeColor = .clear
                        let wx = -w/2 + 20 + CGFloat(c) * 20
                        let wy = -h/2 + 20 + CGFloat(r) * 30
                        win.position = CGPoint(x: wx, y: wy)
                        building.addChild(win)
                    }
                }
            }
            
            cityNode.addChild(building)
        }
    }
    
    func setupCrane() {
        crane = SKNode()
        // Position relative to Camera! 
        // Camera origin is center. Top of screen is y = +height/2
        crane?.position = CGPoint(x: 0, y: size.height/2 - 180)
        cameraNode.addChild(crane!) // Attach to camera so it stays on top!
        
        // Held Crate Visual (No physics)
        let crateVisual = createCrateNode()
        crateVisual.position = CGPoint(x: 0, y: -60)
        crane?.addChild(crateVisual)
        
        // Rope
        let rope = SKShapeNode(rectOf: CGSize(width: 6, height: 100))
        rope.position = CGPoint(x: 0, y: 0)
        rope.fillColor = .black
        rope.strokeColor = .clear
        crane?.addChild(rope)
        
        // Aiming Line (Faint dashed line)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: -100)) // Start below box
        path.addLine(to: CGPoint(x: 0, y: -2000)) // Go way down
        
        let pattern: [CGFloat] = [10.0, 10.0]
        let dashedPath = path.copy(dashingWithPhase: 0, lengths: pattern)
        
        let line = SKShapeNode(path: dashedPath)
        line.strokeColor = .white.withAlphaComponent(0.3)
        line.lineWidth = 2
        line.zPosition = -5 // Behind box
        crane?.addChild(line)
    }
    
    func resetScene() {
        children.filter { $0.name == "box" }.forEach { $0.removeFromParent() }
        isGameActive = true
        lastBox = nil
        
        // Reset Camera Target State
        camTargetY = size.height / 2
