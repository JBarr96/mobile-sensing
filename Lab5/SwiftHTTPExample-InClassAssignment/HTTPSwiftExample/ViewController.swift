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

// Johnathan Barr and Remus Tumac

let SERVER_URL = "http://10.8.119.21:8000" // change this for your server name!!!

import UIKit
import CoreML
import AVFoundation


@available(iOS 12.0, *)
class ViewController: UIViewController, URLSessionDelegate, AVAudioRecorderDelegate {
    
    // MARK: Class Properties
    var session = URLSession()
    let operationQueue = OperationQueue()
    let calibrationOperationQueue = OperationQueue()
    
    // variables necessary for audio recording including the file name
    lazy var audioSession:AVAudioSession = AVAudioSession.sharedInstance()
    var soundRecorder: AVAudioRecorder!
    let fileName = "audiofile.m4a"
    
    // UI elements
    @IBOutlet weak var modelSelectSegmentedControl: UISegmentedControl!
    @IBOutlet weak var trainPredictSegmentedControl: UISegmentedControl!
    @IBOutlet weak var instrumentSegmentedControl: UISegmentedControl!
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var updatingLabel: UILabel!

    // fuction that returns the label for training based on the segmented control selection
    func getTrainingLabel() -> String {
        switch self.instrumentSegmentedControl.selectedSegmentIndex{
        case 0:
            return "Guitar"
        case 1:
            return "Violin"
        case 2:
            return "Piano"
        default:
            return "Guitar"
        }
    }
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hide some elements off the bat
        predictionLabel.isHidden = true
        updatingLabel.isHidden = true
        
        // configure session
        let sessionConfig = URLSessionConfiguration.ephemeral

        sessionConfig.timeoutIntervalForRequest = 1000.0
        sessionConfig.timeoutIntervalForResource = 2000.0
        sessionConfig.httpMaximumConnectionsPerHost = 1

        self.session = URLSession(configuration: sessionConfig,
            delegate: self,
            delegateQueue:self.operationQueue)
        
        //set up the audio session and recorder
        setupAudio()
        setupRecorder()
        
        print("View did load")
    }
          
    // function to return the URL for the audio file
    func getFileURL() -> URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        let soundURL = documentDirectory.appendingPathComponent(fileName)
          
        return soundURL
    }
    
    // function to set up the audio session
    func setupAudio(){
        if audioSession.recordPermission() == .granted {
            do {
                try audioSession.setCategory(AVAudioSessionCategoryRecord, with: AVAudioSessionCategoryOptions.mixWithOthers)
                try audioSession.setActive(true)
                print("AudioSession set up")
            } catch {
                print("  ERROR setting audio session: \(error)" )
            }
        }else{
            print("  ERROR Permission to Audio Denied... Check settings")
        }
    }
    
    // function to set up the audio recorder
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
    
    // function to record/stop recording of audio
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
    
    // AVAudioRecorderDelegate delegate function performed upon completion of audio recording
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Successfully recorded")
        // if training, call training function
        if self.trainPredictSegmentedControl.selectedSegmentIndex == 0{
            sendFeatures()
        }
        // otherwise, call prediction function
        else {
            getHttpPrediction()
        }
    }
    
    // function that reads in the audiofile and transforms it into a float array for HTTP payload
    func readAudioFile() -> [Float]{
        print(getFileURL())
        let file = try! AVAudioFile(forReading: getFileURL())
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false)
        
        let buf = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(file.length))
        try! file.read(into: buf!)
        
        let floatArray = Array(UnsafeBufferPointer(start: buf?.floatChannelData![0], count:Int(buf!.frameLength)))
        return floatArray
    }

    // function to hide instrument selection segmented control if in prediction mode
    @IBAction func trainPredictDidChange(_ sender: UISegmentedControl) {
        if trainPredictSegmentedControl.selectedSegmentIndex == 0 {
            instrumentSegmentedControl.isHidden = false
        } else{
            instrumentSegmentedControl.isHidden = true
        }
    }
    
    //MARK: Comm with Server
    // function to send training data to the server
    func sendFeatures(){
        // generate the url string with the server IP and desired endpoint
        let baseURL = "\(SERVER_URL)/AddDataPoint"
        
        // create URL object based on string
        let postUrl = URL(string: baseURL)
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)
        
        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature": self.readAudioFile(),
                                       "label":"\(getTrainingLabel())"]
        
        // convert the json dictionary to Data
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)
        
        // set request to post type and provide request body payload
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        // create task with request
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                // handle error
                if(error != nil){
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                // otherwise...
                else{
                    // convert response data to dictionary and print to console
                    let jsonDictionary = self.convertDataToDictionary(with: data)
                    
                    print(jsonDictionary["feature"]!)
                    print(jsonDictionary["label"]!)
                }
        })
        
        // run the task
        postTask.resume()
    }
    
    // function to retreive prediction from the server
    func getHttpPrediction(){
        // generate the url string with the server IP and desired endpoint
        let baseURL = "\(SERVER_URL)/PredictOne"
        
        // create URL object based on string
        let postUrl = URL(string: (baseURL))

        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)

        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["feature": self.readAudioFile(),
                                       "ml_model_type": self.modelSelectSegmentedControl.selectedSegmentIndex]

        // convert the json dictionary to Data
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)

        // set request to post type and provide request body payload
        request.httpMethod = "POST"
        request.httpBody = requestBody

        // create task with request
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                // handle error
                if(error != nil){
                    if let res = response{
                        print("Response:\n",res)
                    }
                }
                // otherwise...
                else{
                    // convert the response data to dictionary and update the prediction label with the returned predicted label
                    let jsonDictionary = self.convertDataToDictionary(with: data)

                    let labelResponse = jsonDictionary["prediction"]!
                    print(labelResponse)
                    DispatchQueue.main.async {
                        self.predictionLabel.text = (labelResponse as! String)
                        self.predictionLabel.isHidden = false
                    }
                }
            })

        // run the task
        postTask.resume()
    }

    // function to create model from the
    @IBAction func makeModel(_ sender: Any) {
        // inform the user the model is updating
        updatingLabel.text = ("Updating Model...")
        updatingLabel.isHidden = false
        
        // generate the url string with the server IP and desired endpoint
        let baseURL = "\(SERVER_URL)/UpdateModel"
        
        // create URL object based on string
        let postUrl = URL(string: (baseURL))
        
        // create a custom HTTP POST request
        var request = URLRequest(url: postUrl!)

        // data to send in body of post request (send arguments as json)
        let jsonUpload:NSDictionary = ["ml_model_type": self.modelSelectSegmentedControl.selectedSegmentIndex]

        // convert the json dictionary to Data
        let requestBody:Data? = self.convertDictionaryToData(with:jsonUpload)

        // set request to post type and provide request body payload
        request.httpMethod = "POST"
        request.httpBody = requestBody
        
        // create task with request
        let postTask : URLSessionDataTask = self.session.dataTask(with: request,
            completionHandler:{(data, response, error) in
                // handle error
                if(error != nil){
                    if let res = response{
                        print("Response:\n",res)
                    }
                    print(error)
                }
                // otherwise...
                else{
                    // convert the response data to dictionary and update the UI with the returned training set accuracy
                    let jsonDictionary = self.convertDataToDictionary(with: data)

                    let accuracy = jsonDictionary["resubAccuracy"]!
                    print("Training Set Accuracy: \(accuracy)")
                    DispatchQueue.main.async {
                        self.updatingLabel.text = ("Model \(self.modelSelectSegmentedControl.selectedSegmentIndex + 1) updated! Training Set Accuracy: \(accuracy)")
                    }
                    // after 5 seconds, hide the label
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        self.updatingLabel.isHidden = true
                    }
                }
            })
        
        // run the task
        postTask.resume()

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





