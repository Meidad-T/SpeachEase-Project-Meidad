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
