//
//  GameScene.swift
//  Commotion
//
//  Created by Eric Larson on 9/6/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import SpriteKit
import CoreMotion

@available(iOS 10.0, *)
class GameScene: SKScene, SKPhysicsContactDelegate {
    let roll_threshold = 0.3
    var spaceship_position = CGFloat(200.0)
    let min_spaceship_position = CGFloat(50.0)
    let max_spaceship_position = CGFloat(325.0)

    //@IBOutlet weak var scoreLabel: UILabel!
    
    // MARK: Raw Motion Functions
    let motion = CMMotionManager()
    func startMotionUpdates(){
        // some internal inconsistency here: we need to ask the device manager for device
        
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 0.1
            self.motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: self.handleMotion )
        }
    }
    
    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
        self.physicsWorld.gravity = .zero
        if((motionData?.attitude.roll)! > roll_threshold){
            if(spaceship_position < max_spaceship_position){
                spaceship_position += 10
            }
        }else if((motionData?.attitude.roll)! < -roll_threshold){
            if(spaceship_position > min_spaceship_position){
                spaceship_position -= 10
            }
        }
        
        let actionMove = SKAction.move(to: CGPoint(x: spaceship_position, y: size.height * 0.1),
                                       duration: TimeInterval(0.15))
        spaceship.run(actionMove)
    }
    
    // MARK: View Hierarchy Functions
    let spinBlock = SKSpriteNode()
    let scoreLabel = SKLabelNode()
    var score:Int = 0 {
        willSet(newValue){
            DispatchQueue.main.async{
                self.scoreLabel.text = "Score: \(newValue)"
            }
        }
    }
    
    let ammoCountLabel = SKLabelNode()
    var ammoCount:Int = 10 {
        willSet(newValue){
            DispatchQueue.main.async{
                self.ammoCountLabel.text = "Ammo: \(newValue)"
            }
        }
    }
    
    struct PhysicsCategory {
        static let none:        UInt32 = 0
        static let all:         UInt32 = UInt32.max
        static let alien:       UInt32 = 0b1        // 1
        static let asteroid:    UInt32 = 0b10       // 2
        static let laser:       UInt32 = 0b11       // 3
        static let spaceship:   UInt32 = 0b100      // 4
    }
    
    let spaceship = SKSpriteNode(imageNamed: "spaceship")
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        
        // start motion for gravity
        self.startMotionUpdates()
        
        self.addSpaceship()
        
        self.addScore()
        self.addAmmoCount()
        
//        self.ammoCount = UserDefaults.standard.integer(forKey: "steps")
        
        run(SKAction.repeatForever(
          SKAction.sequence([
            SKAction.run(addAlien),
            SKAction.wait(forDuration: 1.0)
            ])
        ))
        
        run(SKAction.repeatForever(
          SKAction.sequence([
            SKAction.run(addAsteroid),
            SKAction.wait(forDuration: 1.5)
            ])
        ))
        
//        self.addBackground()
    }
    
    // MARK: Create Sprites Functions
    func addScore(){
        
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = SKColor.white
        scoreLabel.position = CGPoint(x: frame.midX - 125, y: frame.minY+10)
        
        addChild(scoreLabel)
    }
    
    func addAmmoCount(){
        
        ammoCountLabel.text = "Ammo: \(ammoCount)"
        ammoCountLabel.fontSize = 20
        ammoCountLabel.fontColor = SKColor.white
        ammoCountLabel.position = CGPoint(x: frame.midX + 125, y: frame.minY+10)
        
        addChild(ammoCountLabel)
    }
    
    func addSpaceship(){
        spaceship.position = CGPoint(x: size.width * 0.5, y: size.height * 0.1)
        spaceship.scale(to: CGSize(width: 50, height: 50))
        spaceship.physicsBody = SKPhysicsBody(rectangleOf:spaceship.size)
        spaceship.physicsBody?.isDynamic = false
        spaceship.physicsBody?.categoryBitMask = PhysicsCategory.spaceship
        self.addChild(spaceship)
    }

//  MARK: Monster Example
    func addAlien() {
        let alien = SKSpriteNode(imageNamed: "alien")
        alien.scale(to: CGSize(width: 50, height: 40))
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size) // 1
        alien.physicsBody?.isDynamic = true // 2
        alien.physicsBody?.categoryBitMask = PhysicsCategory.alien // 3
        alien.physicsBody?.contactTestBitMask = PhysicsCategory.laser // 4
        alien.physicsBody?.collisionBitMask = PhysicsCategory.none // 5



        // Determine where to spawn the monster along the Y axis
        let actualY = random(min: alien.size.height + 400, max: size.height - alien.size.height/2)

        // Position the monster slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
        alien.position = CGPoint(x: size.width + alien.size.width/2, y: actualY)

        // Add the monster to the scene
        addChild(alien)

        // Determine speed of the monster
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))

        // Create the actions
        let actionMove = SKAction.move(to: CGPoint(x: -100, y: actualY),
                                     duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        alien.run(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
    
    func addAsteroid() {

        // Create sprite
        let asteroid = SKSpriteNode(imageNamed: "asteroid")
        asteroid.scale(to: CGSize(width: 40, height: 40))
        asteroid.physicsBody = SKPhysicsBody(rectangleOf: asteroid.size) // 1
        asteroid.physicsBody?.isDynamic = true // 2
        asteroid.physicsBody?.categoryBitMask = PhysicsCategory.asteroid // 3
        asteroid.physicsBody?.contactTestBitMask = PhysicsCategory.laser // 4
        asteroid.physicsBody?.collisionBitMask = PhysicsCategory.none // 5


        // Determine where to spawn the monster along the Y axis
        let actualY = random(min: asteroid.size.height + 400, max: size.height/2 - asteroid.size.height/2 - 200)

        // Position the monster slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
        asteroid.position = CGPoint(x: 0 - asteroid.size.width, y: actualY)

        // Add the monster to the scene
        addChild(asteroid)

        // Determine speed of the monster
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))

        // Create the actions
        let actionMove = SKAction.move(to: CGPoint(x: size.width + asteroid.size.width, y: actualY),
                                     duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        asteroid.run(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
    
    @available(iOS 11.0, *)
    func fireLaser(){
        if ammoCount > 0 {
            let laser = SKSpriteNode(imageNamed: "laser")
            laser.scale(to: CGSize(width: 10, height: 35))
            laser.position = spaceship.position
            
            laser.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: laser.size.width, height: laser.size.height))
            laser.physicsBody?.isDynamic = true
            laser.physicsBody?.categoryBitMask = PhysicsCategory.laser
            laser.physicsBody?.contactTestBitMask = PhysicsCategory.alien
            laser.physicsBody?.collisionBitMask = PhysicsCategory.none
            laser.physicsBody?.usesPreciseCollisionDetection = true

            addChild(laser)
            
            let destination = CGPoint(x: spaceship.position.x, y: spaceship.position.y + 1000)

            // 9 - Create the actions
            let actionMove = SKAction.move(to: destination, duration: 2.0)
            let actionMoveDone = SKAction.removeFromParent()
            laser.run(SKAction.sequence([actionMove, actionMoveDone]))
            ammoCount -= 1
            
            if ammoCount == 0{
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                let gameOverScene = GameOverScene(size: self.size, score: self.score)
                view?.presentScene(gameOverScene, transition: reveal)
            }
        }
    }
    
    func laserDidCollideWithAlien(laser: SKSpriteNode, alien: SKSpriteNode) {
        self.score += 1
        laser.removeFromParent()
        alien.removeFromParent()
    }
    
    func laserDidCollideWithAsteroid(laser: SKSpriteNode) {
        laser.removeFromParent()
    }
    
    // MARK: =====Delegate Functions=====
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if #available(iOS 11.0, *) {
            self.fireLaser()
        } else {
            // Fallback on earlier versions
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        // 1
         var firstBody: SKPhysicsBody
         var secondBody: SKPhysicsBody
         if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
           firstBody = contact.bodyA
           secondBody = contact.bodyB
         } else {
           firstBody = contact.bodyB
           secondBody = contact.bodyA
         }
        
         // 2
         if ((firstBody.categoryBitMask & PhysicsCategory.alien != 0) &&
             (secondBody.categoryBitMask & PhysicsCategory.laser != 0)) {
           if let alien = firstBody.node as? SKSpriteNode,
             let laser = secondBody.node as? SKSpriteNode {
             laserDidCollideWithAlien(laser: laser, alien: alien)
           }
         }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.asteroid != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.laser != 0)) {
          if let laser = secondBody.node as? SKSpriteNode {
            laserDidCollideWithAsteroid(laser: laser)
          }
        }
//        if contact.bodyA.node == spinBlock || contact.bodyB.node == spinBlock {
//            self.score += 1
//        }
    }

    // MARK: Utility Functions (thanks ray wenderlich!)
    func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }

    func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
    }

}
