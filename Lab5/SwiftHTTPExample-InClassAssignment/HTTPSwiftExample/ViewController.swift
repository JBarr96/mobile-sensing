//
//  ViewController.swift
//  HTTPSwiftExample
//
//  Created by Eric Larson on 3/30/15.
//  Copyright (c) 2015 Eric Larson. All rights reserved.
//

// This exampe is meant to be run with the python example:
//              tornado_example.py 
//              from the course GitHub repository: tornado_bare, branch sklearn_example


// if you do not know your local sharing server name try:
//    ifconfig |grep inet   
// to see what your public facing IP address is, the ip address can be used here
//let SERVER_URL = "http://erics-macbook-pro.local:8000" // change this for your server name!!!
let SERVER_URL = "http://10.8.113.230:8000" // change this for your server name!!!

import UIKit
import CoreMotion
import AVFoundation

class ViewController: UIViewController, URLSessionDelegate, AVAudioRecorderDelegate {
    
    // MARK: Class Properties
    var session = URLSession()
    let operationQueue = OperationQueue()
    let motionOperationQueue = OperationQueue()
    let calibrationOperationQueue = OperationQueue()
    
    var ringBuffer = RingBuffer()
    let animation = CATransition()
    let motion = CMMotionManager()
    
    var magValue = 0.1
    var isCalibrating = false
    
    var isWaitingForMotionData = false
    
    lazy var audioSession:AVAudioSession = AVAudioSession.sharedInstance()
    var soundRecorder: AVAudioRecorder!
    let fileName = "audiofile.m4a"
    
    var trainPredict = 0
    
    @IBOutlet weak var modelSelectSegmentedControl: UISegmentedControl!
    @IBOutlet weak var trainPredictSegmentedControl: UISegmentedControl!
    @IBOutlet weak var instrumentSegmentedControl: UISegmentedControl!
    @IBOutlet weak var coreMLSwitch: UISwitch!
    @IBOutlet weak var predictionLabel: UILabel!
    
    @IBOutlet weak var dsidLabel: UILabel!
    @IBOutlet weak var upArrow: UILabel!
    @IBOutlet weak var rightArrow: UILabel!
    @IBOutlet weak var downArrow: UILabel!
    @IBOutlet weak var leftArrow: UILabel!
    @IBOutlet weak var largeMotionMagnitude: UIProgressView!
    
    func getTrainingLabel() -> String {
        switch self.instrumentSegmentedControl.selectedSegmentIndex{
        case 0:
            return "guitar"
        case 1:
            return "violin"
        case 2:
            return "piano"
        default:
            return "guitar"
        }
    }
    
    func setDelayedWaitingToTrue(_ time:Double){
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: {
            self.isWaitingForMotionData = true
        })
    }
    
    // MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        predictionLabel.isHidden = true
        
        // Do any additional setup after loading the view, typically from a nib.

        let sessionConfig = URLSessionConfiguration.ephemeral

        sessionConfig.timeoutIntervalForRequest = 10.0
        sessionConfig.timeoutIntervalForResource = 20.0
        sessionConfig.httpMaximumConnectionsPerHost = 1

        self.session = URLSession(configuration: sessionConfig,
            delegate: self,
            delegateQueue:self.operationQueue)
        
        setupAudio()
        setupRecorder()
        print("View did load")
    }
    
    func getCacheDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory,.userDomainMask, true) as [String]
          
        return paths[0]
    }
          
    func getFileURL() -> URL {
//        let filePath = URL(fileURLWithPath: getCacheDirectory()).appendingPathComponent(fileName)
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        let soundURL = documentDirectory.appendingPathComponent(fileName)
          
        return soundURL
    }
    
    func setupAudio(){
        if audioSession.recordPermission() == .granted {
            do {
                try audioSession.setCategory(AVAudioSessionCategoryRecord, with: AVAudioSessionCategoryOptions.mixWithOthers)
                try audioSession.setActive(true)
            } catch {
                print("  ERROR setting audio session: \(error)" )
            }
        }else{
            print("  ERROR Permission to Audio Denied... Check settings")
        }
    }
    
    func setupRecorder() {
        let recordSettings = [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey : 44100.0
        ] as [String : Any]
                
        do { try soundRecorder = AVAudioRecorder(url: getFileURL(), settings: recordSettings) }
        catch { print("Error initializing audio recorder.") }
        soundRecorder.delegate = self
        soundRecorder.prepareToRecord()
        
        print("Recorder set up")
    }
    
    @IBAction func recordSound(_ sender: UIButton) {
        if (sender.titleLabel?.text == "Record"){
            soundRecorder.record()
            print("Recording")
            sender.setTitle("Stop", for: .normal)
            predictionLabel.isHidden = true
        } else {
            soundRecorder.stop()
            print("Stopped recording")
            sender.setTitle("Record", for: .normal)
        }
    }
    
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Successfully recorded")
        // if switch is on, make HTTP request
        if self.coreMLSwitch.isOn{
            // if training, call training function
            if self.trainPredictSegmentedControl.selectedSegmentIndex == 0{
                sendFeatures()
            }
            // otherwise, call prediction function
            else {
                getPrediction()
            }
        }
        // otherwise, use CoreML
        else{
            // if training, call training function
            if self.trainPredictSegmentedControl.selectedSegmentIndex == 0{
              // CoreML training function call
            }
            // otherwise, call the prediction function
            else {
              // CoreML prediction function
            }
        }
    }
    
    func readAudioFile() -> [Float]{
        print(getFileURL())
        let file = try! AVAudioFile(forReading: getFileURL())
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false)
        
        let buf = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(file.length))
        try! file.read(into: buf!)
        
        // this makes a copy
        let floatArray = Array(UnsafeBufferPointer(start: buf?.floatChannelData![0], count:Int(buf!.frameLength)))
        return floatArray
    }

    @IBAction func trainPredictDidChange(_ sender: UISegmentedControl) {
        trainPredict = trainPredictSegmentedControl.selectedSegmentIndex
        if trainPredict == 0{
            instrumentSegmentedControl.isHidden = false
        } else{
            instrumentSegmentedControl.isHidden = true
        }
    }
    
    //MARK: Comm with Server
    func sendFeatures(){
        let baseURL = "\(SERVER_URL)/AddDataPoint"
        let postUrl = URL(string: baseURL)
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature": self.readAudioFile(),
                                       "label":"\(getTrainingLabel())"]
        
        
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                if(error != nil){
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                else{
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    
                    print(jsonDictionary["feature"]!)
                    print(jsonDictionary["label"]!)
                }

        })
        
        postTask.resume() // start the task
    }
    
    func getPrediction(){
        let baseURL = "\(SERVER_URL)/PredictOne"
        let postUrl = URL(string: (baseURL))

        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)

        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature": self.readAudioFile()]


        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)

        request.httpMethod = "POST"
        request.httpBody = requestBody

        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
                                                                  completionHandler:{(data, response, error) in
                                                                    if(error != nil){
                                                                        if let res = response{
                                                                            print("Response:\n",res)
                                                                        }
                                                                    }
                                                                    else{
                                                                        let jsonDictionary = self.convertDataToDictionary(with: data)

                                                                        let labelResponse = jsonDictionary["prediction"]!
                                                                        print(labelResponse)
                                                                        self.predictionLabel.text = (labelResponse as! String)
                                                                        self.predictionLabel.isHidden = false

                                                                    }

        })

        postTask.resume() // start the task
    }
//
    

    @IBAction func makeModel(_ sender: Any) {
        // create a GET request for server to update the ML model with current data
        let baseURL = "\(SERVER_URL)/UpdateModel"
        let query = "?model=\(self.modelSelectSegmentedControl.selectedSegmentIndex)"

        let getUrl = URL(string: baseURL+query)
        let request: URLRequest = URLRequest(url: getUrl!)
        let dataTask : URLSessionDataTask = self.session.dataTask(with: request,
              completionHandler:{(data, response, error) in
                // handle error!
                if (error != nil) {
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                else{
                    let jsonDictionary = self.convertDataToDictionary(with: data)

                    if let resubAcc = jsonDictionary["resubAccuracy"]{
                        print("Resubstitution Accuracy is", resubAcc)
                    }
                }

        })

        dataTask.resume() // start the task

    }
    
    //MARK: JSON Conversion Functions
    func convertDictionaryToData(with jsonUpload:NSDictionary) -> Data?{
        do { // try to make JSON and deal with errors using do/catch block
            let requestBody = try JSONSerialization.data(withJSONObject: jsonUpload, options:JSONSerialization.WritingOptions.prettyPrinted)
            return requestBody
        } catch {
            print("json error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func convertDataToDictionary(with data:Data?)->NSDictionary{
        do { // try to parse JSON and deal with errors using do/catch block
            let jsonDictionary: NSDictionary =
                try JSONSerialization.jsonObject(with: data!,
                                              options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            return jsonDictionary
            
        } catch {
            print("json error: \(error.localizedDescription)")
            return NSDictionary() // just return empty
        }
    }

}





