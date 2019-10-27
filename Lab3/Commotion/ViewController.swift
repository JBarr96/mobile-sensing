//
//  ViewController.swift
//  Commotion
//
//  Created by Eric Larson on 9/6/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: =====class variables=====
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    let motion = CMMotionManager()
    let defaults = UserDefaults.standard
    
    let circleProgressLayer = CAShapeLayer()
    var stepGoal:Float = 5000
    var previousStepsToday:Float = 0.0
    
    var totalSteps: Float = 0.0 {
        willSet(newtotalSteps){
            DispatchQueue.main.async{
                // update ui based on new step count
                self.stepsLabel.text = String(format: "%.0f", locale: Locale.current, newtotalSteps)
                self.circleProgressLayer.strokeEnd = CGFloat(newtotalSteps / self.stepGoal)
                
                // check if current number of steps has reach goal
                if newtotalSteps >= self.stepGoal {
                    self.defaults.set(newtotalSteps, forKey: "steps")
                    self.gameLaunchButton.isHidden = false
                }
            }
        }
    }
    
    //MARK: =====UI Elements=====
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var yesterdayStepsLabel: UILabel!
    @IBOutlet weak var stepGoalLabel: UILabel!
    @IBOutlet weak var isWalking: UILabel!
    @IBOutlet weak var newGoalTextField: UITextField!
    @IBOutlet weak var gameLaunchButton: UIButton!
    
    //MARK: =====View Lifecycle=====
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hide the button that launches the game
        self.gameLaunchButton.isHidden = true

        self.startActivityMonitoring()
        self.startPedometerMonitoring()
        self.setHistoricSteps()
        
        let circularPath = UIBezierPath(arcCenter: view.center, radius: 80, startAngle: -5 * CGFloat.pi / 4, endAngle: -7 * CGFloat.pi / 4, clockwise: true)
        
        // create track layer for progress bar
        let trackLayer = CAShapeLayer()
        trackLayer.path = circularPath.cgPath
        trackLayer.strokeColor = UIColor.lightGray.cgColor
        trackLayer.lineWidth = 20
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = kCALineCapRound
        
        view.layer.addSublayer(trackLayer)
        
        // create progress layer for progress bar
        circleProgressLayer.path        = circularPath.cgPath
        circleProgressLayer.strokeColor = UIColor.purple.cgColor
        circleProgressLayer.lineWidth   = 20
        circleProgressLayer.fillColor   = UIColor.clear.cgColor
        circleProgressLayer.lineCap     = kCALineCapRound
        
        view.layer.addSublayer(circleProgressLayer)
        
        // retrieve persisted goal
        if let oldStepGoal = defaults.value(forKey: "stepGoal") {
            self.setStepGoal(newStepGoal: oldStepGoal as! Float)
        }
        else {
            self.setStepGoal(newStepGoal: self.stepGoal)
        }
        
        // notification for keyboard show and hide
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    // MARK: =====Activity Methods=====
    func startActivityMonitoring(){
        // is activity is available
        if CMMotionActivityManager.isActivityAvailable(){
            self.activityManager.startActivityUpdates(to: OperationQueue.main, withHandler: self.handleActivity)
        }
        
    }
    
    // handle change in pedometer activity
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
    
    // update the step goal
    func setStepGoal(newStepGoal: Float) {
        self.stepGoal = newStepGoal
        self.defaults.set(newStepGoal, forKey: "stepGoal")
        
        // update ui based on new goal
        self.stepGoalLabel.text = "GOAL: \(String(format: "%.0f", locale: Locale.current, self.stepGoal))"
        self.circleProgressLayer.strokeEnd = CGFloat(self.totalSteps / self.stepGoal)
        
        // check if new goal was reached
        if self.totalSteps >= self.stepGoal {
            self.defaults.set(self.totalSteps, forKey: "steps")
            self.gameLaunchButton.isHidden = false
        }
        else {
            self.gameLaunchButton.isHidden = true
        }
    }
    
    // retrieve historical pedometer data
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
    
    // clear textfield before editing
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
    
    // handle the press of the return button after filling the text field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text != nil {
            let newStepGoal = Float(textField.text!)
            
            if newStepGoal != nil {
                self.setStepGoal(newStepGoal: newStepGoal!)
            }
            else {
                textField.text = ""
            }
        }
        
        textField.resignFirstResponder()
        return true
    }
    
    // shift ui up if keyboard is onn
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            view.frame.origin.y = -1 * keyboardHeight
        }
    }
    
    // shift ui down when keyboard disapears
    @objc func keyboardWillHide(_ notification: Notification) {
            view.frame.origin.y = 0
    }
    
    // hide keyboard on tap
    @IBAction func didTapMainView(_ sender: Any) {
        self.newGoalTextField.resignFirstResponder()
    }
}
