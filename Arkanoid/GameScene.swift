//
//  GameScene.swift
//  Arkanoid
//
//  Created by Fco. Javier Guerrero Carmona on 12/08/2020.
//  Copyright © 2020 Fco. Javier Guerrero Carmona. All rights reserved.
//

import SpriteKit
import CoreMotion

enum CollisionType: UInt32 {
    case paddle = 1
    case wall = 2
    case ball = 4
    case bottom = 8
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var motionManager: CMMotionManager?
    var paddle: SKSpriteNode!
    var wall: SKSpriteNode!
    var ball: SKSpriteNode!
    var background: SKSpriteNode!
    var wallArray = [SKSpriteNode]()

    var scoreLabel: SKLabelNode!
    var levelLabel: SKLabelNode!
    var gameOverLabel: SKSpriteNode!
    
    var node = SKSpriteNode()
    var level: Int = 1
    var isGameOver = false
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates()
        
        background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        let bottomRect = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.size.width, height: 1)
        let borderBottom = SKNode()
        borderBottom.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
        borderBottom.name = "bottom"
        addChild(borderBottom)
        borderBottom.physicsBody?.categoryBitMask = CollisionType.bottom.rawValue
        borderBottom.physicsBody?.collisionBitMask = 0
        borderBottom.physicsBody?.contactTestBitMask = CollisionType.ball.rawValue
        
        paddle = SKSpriteNode(imageNamed: "bar")
        paddle.name = "paddle"
        paddle.position = CGPoint(x: 512, y: 20)
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.size)
        paddle.physicsBody?.allowsRotation = false
        paddle.physicsBody?.isDynamic = true
        
        paddle.physicsBody?.categoryBitMask = CollisionType.paddle.rawValue
        paddle.physicsBody?.collisionBitMask = 0
        paddle.physicsBody?.contactTestBitMask = CollisionType.ball.rawValue
        
        addChild(paddle)
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    
        loadLevel()
        launch()
        createScore()

    }
    
    func createScore(){
        scoreLabel = SKLabelNode(fontNamed: "Marker Felt")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 736)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
    }

    
    override func update(_ currentTime: TimeInterval) {
        if let accelerometerData = motionManager?.accelerometerData {
            paddle.position.x += CGFloat(accelerometerData.acceleration.y * -50)
        }
        
        if paddle.position.x < frame.minX {
            paddle.position.x = frame.minX
        } else if paddle.position.x > frame.maxX {
            paddle.position.x = frame.maxX
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let prevTouchlocation = touch.previousLocation(in: self)
        
        let newXPos = paddle.position.x + (location.x - prevTouchlocation.x)
        paddle.position = CGPoint(x: newXPos, y: paddle.position.y)
    }
    
    func loadLevel(){
        // Find the txt in the bundle
        guard let levelURL = Bundle.main.url(forResource: "level\(level)", withExtension: "txt") else {
            fatalError("Could not find level\(level).txt in the app bundle")
        }
        // Load the file content to a String
        guard let levelString = try? String(contentsOf: levelURL) else {
            fatalError("Could not load level\(level).txt in the app bundle")
        }
        
        //print(levelString)
        let lines = levelString.components(separatedBy: "\n")
        //print(lines)
        
        for (row, line) in lines.reversed().enumerated() {
            //print("Row: \(row). Line: \(line)")
            for (column, letter) in line.enumerated() {
                //print("Column: \(column). Letter: \(letter)")
                let position = CGPoint(x: (64*column)+32, y: (64*row)+32)
                
                if letter == "w" {
                    wall = SKSpriteNode(imageNamed: "Wall")
                    wall.name = "wall"
                    wall.position = position
                    wall.size.height = 32
                    wall.size.width = 60
                    
                    wall.physicsBody = SKPhysicsBody(rectangleOf: wall.size)
                    wall.physicsBody?.categoryBitMask = CollisionType.wall.rawValue
                    wall.physicsBody?.isDynamic = false
                    addChild(wall)
                    
                    wallArray.append(wall)
                } else if letter == " "{
                    // do nothing - empty space
                } else {
                    fatalError("Unknown level letter: \(letter)")
                }
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else {return}
        guard let nodeB = contact.bodyB.node else {return}
        
        if nodeA == ball {
            ballCollided(with: nodeB)
        } else if nodeB == ball {
            ballCollided(with: nodeA)
        }
    }
    
    func ballCollided(with node: SKNode) {
        if node.name == "wall" {
            ball.physicsBody?.applyImpulse(CGVector(dx: 2, dy: 2))
            node.removeFromParent()
            wallArray.removeLast()
            score += 5
            
            if wallArray.count == 0 {
                print("Has ganado")
                ball.removeFromParent()
                level += 1
                showNextLevelLabel()
                //loadLevel()
            }
        } else if node.name == "paddle" {
            ball.physicsBody?.applyImpulse(CGVector(dx: 2, dy: 5))
        } else if node.name == "bottom" {
            print("GAME OVER")
            ball.removeFromParent()
            gameOver()

        }
    }
    
    func launch(){
        ball = SKSpriteNode(imageNamed: "ball")
        ball.name = "ball"
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2.0)
        ball.physicsBody?.restitution = 1
        ball.physicsBody?.allowsRotation = false
        ball.physicsBody?.linearDamping = 0
        ball.physicsBody?.friction = 0
        ball.physicsBody?.categoryBitMask = CollisionType.ball.rawValue
        ball.physicsBody?.collisionBitMask = CollisionType.wall.rawValue | CollisionType.paddle.rawValue | CollisionType.bottom	.rawValue
        ball.physicsBody?.contactTestBitMask = CollisionType.wall.rawValue | CollisionType.paddle.rawValue
        ball.position = CGPoint(x: 512, y: 40)
        ball.zPosition = 1
        addChild(ball)
        
        let impulse = CGVector(dx: 20, dy: -20)
        ball.physicsBody?.applyImpulse(impulse)
    }
    
    func showNextLevelLabel(){
        levelLabel = SKLabelNode(fontNamed: "Marker Felt")
        levelLabel.text = "HAS GANADO: \(level)"
        levelLabel.position = CGPoint(x: 484, y: 512)
        levelLabel.fontSize = 40
        levelLabel.zPosition = 3
        levelLabel.run(SKAction.fadeOut(withDuration: 3.5))
        addChild(levelLabel)
    }
    
    func gameOver(){
        gameOverLabel = SKSpriteNode(imageNamed: "GAME_OVER")
        gameOverLabel.position = CGPoint(x: 512, y: 384)
        gameOverLabel.zPosition = 3
        addChild(gameOverLabel)
        paddle.removeFromParent()
        
    }
    
}
