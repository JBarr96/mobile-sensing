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
    var previousStepsToday:Float = 0.0
    
    var totalSteps: Float = 0.0 {
        willSet(newtotalSteps){
            DispatchQueue.main.async{
                self.stepsLabel.text = String(format: "%.0f", locale: Locale.current, newtotalSteps)
                self.circleProgressLayer.strokeEnd = CGFloat(newtotalSteps / self.stepGoal)
            }
        }
    }
    
    //MARK: =====UI Elements=====
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var yesterdayStepsLabel: UILabel!
    @IBOutlet weak var stepGoalLabel: UILabel!
    @IBOutlet weak var isWalking: UILabel!
    
    
    //MARK: =====View Lifecycle=====
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.startActivityMonitoring()
        self.startPedometerMonitoring()
        self.startMotionUpdates()
        self.setHistoricSteps()
        
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
                if unwrappedActivity.unknown {
                    self.isWalking.text = "🤷"
                }
                else if unwrappedActivity.stationary {
                    self.isWalking.text = "🧑"
                }
                else if unwrappedActivity.walking {
                    self.isWalking.text = "🚶"
                }
                else if unwrappedActivity.running {
                    self.isWalking.text = "🏃"
                }
                else if unwrappedActivity.cycling {
                    self.isWalking.text = "🚴"
                }
                else if unwrappedActivity.automotive {
                    self.isWalking.text = "🏎️"
                }
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
            self.totalSteps = self.previousStepsToday + steps.floatValue
        }
    }
    
    func setHistoricSteps(){
        let calendar = Calendar(identifier: .gregorian)
        
        let yesterday = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -1, to: Date())!)!
        let today: Date = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        
        // query for steps previously taken today
        self.pedometer.queryPedometerData(from: today, to: Date())
        {
            (pedData: CMPedometerData?, error: Error?) -> Void in
            self.previousStepsToday = Float(truncating: pedData!.numberOfSteps)
            self.totalSteps = self.previousStepsToday
        }
        
        // set for steps taken yesterday
        self.pedometer.queryPedometerData(from: yesterday, to: today)
        {
            (pedData: CMPedometerData?, error: Error?) -> Void in

            DispatchQueue.main.async{
                self.yesterdayStepsLabel.text = "\(pedData!.numberOfSteps)"
            }
        }
    }
}
