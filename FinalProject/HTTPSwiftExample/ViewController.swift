//
//  ViewController.swift
//  HTTPSwiftExample
//
//  Created by Eric Larson on 3/30/15.
//  Copyright (c) 2015 Eric Larson. All rights reserved.

// Johnathan Barr and Remus Tumac

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
    
    var recordForTempoAnalysisFlag = false
    var recordLoopPlayback = false
    
    // metronome variables
    var bpm: Int = 60 { didSet {
        bpm = min(300,max(30,bpm))
        self.bpmLabel.text = "\(self.bpm)"
        }}
    var onTick: ((_ nextTick: DispatchTime) -> Void)?
    var nextTick: DispatchTime = DispatchTime.distantFuture
    
    var metronome_enabled: Bool = false { didSet {
        if metronome_enabled {
            print("Starting metronome, BPM: \(bpm)")
            player.prepareToPlay()
            nextTick = DispatchTime.now()
            tick()
        } else {
            player.stop()
            print("Stopping metronome")
        }
    }}
    
    @IBOutlet weak var bpmLabel: UILabel!
    @IBOutlet weak var bpmSubLabel: UILabel!
    
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var modeImage: UIImageView!
    
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
    
    enum Mode {
        case metronome
        case loop
    }
    
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

    enum State {
        case speak
        case listening
        case recording_tempo
        case playing_metronome
        case stopped_metronome
        case recording_loop
        case playing_loop
        case stopped_loop
    }
    
    var state = State.speak { didSet {
        switch state {
        case State.speak:
            self.actionButton.setBackgroundImage(images["speak"], for: .normal)
            self.playButton.isHidden = true
            self.modeImage.isHidden = true
            
        case State.listening:
            self.actionButton.setBackgroundImage(images["go"], for: .normal)
            self.playButton.isHidden = true
            self.modeImage.isHidden = true
            
        case State.recording_tempo:
            self.actionButton.setBackgroundImage(images["recording_tempo"], for: .normal)
            self.playButton.isHidden = true
            self.modeImage.isHidden = true
            
        case State.playing_metronome:
            self.actionButton.setBackgroundImage(images["stop"], for: .normal)
            self.mode = Mode.metronome
            self.playButton.isHidden = true
            self.modeImage.isHidden = false
            
        case State.stopped_metronome:
            self.actionButton.setBackgroundImage(images["speak"], for: .normal)
            self.playButton.isHidden = false
            self.modeImage.isHidden = false
            
        case State.recording_loop:
            self.actionButton.setBackgroundImage(images["recording_loop"], for: .normal)
            self.actionButton.isEnabled = false
            self.mode = Mode.loop
            self.playButton.isHidden = true
            self.modeImage.isHidden = true
            
        case State.playing_loop:
            self.actionButton.setBackgroundImage(images["stop"], for: .normal)
            self.actionButton.isEnabled = true
            self.playButton.isHidden = true
            self.modeImage.isHidden = false
            
        case State.stopped_loop:
            self.actionButton.setBackgroundImage(images["speak"], for: .normal)
            self.playButton.isHidden = false
            self.modeImage.isHidden = false
            
        default:
            return
        }
    }}
    
    var flash = false { didSet {
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
        }else{
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
        
        do{
            player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
            print("loaded file with volume \(player.volume) and \(player.duration)")
        }catch{
            print(error)
        }
        print("playing \(player.isPlaying)")
        
        //set up the audio session and recorder
        setupRecorder()
        
        self.onTick = { (nextTick) in
            self.flash = !self.flash
        }
    }
    
    func transcribeAudioAndTakeAction() {
        let url = getFileURL()
        // create a new recognizer and point it at our audio
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        var transcription = ""

        // start recognition!
        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
            // abort if we didn't get any transcription back
            guard let result = result else {
                print("There was an error: \(error!)")
                return
            }

            // if we got the final transcription back, print it
            if result.isFinal {
                // pull out the best transcription...
                transcription = result.bestTranscription.formattedString
                print("Transcription: \(transcription)")
                self.interpretCommand(command: transcription.lowercased())
            }
            else{
                transcription = ""
            }
        }
    }
    
    func interpretCommand(command: String) {
        print(command)
        
        if command.contains("metronome"){
            self.state = State.playing_metronome
            startMetronome()
        }
        else if command.contains("loop"){
            
            // switch to loop mode
        }
        else if command.contains("set tempo"){
            if command.contains("to"){
                let strArr = command.split(separator: " ")
                for item in strArr {
                    let part = item.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

                    if let intVal = Int(part) {
                        self.bpm = intVal
                    }
                }
            }
            else{
                // start recording to get new temo
                self.recordForTempoAnalysis()
            }
            self.state = State.speak
        }
        else if command.contains("record"){
            recordForLoop()
        }
        else if command.contains("start"){
            // start either metronome or loop, depending on mode
        }
    }
    
    func recordForTempoAnalysis(){
        self.state = State.recording_tempo
        self.recordForTempoAnalysisFlag = true
        soundRecorder.record()
    }
    
    func recordForLoop(){
        self.state = State.recording_loop
        self.recordLoopPlayback = true
        soundRecorder.record()
    }
    
    // function to record/stop recording of audio
    @IBAction func actionButtonPressed(_ sender: UIButton) {
        switch state {
        case State.speak:
            soundRecorder.record()
            print("Recording command")
            self.state = State.listening
            // having "listening" label appear
        case State.listening:
            soundRecorder.stop()
            print("Stopped recording command")
        case State.recording_tempo:
            soundRecorder.stop()
            print("Stopped recording tempo")
        case State.playing_metronome:
            stopMetronome()
        case State.stopped_metronome:
            soundRecorder.record()
            print("Recording")
            self.state = State.listening
        case State.playing_loop:
            stopLoop()
        case State.stopped_loop:
            soundRecorder.record()
            print("Recording")
            self.state = State.listening
        default:
            return
        }
    }
    
    // AVAudioRecorderDelegate delegate function performed upon completion of audio recording
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Successfully recorded")
       // call get transcribed audio text
        
        if self.recordForTempoAnalysisFlag {
            self.recordForTempoAnalysisFlag = false
            self.bpm = findRecordingTempo()
        }
        else if self.recordLoopPlayback{
            self.recordLoopPlayback = false
            startLoop()
        }
        else {
            transcribeAudioAndTakeAction()
        }
    }
    
    func startMetronome(){
        metronome_enabled = true
        self.state = State.playing_metronome
        flash = true
        print("Started metronome")
    }
    
    func stopMetronome(){
        metronome_enabled = false
        self.state = State.stopped_metronome
        view.backgroundColor = .darkGray
        flash = false
        print("Stopped metronome")
    }
    
    func startLoop(){
        print("Started Loop")
    }
    
    func stopLoop(){
        print("Stopped loop")
    }
        
        
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
    func getFileURL() -> URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0] as URL
        let soundURL = documentDirectory.appendingPathComponent(fileName)
          
        return soundURL
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

        print("Tick")
        player.play()
        onTick?(nextTick)
    }
    
    // function that reads in the audiofile and transforms it into a float array
    func readAudioFile() -> [Float]{
        print(getFileURL())
        let file = try! AVAudioFile(forReading: getFileURL())
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false)
        
        let buf = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(file.length))
        try! file.read(into: buf!)
        
        let floatArray = Array(UnsafeBufferPointer(start: buf?.floatChannelData![0], count:Int(buf!.frameLength)))
        return floatArray
    }
    
    func findRecordingTempo() -> Int {
        let audioData : Array = readAudioFile()
        
        var peaks : [Int] = []
        let windowSize = 3000
        
        print(audioData.count)
        for i in 4000..<audioData.count - windowSize {
            var windowMax = audioData[i]
            var windowMaxPosition = i
            
            for j in i..<i + windowSize {
                if(audioData[j] > windowMax) {
                    windowMax = audioData[j]
                    windowMaxPosition = j
                }
            }
            
            if(windowMaxPosition == i + windowSize / 2 && windowMax > 0.15) {
                peaks.append(windowMaxPosition)
            }
        }
        
        var beatsPerMinute = 0.0
        
        if peaks.count > 1 {
            let timeInterval = Double(peaks.last! - peaks.first!) / 44100.0
            beatsPerMinute = Double(peaks.count - 1) / timeInterval * 60            
        }
        
        print("BPM: \(Int(beatsPerMinute.rounded()))")
        
        return Int(beatsPerMinute.rounded())
    }
    
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

