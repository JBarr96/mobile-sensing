//
//  GameScene.swift
//  Commotion
//
//  Created by Eric Larson on 9/6/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//
//
// Johnathan Barr and Remus Tumac
//
// Major credit to SpriteKit Tutorial for Beginners by Brody Eller of Ray Wenderlich
// Source: https://www.raywenderlich.com/71-spritekit-tutorial-for-beginners

import UIKit
import SpriteKit
import CoreMotion

@available(iOS 10.0, *)
class GameScene: SKScene, SKPhysicsContactDelegate {
    let roll_threshold = 0.3                    // variable used to check the motionData roll value against
    var spaceship_position = CGFloat(200.0)     // variable used to move the spaceship sprite
    let min_spaceship_position = CGFloat(50.0)  // minimum position the spaceship is allowed to move left
    let max_spaceship_position = CGFloat(325.0) // maximum position the spaceship is allowed to move right
    var game_over = false                       // boolean flag of whether the game is over (user has exhausted available ammo
    
    // set the default ammo count, either from steps in stored in UserDefaults or set to 10 (if value not there)
    let defaultAmmo: Int = {
        if UserDefaults.standard.value(forKey: "steps") != nil{
            return UserDefaults.standard.integer(forKey: "steps")
        }else{
            return 100
        }
    }()
    
    // set the user's all time high score, either stored in stored in UserDefaults or set to 0 (first time playing)
    let high_score: Int = {
        if UserDefaults.standard.value(forKey: "high_score") != nil{
            return UserDefaults.standard.integer(forKey: "high_score")
        }else{
            return 0
        }
    }()

    var gameVC_delegate: GameViewController?    // GameViewController delegate used for dismissing GameScene
    
    // MARK: Raw Motion Functions
    let motion = CMMotionManager()
    func startMotionUpdates(){
        // some internal inconsistency here: we need to ask the device manager for device
        
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 0.1
            self.motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: self.handleMotion )
        }
    }
    
    // function to handle the motion capute, specifically the roll to control the spaceship
    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
        // set the gravity to zero so things do not fly off the screen
        self.physicsWorld.gravity = .zero
        
        // check the motionData's roll position, if it above the predetermined threshold...
        if((motionData?.attitude.roll)! > roll_threshold){
            // check to see if it has reached the maximum position allowed (as to not go off screen)
            if(spaceship_position < max_spaceship_position){
                // if it has not, increment the position by 10 pixels
                spaceship_position += 10
            }
        // same check but just for the negative direction
        }else if((motionData?.attitude.roll)! < -roll_threshold){
            if(spaceship_position > min_spaceship_position){
                spaceship_position -= 10
            }
        }
        
        // once the new spaceship position has been determined, animate the ship to that position
        let actionMove = SKAction.move(to: CGPoint(x: spaceship_position, y: size.height * 0.1),
                                       duration: TimeInterval(0.15))
        spaceship.run(actionMove)
    }
    
    // MARK: View Hierarchy Functions
    // label to display the current score
    let scoreLabel = SKLabelNode()
    
    // initialize and watch score variable, updating the label if the value changes
    var score:Int = 0 {
        willSet(newValue){
            DispatchQueue.main.async{
                self.scoreLabel.text = "Score: \(newValue)"
            }
        }
    }
    
    // label to display the current ammo count
    let ammoCountLabel = SKLabelNode()
    
    // initialize and watch ammo count variable, updating the label if the value changes
    var ammoCount:Int = 100 {
        willSet(newValue){
            DispatchQueue.main.async{
                self.ammoCountLabel.text = "Ammo: \(newValue)"
            }
        }
    }
    
    // struct to store the physics encodings of different sprites for collisoin detection
    struct PhysicsCategory {
        static let none:        UInt32 = 0
        static let all:         UInt32 = UInt32.max
        static let alien:       UInt32 = 0b1        // 1
        static let asteroid:    UInt32 = 0b10       // 2
        static let laser:       UInt32 = 0b11       // 3
        static let spaceship:   UInt32 = 0b100      // 4
    }
    
    // spaceship sprite (created at class level for ability to update position based on motion data)
    let spaceship = SKSpriteNode(imageNamed: "spaceship")
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        
        // start motion for gravity
        self.startMotionUpdates()
        
        // add spaceship sprite to scene
        self.addSpaceship()
        
        // add score and ammo labels to scene
        self.addScore()
        self.addAmmoCount()
        
        // begin adding moving alien sprites to the scene at random y positions (repeats forever)
        run(SKAction.repeatForever(
          SKAction.sequence([
            SKAction.run(addAlien),
            SKAction.wait(forDuration: 1.0)
            ])
        ))
        
        // begin adding moving asteroid sprites to the scene at random y positions (repeats forever)
        run(SKAction.repeatForever(
          SKAction.sequence([
            SKAction.run(addAsteroid),
            SKAction.wait(forDuration: 1.5)
            ])
        ))
    }
    
    // MARK: Create Sprites Functions
    // function add the score label spirte to the scene
    func addScore(){
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = SKColor.white
        scoreLabel.position = CGPoint(x: frame.midX - 125, y: frame.minY+10)
        addChild(scoreLabel)
    }
    
    // function to add the ammo label sprite to the scene
    func addAmmoCount(){
        self.ammoCount = defaultAmmo
        ammoCountLabel.fontSize = 20
        ammoCountLabel.fontColor = SKColor.white
        ammoCountLabel.position = CGPoint(x: frame.midX + 125, y: frame.minY+10)
        addChild(ammoCountLabel)
    }
    
    // function to initially add the spaceshape spite to the scene
    func addSpaceship(){
        spaceship.position = CGPoint(x: size.width * 0.5, y: size.height * 0.1)
        spaceship.scale(to: CGSize(width: 50, height: 50))
        spaceship.physicsBody = SKPhysicsBody(rectangleOf:spaceship.size)
        spaceship.physicsBody?.isDynamic = false
        spaceship.physicsBody?.categoryBitMask = PhysicsCategory.spaceship
        self.addChild(spaceship)
    }

    
    // function to add an alien sprite to the scene and animate it
    func addAlien() {
        // create and scale sprite
        let alien = SKSpriteNode(imageNamed: "alien")
        alien.scale(to: CGSize(width: 50, height: 40))
        
        // set up phsyics attributes
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.categoryBitMask = PhysicsCategory.alien

        // Determine where to spawn the alien along the Y axis
        let randomY = random(min: alien.size.height + 400, max: size.height - alien.size.height/2)

        // Position the alien slightly off-screen along the right edge, and along a random position along the Y axis as calculated above
        alien.position = CGPoint(x: size.width + alien.size.width/2, y: randomY)

        // Add the alien to the scene to the scene
        addChild(alien)

        // Randomly determine speed of the alien
        let randomDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))

        // create the move action
        let actionMove = SKAction.move(to: CGPoint(x: -100, y: randomY), duration: TimeInterval(randomDuration))
        
        // create action to remove alien from parent
        let actionMoveDone = SKAction.removeFromParent()
        
        // run sequence of movement and remove actions
        alien.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    // function to add an asteroid sprite to the scene and animate it
    func addAsteroid() {
        // Create and scale sprite
        let asteroid = SKSpriteNode(imageNamed: "asteroid")
        asteroid.scale(to: CGSize(width: 40, height: 40))
        
        // set up phsyics attributes
        asteroid.physicsBody = SKPhysicsBody(rectangleOf: asteroid.size)
        asteroid.physicsBody?.categoryBitMask = PhysicsCategory.asteroid

        // Determine where to spawn the asteroid along the Y axis
        let randomY = random(min: size.height/2 - 225, max: size.height/2 - asteroid.size.height/2)

        // Position the asteroid slightly off-screen along the right edge, and along a random position along the Y axis as calculated above
        asteroid.position = CGPoint(x: 0 - asteroid.size.width, y: randomY)

        // Add the asteroid to the scene
        addChild(asteroid)

        // Randomly determine speed of the asteroid
        let randomDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))

        // create the move action
        let actionMove = SKAction.move(to: CGPoint(x: size.width + asteroid.size.width, y: randomY), duration: TimeInterval(randomDuration))
        
        // create action to remove asteroid from parent
        let actionMoveDone = SKAction.removeFromParent()
        
        // run sequence of movement and remove actions
        asteroid.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    // function to shoot laser
    @available(iOS 11.0, *)
    func fireLaser(){
        // first check if play has run out of ammo, if they have, end the game. Otherwise...
        if ammoCount > 0 {
            // create and scale the sprite
            let laser = SKSpriteNode(imageNamed: "laser")
            laser.scale(to: CGSize(width: 10, height: 35))
            
            // position it to shoot from the spaceship
            laser.position = spaceship.position
            
            // set the physics attributes
            laser.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: laser.size.width, height: laser.size.height))
            laser.physicsBody?.isDynamic = true
            laser.physicsBody?.categoryBitMask = PhysicsCategory.laser
            laser.physicsBody?.contactTestBitMask = PhysicsCategory.laser
            laser.physicsBody?.collisionBitMask = PhysicsCategory.laser
            laser.physicsBody?.usesPreciseCollisionDetection = true

            // add the sprite to the scene
            addChild(laser)
            
            // set the destination for the laser to travel to to be the same x position as its launch, but 1000 pixels up in the Y direction
            let destination = CGPoint(x: spaceship.position.x, y: spaceship.position.y + 1000)

            // create action to move the laser to the destination
            let actionMove = SKAction.move(to: destination, duration: 2.0)
            
            // create action to remove the laser from the parent
            let actionMoveDone = SKAction.removeFromParent()
            
            // run the two actions in sequence
            laser.run(SKAction.sequence([actionMove, actionMoveDone]))
            
            // decrement the ammo count
            ammoCount -= 1
        }else{
            // trigger the end of the game
            self.gameDidEnd()
        }
    }
    
    // function that ends the game
    func gameDidEnd() {
        // generate the message for ending the game (dependent on whether or not they beat their high score
        var message = "Game Over\n"
        // if their current score is greater than their high score
        if self.score > self.high_score{
            // add high score to the message and overwrite the high score in UserDefaults
            message += "New High Score!\n"
            UserDefaults.standard.set(self.score, forKey: "high_score")
        }
        message += "Score: \(self.score)\nKeep walking!"
        
        // create and add label to display message
        let label = SKLabelNode()
        if #available(iOS 11.0, *) {
            label.numberOfLines = 0
        }
        label.text = message
        label.fontSize = 40
        label.fontColor = SKColor.white
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        // create and add smaller label to inform user to tap anywhere to exit
        let message2 = "Tap anywhere to exit"
        let label2 = SKLabelNode()
        label2.text = message2
        label2.fontSize = 20
        label2.fontColor = SKColor.white
        label2.position = CGPoint(x: size.width/2, y: size.height/2 - 100)
        addChild(label2)
        
        // set game_over flag to true to alter action of tap
        game_over = true
    }
    
    // function triggered when laser collides with alien
    func laserDidCollideWithAlien(laser: SKSpriteNode, alien: SKSpriteNode) {
        // increment the score by one and remove both sprites from the scene
        self.score += 1
        laser.removeFromParent()
        alien.removeFromParent()
    }
    
    // function triggered when laser collides with asteroid
    func laserDidCollideWithAsteroid(laser: SKSpriteNode) {
        // remove the laser sprite from the scene
        laser.removeFromParent()
    }
    
    // touch method
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if #available(iOS 11.0, *) {
            // if the game is not over, touch fires laser
            if(!game_over){
                self.fireLaser()
            }else{
                // if game has ended, touch uses the delegate to dismiss
                gameVC_delegate?.dismiss(animated: true)
            }
        }
    }

    // function to determine collisions
    func didBegin(_ contact: SKPhysicsContact) {
        // create two physics bodies
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        // arrange them in order of category bit mask to handle each collision appropriately
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }

        // if the collision is between an alien and a laser, call the appropriate function
        if ((firstBody.categoryBitMask & PhysicsCategory.alien != 0) && (secondBody.categoryBitMask & PhysicsCategory.laser != 0)) {
            if let alien = firstBody.node as? SKSpriteNode,
                let laser = secondBody.node as? SKSpriteNode {
                laserDidCollideWithAlien(laser: laser, alien: alien)
            }
        }

        // if the collision is between an asteroid and a laser, call the appropriate function
        if ((firstBody.categoryBitMask & PhysicsCategory.asteroid != 0) && (secondBody.categoryBitMask & PhysicsCategory.laser != 0)) {
            if let laser = secondBody.node as? SKSpriteNode {
                laserDidCollideWithAsteroid(laser: laser)
            }
        }
    }
    
    // MARK: Utility Functions (thanks ray wenderlich!)
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }

    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }

}
