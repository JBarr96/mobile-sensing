//
//  GameOver.swift
//  Commotion
//
//  Created by Johnathan Barr on 10/17/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

import SpriteKit

@available(iOS 10.0, *)
class GameOverScene: SKScene {
    @available(iOS 11.0, *)
    init(size: CGSize, score:Int) {
    super.init(size: size)
    
    let high_score = UserDefaults.standard.integer(forKey: "high_score")
    
    // 2
    var message = "Game Over\n"
    if score > high_score{
        message += "New High Score!\n"
        UserDefaults.standard.set(score, forKey: "high_score")
    }
    message += "Score: \(score)\nKeep walking!"
    
    // 3
    let label = SKLabelNode()
    label.numberOfLines = 0
    label.text = message
    label.fontSize = 40
    label.fontColor = SKColor.white
    label.position = CGPoint(x: size.width/2, y: size.height/2)
    addChild(label)
    
    // return to step counter
        
    // 4
//    run(SKAction.sequence([
//      SKAction.wait(forDuration: 3.0),
//      SKAction.run() { [weak self] in
//        // 5
//        guard let `self` = self else { return }
//        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
//        let scene = GameScene(size: size)
//        self.view?.presentScene(scene, transition:reveal)
//      }
//      ]))
   }
  
  // 6
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
