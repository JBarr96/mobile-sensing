//
//  ViewController.swift
//  Commotion
//
//  Created by Eric Larson on 9/6/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    //MARK: =====class variables=====
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    let motion = CMMotionManager()
    
    let circleProgressLayer = CAShapeLayer()
    let stepGoal:Float = 10000
    
    var totalSteps: Float = 0.0 {
        willSet(newtotalSteps){
            DispatchQueue.main.async{
                self.stepsLabel.text = String(format: "%.0f", locale: Locale.current, 10000.0)
                self.circleProgressLayer.strokeEnd = CGFloat(newtotalSteps / self.stepGoal)
            }
        }
    }
    
    //MARK: =====UI Elements=====
    @IBOutlet weak var isWalking: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var stepGoalLabel: UILabel!
    
    
    //MARK: =====View Lifecycle=====
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.totalSteps = 0.0
        self.startActivityMonitoring()
        self.startPedometerMonitoring()
        self.startMotionUpdates()
        
        self.stepGoalLabel.text = "GOAL: \(String(format: "%.0f", locale: Locale.current, self.stepGoal))"
        
        let circularPath = UIBezierPath(arcCenter: view.center, radius: 80, startAngle: -5 * CGFloat.pi / 4, endAngle: -7 * CGFloat.pi / 4, clockwise: true)
        
        // create track layer
        let trackLayer = CAShapeLayer()
        trackLayer.path = circularPath.cgPath
        trackLayer.strokeColor = UIColor.lightGray.cgColor
        trackLayer.lineWidth = 20
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = kCALineCapRound
        
        view.layer.addSublayer(trackLayer)
        
        circleProgressLayer.path        = circularPath.cgPath
        circleProgressLayer.strokeColor = UIColor.purple.cgColor
        circleProgressLayer.lineWidth   = 20
        circleProgressLayer.fillColor   = UIColor.clear.cgColor
        circleProgressLayer.lineCap     = kCALineCapRound
//        circleProgressLayer.strokeEnd   = 0
//
//        // add initial animation to circle progress bar
//        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
//        basicAnimation.toValue = 0.5
//        basicAnimation.duration = 0.75
//        basicAnimation.fillMode = kCAFillModeForwards
//        basicAnimation.isRemovedOnCompletion = false
//
//        circleProgressLayer.add(basicAnimation, forKey: "basic")
        
        view.layer.addSublayer(circleProgressLayer)
    }
    
    
    // MARK: =====Raw Motion Functions=====
    func startMotionUpdates(){
        // some internal inconsistency here: we need to ask the device manager for device 
        
        // TODO: should we be doing this from the MAIN queue? You will need to fix that!!!....
        if self.motion.isDeviceMotionAvailable{
//            self.motion.startDeviceMotionUpdates(to: OperationQueue.main,
//                                                 withHandler: self.handleMotion)
        }
    }
    
    func handleMotion(_ motionData:CMDeviceMotion?, error:Error?){
        if let gravity = motionData?.gravity {
            let rotation = atan2(gravity.x, gravity.y) - Double.pi
            self.isWalking.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
        }
    }
    
    // MARK: =====Activity Methods=====
    func startActivityMonitoring(){
        // is activity is available
        if CMMotionActivityManager.isActivityAvailable(){
            // update from this queue (should we use the MAIN queue here??.... )
            self.activityManager.startActivityUpdates(to: OperationQueue.main, withHandler: self.handleActivity)
        }
        
    }
    
    func handleActivity(_ activity:CMMotionActivity?)->Void{
        // unwrap the activity and disp
        if let unwrappedActivity = activity {
            DispatchQueue.main.async{
                // self.isWalking.text = "Walking: \(unwrappedActivity.walking)\n Still: \(unwrappedActivity.stationary)"
            }
        }
    }
    
    // MARK: =====Pedometer Methods=====
    func startPedometerMonitoring(){
        //separate out the handler for better readability
        if CMPedometer.isStepCountingAvailable(){
            pedometer.startUpdates(from: Date(),
                                   withHandler: handlePedometer)
        }
    }
    
    //ped handler
    func handlePedometer(_ pedData:CMPedometerData?, error:Error?)->(){
        if let steps = pedData?.numberOfSteps {
            self.totalSteps = steps.floatValue
        }
    }


}

