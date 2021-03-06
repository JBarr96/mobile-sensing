//
//  GameViewController.swift
//  Commotion
//
//  Created by Eric Larson on 9/6/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import SpriteKit

@available(iOS 10.0, *)
class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // setup game scene
        let scene = GameScene(size: view.bounds.size)
        scene.gameVC_delegate = self        // set game scene's delegate to self
        let skView = view as! SKView        // the view in storyboard must be an SKView
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }
    
}
