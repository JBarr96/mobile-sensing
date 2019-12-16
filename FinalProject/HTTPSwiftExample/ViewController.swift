//
//  ViewController.swift
//  HTTPSwiftExample
//
//  Created by Eric Larson on 3/30/15.
//  Copyright (c) 2015 Eric Larson. All rights reserved.
//
// Johnathan Barr and Remus Tumac
//
// Metronome logic adapted from here: https://github.com/ekscrypto/Swift-Tutorial-Metronome
// Image resizing function found here: https://iosdevcenters.blogspot.com/2015/12/how-to-resize-image-in-swift-in-ios.html
//


import UIKit
import CoreML
import AVFoundation
import Speech


@available(iOS 12.0, *)
class ViewController: UIViewController, URLSessionDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    // variables necessary for audio recording including the file name
    lazy var audioSession:AVAudioSession = AVAudioSession.sharedInstance()
    var soundRecorder: AVAudioRecorder!
    private var player:AVAudioPlayer! = nil
    let fileName = "audiofile.m4a"
    let loopPlaybackFileName = "audiofile-loop.m4a"
    
    var recordForTempoAnalysisFlag = false
    var recordLoopPlayback = false
    
    // metronome variables
    var bpm: Int = 60 { didSet {
        bpm = min(300,max(30,bpm))
        self.bpmLabel.text = "\(self.bpm)"
        }}
    var onTick: ((_ nextTick: DispatchTime) -> Void)?
    var nextTick: DispatchTime = DispatchTime.distantFuture
    
    // flag that turns the turns the metronome on/off based on value
    var metronome_enabled: Bool = false { didSet {
        if metronome_enabled {
            print("Starting metronome, BPM: \(bpm)")
            player.prepareToPlay()
            nextTick = DispatchTime.now()
            tick()
        } else {
            print("Stopping metronome")
            player.stop()
        }
    }}

    // sampling rate for recorder
    let recorderSamplingRate = 44100.0
    
    // number of bars to play back the recorded loop
    var numBarsLoopPlayback = 0
    
    // all UI elements (labels and buttons)
    @IBOutlet weak var bpmLabel: UILabel!
    @IBOutlet weak var bpmSubLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var modeImage: UIImageView!
    
    // dictionary of images that will be used for icons or buttons
    let images:[String:UIImage] = ["speak": UIImage(named: "Tap To Speak")!,
                                    "go": UIImage(named: "Go Button")!,
                                    "stop": UIImage(named: "Stop Button")!,
                                    "play": UIImage(named: "Play Button")!,
                                    "recording_loop": UIImage(named: "Recording Button")!,
                                    "loop_black": UIImage(named: "loop_black")!,
                                    "loop_white": UIImage(named: "loop_white")!,
                                    "recording_tempo": UIImage(named: "Stop Recording")!,
                                    "metronome_black": UIImage(named: "metronome_black")!,
                                    "metronome_white": UIImage(named: "metronome_white")!]
    
    // enum to distinguish whether app is in metronome or looping mode
    enum Mode {
        case metronome
        case loop
    }
    
    // variable with teh app's current mode, changing the mode icon accordingly
    var mode = Mode.metronome { didSet {
        switch mode {
        case Mode.metronome:
            self.modeImage.image = images["metronome_white"]
        case Mode.loop:
            self.modeImage.image = images["loop_white"]
        default:
            return
        }
    }}

    // enum to represent the "state" of the app
    enum State {
        case speak
        case listening
        case misunderstand
        case recording_tempo
        case playing_metronome
        case stopped_metronome
        case recording_loop
        case playing_loop
        case stopped_loop
    }
    
    // current state of the app, changing which will change the UI accordingly
    var state = State.speak { didSet {
        switch state {
        // speak state is the default state of the app with no play or mode icons. Just bpm and action button
        case State.speak:
            self.actionButton.setBackgroundImage(images["speak"], for: .normal)
            self.actionButton.isEnabled = true
            self.statusLabel.isHidden = true
            self.playButton.isHidden = true
            self.modeImage.isHidden = true
            
        // listening state is what is shown while a verbal command is being issued, changing
        // the action button to the green "Go" button and displaying "Listening" in the status label
        case State.listening:
            self.actionButton.setBackgroundImage(images["go"], for: .normal)
            self.statusLabel.text = "Listening..."
            self.statusLabel.isHidden = false
            self.playButton.isHidden = true
            self.modeImage.isHidden = true
        
        // misunderstood state is when a command is not understood as one of the accepted commands of the app
        // informs the user the command was not understood and prompts them to try again
        case State.misunderstand:
            self.statusLabel.text = "Command not understood Please Try Again"
            self.actionButton.setBackgroundImage(images["speak"], for: .normal)
            self.actionButton.isEnabled = true
            self.statusLabel.isHidden = false
            self.playButton.isHidden = true
            self.modeImage.isHidden = true
            
        // recording tempo state for when a tempo is being set dynamically with the audio analysis
        // shows round red stop button to end recording
        case State.recording_tempo:
            self.actionButton.setBackgroundImage(images["recording_tempo"], for: .normal)
            self.actionButton.isEnabled = true
            self.statusLabel.isHidden = true
            self.playButton.isHidden = true
            self.modeImage.isHidden = true
            
        // playing metronome state for when the metronome is currently running
        // shows red square stop button to pause recording and metronome mode icon
        case State.playing_metronome:
            self.actionButton.setBackgroundImage(images["stop"], for: .normal)
            self.actionButton.isEnabled = true
            self.mode = Mode.metronome
            self.statusLabel.isHidden = true
            self.playButton.isHidden = true
            self.modeImage.isHidden = false
            
        // stopped metronome state for when the metronome has been stopped
        // shows regular voice command button, mode icon, and play button to resume metronome
        case State.stopped_metronome:
            self.actionButton.setBackgroundImage(images["speak"], for: .normal)
            self.actionButton.isEnabled = true
            self.statusLabel.isHidden = true
            self.playButton.isHidden = false
            self.modeImage.isHidden = false
            
        // recording loop state for when a loop is currently being recorded
        // makes action button big red recording circle that you cannot press (don't want to interrupt recording)
        case State.recording_loop:
            self.actionButton.setBackgroundImage(images["recording_loop"], for: .normal)
            self.actionButton.isEnabled = false
            self.mode = Mode.loop
            self.statusLabel.isHidden = true
            self.playButton.isHidden = true
            self.modeImage.isHidden = true
            
        // playing loop state for when a recorded loop is being played back
        // same as metronome playing with red stop square and mode icon
        case State.playing_loop:
            self.actionButton.setBackgroundImage(images["stop"], for: .normal)
            self.actionButton.isEnabled = true
            self.statusLabel.isHidden = true
            self.playButton.isHidden = true
            self.modeImage.isHidden = false
            
        // stopped loop state for when recorded loop playback has been stopped
        // same as stopped metronome with normal action button, mode icon, and play button to resume playback
        case State.stopped_loop:
            self.actionButton.setBackgroundImage(images["speak"], for: .normal)
            self.actionButton.isEnabled = true
            self.statusLabel.isHidden = true
            self.playButton.isHidden = false
            self.modeImage.isHidden = false
            
        // default because swift requires default
        default:
            return
        }
    }}
    
    // variable that stores the current state of screen flashing, changing which will "flash" the screen
    var flash = false { didSet {
        // if true, white background with dark icons
        if flash{
            view.backgroundColor = .white
            self.bpmLabel.textColor = .darkGray
            self.bpmSubLabel.textColor = .darkGray
            switch self.mode {
            case Mode.metronome:
                self.modeImage.image = images["metronome_black"]
            case Mode.loop:
                self.modeImage.image = images["loop_black"]
            default:
                return
            }
        }
        // if false, normal dark background with white icons
        else{
            view.backgroundColor = .darkGray
            self.bpmLabel.textColor = .white
            self.bpmSubLabel.textColor = .white
            switch self.mode {
            case Mode.metronome:
                self.modeImage.image = images["metronome_white"]
            case Mode.loop:
                self.modeImage.image = images["loop_white"]
            default:
                return
            }
        }
    }}

    override func viewDidLoad() {
        super.viewDidLoad()
        self.playButton.setBackgroundImage(images["play"], for: .normal)
        self.bpm = 60
        self.state = State.speak
        
        // set up audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioSession.setActive(true)
        } catch let error as NSError {
            print(error.description)
        }
        
        // set up audio player
        let sound = Bundle.main.path(forResource: "Click", ofType: "wav")
        self.setupAudioPlayer(audioFileURL: URL(fileURLWithPath: sound!))
        
        setupRecorder(recordingFileName: self.fileName)

        // set up flash functionality for metronome
        self.onTick = { (nextTick) in
            self.flash = !self.flash
        }
    }
    
    // function to listen to audio command and convert to string using SFSpeechRecognizer
    func transcribeAudioAndTakeAction() {
        let url = getFileURL(fileName: fileName)
        // create a new recognizer and point it at our audio
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        var transcription = ""

        // start recognition!
        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
            // abort if we didn't get any transcription back
            guard let result = result else {
                DispatchQueue.main.async { [weak self] in
                    self?.state = State.misunderstand
                }
                
                return
            }

            // if we got the final transcription back, print it
            if result.isFinal {
                // pull out the best transcription...
                transcription = result.bestTranscription.formattedString
                print("Transcription: \(transcription)")
                // perform action with command
                self.interpretCommand(command: transcription.lowercased())
            }
            else{
                transcription = ""
            }
        }
    }
    
    // function to trigger recording for tempo analysis
    func recordForTempoAnalysis(){
        print("Record for Tempo Analysis")
        
        self.state = State.recording_tempo
        self.recordForTempoAnalysisFlag = true
        self.statusLabel.text = "Listening..."
        self.statusLabel.isHidden = false
        soundRecorder.record()
    }
    
    // function to trigger loop recording
    func recordForLoop(numBars: Int){
        self.state = State.recording_loop
        self.recordLoopPlayback = true
        self.numBarsLoopPlayback = numBars
        
        // calculate time duration of recording
        let interval: TimeInterval = Double(numBars) / (Double(self.bpm) / 60.0)
        
        // set up metronome to count the user before recording starts
        let sound = Bundle.main.path(forResource: "Click", ofType: "wav")
        self.setupAudioPlayer(audioFileURL: URL(fileURLWithPath: sound!))
        self.player.volume = 80.0
        self.player.prepareToPlay()
        
        let metronomeInterval: TimeInterval = 60.0 / TimeInterval(bpm)
        
        // count in the user for 4 bars with metronome tick
        self.player.play()
        self.flash = true
        
        var times = 3
        let timer = Timer.scheduledTimer(withTimeInterval: metronomeInterval, repeats: true, block: { timer in
            if times > 0{
                self.player.play()
                self.flash = !self.flash
            }
            times -= 1
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + metronomeInterval * 3.9) { [weak self] in
            timer.invalidate()
            
            // start recording
            self?.setupRecorder(recordingFileName: self!.loopPlaybackFileName)
            self?.statusLabel.text = "Recording..."
            self?.statusLabel.isHidden = false
            self?.soundRecorder.record()
            
            // stop recording
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
                self?.soundRecorder.stop()
            }
        }
    }
    
    // function for when main action button is pressed
    // functionality depends on the current state of the app
    @IBAction func actionButtonPressed(_ sender: UIButton) {
        // pressing the button while in...
        switch state {
        // speak state will trigger the recording of a command
        case State.speak:
            soundRecorder.record()
            print("Recording command")
            self.state = State.listening
        // listening state will end the recording of the command (and trigger followup action)
        case State.listening:
            self.actionButton.isEnabled = false
            soundRecorder.stop()
            print("Stopped recording command")
        // misunderstood state will trigger the recording of a command
        case State.misunderstand:
            soundRecorder.record()
            print("Recording command")
            self.state = State.listening
        // recording tempo state will end the recording of the audio to be processed for tempo analysis
        case State.recording_tempo:
            self.statusLabel.text = "Thinking..."
            soundRecorder.stop()
            print("Stopped recording tempo")
        // playing metronome state will stop the metronome
        case State.playing_metronome:
            stopMetronome()
        // stopped metronome state will trigger the recording of a command
        case State.stopped_metronome:
            soundRecorder.record()
            print("Recording command")
            self.state = State.listening
        // playing loop state will stop the playback of the loop
        case State.playing_loop:
            stopLoop()
        // stopped loop state will trigger the recording of a command
        case State.stopped_loop:
            soundRecorder.record()
            print("Recording command")
            self.state = State.listening
        // default because swift requires a default
        default:
            return
        }
    }
    
    // function to initiate the playing of the metronome
    func startMetronome(){
        let sound = Bundle.main.path(forResource: "Click", ofType: "wav")
        self.setupAudioPlayer(audioFileURL: URL(fileURLWithPath: sound!))
        self.player.volume = 80.0
        metronome_enabled = true
        self.state = State.playing_metronome
        flash = true
        print("Started metronome")
    }
    
    // function to stop the playing of the metronome
    func stopMetronome(){
        metronome_enabled = false
        self.state = State.stopped_metronome
        view.backgroundColor = .darkGray
        flash = false
        print("Stopped metronome")
    }
    
    // function to initiate the playback of the recorded loop
    func startLoop() {
        // set up audio player for loop playback
        self.setupAudioPlayer(audioFileURL: getFileURL(fileName: self.loopPlaybackFileName))
        self.state = State.playing_loop
        
        self.player.numberOfLoops = -1
        self.player.volume = 80.0

        self.player.prepareToPlay()
        self.player.play()
    }
    
    // function to stop the playback of the recorded loop
    func stopLoop(){
        self.state = State.stopped_loop
        self.player.stop()
    }
        
    // function when green play button is pressed to resume playback of either metronome or loop
    @IBAction func resume(_ sender: Any) {
        if self.mode == Mode.metronome {
            startMetronome()
        }
        else if self.mode == Mode.loop {
            startLoop()
        }
        else{
            return
        }
    }
    
    // function to return the URL for the audio file
    func getFileURL(fileName: String) -> URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        let soundURL = documentDirectory.appendingPathComponent(fileName)
          
        return soundURL
    }
    
    // function to set up the audio player
    func setupAudioPlayer(audioFileURL: URL) {
        do{
            player = try AVAudioPlayer(contentsOf: audioFileURL)
            print("loaded file with volume \(player.volume) and \(player.duration)")
        }catch{
            print(error)
        }
        print("playing \(player.isPlaying)")
    }
    
    // function to set up the audio recorder
    func setupRecorder(recordingFileName: String) {
        let recordSettings = [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey : 44100.0
        ] as [String : Any]
                
        do { try soundRecorder = AVAudioRecorder(url: getFileURL(fileName: recordingFileName), settings: recordSettings) }
        catch { print("Error initializing audio recorder.") }
        soundRecorder.delegate = self
        soundRecorder.prepareToRecord()
        
        print("Recorder set up")
    }

    // function for the metronome 'tick'
    private func tick() {
        guard
            metronome_enabled,
            nextTick <= DispatchTime.now()
            else { return }

        let interval: TimeInterval = 60.0 / TimeInterval(bpm)
        nextTick = nextTick + interval
        DispatchQueue.main.asyncAfter(deadline: nextTick) { [weak self] in
            self?.tick()
        }

        player.play()
        onTick?(nextTick)
    }
    
    // function to interpret a command
    // series of conditional tests to determine which function to trigger
    func interpretCommand(command: String) {
        print(command)
        
        if command.contains("metronome"){
            self.state = State.playing_metronome
            startMetronome()
        }
        // accounts for common misunderstandings in pronunciation
        else if command.contains("set tempo") || command.contains("set timbre") || command.contains("set temperature") || command.contains("september"){
            if command.contains("to") || command.contains("temperature"){
                let strArr = command.split(separator: " ")
                // parse out integer bpm from string
                for item in strArr {
                    let part = item.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

                    if let intVal = Int(part) {
                        self.bpm = intVal
                    }
                }
                self.state = State.speak
            }
            else if command == "set tempo" || command == "set timbre" {
                self.recordForTempoAnalysis()
            }
            else {
                self.state = State.misunderstand
            }
        }
        else if command.contains("record") || command.contains("records"){
            let strArr = command.split(separator: " ")
            var numBars = 0
            
            // parse out number of bars to record from string
            for item in strArr {
                let part = item.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                
                if let intVal = Int(part) {
                    numBars = intVal
                    break
                }
                else {
                    // check if the number of bars was spelled out
                    switch item {
                        case "one":
                            numBars = 1
                        case "two":
                            numBars = 2
                        case "three":
                            numBars = 3
                        case "four":
                            numBars = 4
                        case "five":
                            numBars = 5
                        case "six":
                            numBars = 6
                        case "seven":
                            numBars = 7
                        case "eight":
                            numBars = 8
                        case "nine":
                            numBars = 9
                        default:
                            continue
                    }
                }
            }
            
            if numBars > 0 {
                recordForLoop(numBars: numBars)
            }
            else {
                self.state = State.misunderstand
            }
        }
        else {
            self.state = State.misunderstand
        }
    }
    
    // AVAudioRecorderDelegate delegate function performed upon completion of audio recording
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Finished Recording")
        self.statusLabel.text = "Thinking..."
        
        // if the recordForTempoAnalysisFlag is set, perform tempo analysis on audio
        if self.recordForTempoAnalysisFlag {
            self.recordForTempoAnalysisFlag = false
            self.bpm = findRecordingTempo()
            self.state = State.speak
        }
        // if recordLoopPlayback is set, stop the recording and begin looped playback
        else if self.recordLoopPlayback {
            self.flash = false
            self.recordLoopPlayback = false
            startLoop()
            
            // reset audio recorder
            self.recordLoopPlayback = false
            self.setupRecorder(recordingFileName: self.fileName)
        }
        // otherwise, interpret the recorded command
        else {
            transcribeAudioAndTakeAction()
        }
    }
    
    // function that reads in the audiofile and transforms it into a float array
    func readAudioFile() -> [Float]{
        let file = try! AVAudioFile(forReading: getFileURL(fileName: fileName))
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false)
        
        let buf = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(file.length))
        try! file.read(into: buf!)
        
        let floatArray = Array(UnsafeBufferPointer(start: buf?.floatChannelData![0], count:Int(buf!.frameLength)))
        return floatArray
    }
    
    // function for determining tempo from recorded audio
    func findRecordingTempo() -> Int {
        print("Analyzing Tempo")
        self.statusLabel.text = "Thinking..."
        let audioData : Array = readAudioFile()
        
        var peaks : [Int] = []
        let windowSize = 3000
        
        // iterate over the audio buffer with a window of size 3000
        for i in 4000..<audioData.count - windowSize {
            var windowMax = audioData[i]
            var windowMaxPosition = i
            
            // find local maxima inside windoe
            for j in i..<i + windowSize {
                if(audioData[j] > windowMax) {
                    windowMax = audioData[j]
                    windowMaxPosition = j
                }
            }
            
            // check if local maxima is a peak within the window
            if(windowMaxPosition == i + windowSize / 2 && windowMax > 0.15) {
                peaks.append(windowMaxPosition)
            }
        }
        
        var beatsPerMinute = 0.0
        
        if peaks.count > 1 {
            // calculate BPM
            let timeInterval = Double(peaks.last! - peaks.first!) / 44100.0
            beatsPerMinute = Double(peaks.count - 1) / timeInterval * 60            
        }
        
        print("BPM: \(Int(beatsPerMinute.rounded()))")
        
        return Int(beatsPerMinute.rounded())
    }
    
    // function to resize UIImages
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
}

