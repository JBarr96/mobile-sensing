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
    let fileName = "audiofile.m4a"
    let loopPlaybackFileName = "audiofile-loop.m4a"
    
    var bpm: Int = 60 { didSet {
        bpm = min(300,max(30,bpm))
        self.tempoLabel.text = "BPM : \(self.bpm)"
        }}
    var onTick: ((_ nextTick: DispatchTime) -> Void)?
    var nextTick: DispatchTime = DispatchTime.distantFuture
    
    var metronome_enabled: Bool = false { didSet {
        if metronome_enabled {
            start()
        } else {
            stop()
        }
        }}
    
    let recorderSamplingRate = 44100.0
    
    var recordForTempoAnalysis = false
    var recordLoopPlayback = false
    
    var numBarsLoopPlayback = 0
    
    
    @IBOutlet weak var tempoLabel: UILabel!
    @IBOutlet weak var tickLabel: UILabel!
    @IBOutlet weak var transcriptionLabel: UILabel!
    
    @IBOutlet weak var recordButton: UIButton!
    
    private var player:AVAudioPlayer! = nil
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            print(error.description)
        }
        
        // Do any additional setup after loading the view.
        let sound = Bundle.main.path(forResource: "Click", ofType: "wav")
        self.setupAudioPlayer(audioFileURL: URL(fileURLWithPath: sound!))
        
        //set up the audio session and recorder
//        setupAudio()
        setupRecorder(recordingFileName: self.fileName)

        
        self.onTick = { (nextTick) in
            self.animateTick()
        }
    }
    
    private func animateTick() {
        tickLabel.alpha = 1.0
        UIView.animate(withDuration: 0.35) {
            self.tickLabel.alpha = 0.0
        }
    }
    
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
                print("There was an error: \(error!)")
                return
            }

            // if we got the final transcription back, print it
            if result.isFinal {
                // pull out the best transcription...
                transcription = result.bestTranscription.formattedString
                print("Transcription: \(transcription)")
                self.transcriptionLabel.text = transcription
                
                self.interpretCommand(command: transcription.lowercased())
            }
            else{
                transcription = ""
            }
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
    
    // function to set up the audio session
    func setupAudio(){
        if audioSession.recordPermission() == .granted {
            do {
                try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.mixWithOthers)
                try audioSession.setActive(true)
                print("AudioSession set up")
            } catch {
                print("  ERROR setting audio session: \(error)" )
            }
        }else{
            print("  ERROR Permission to Audio Denied... Check settings")
        }
    }
    
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
    
    // function to record/stop recording of audio
    @IBAction func recordSound(_ sender: UIButton) {
        if (sender.titleLabel?.text == "Record"){
            if self.player.isPlaying {
                self.player.pause()
            }
            
            soundRecorder.record()
            print("Recording")
            sender.setTitle("Stop", for: .normal)
        } else {
            soundRecorder.stop()
            print("Stopped recording")
            sender.setTitle("Record", for: .normal)
        }
    }
    
    @IBAction func startStopMetronome(_ sender: UIButton) {
        if (sender.titleLabel?.text == "Start Metronome"){
            // set up the audio player
            let sound = Bundle.main.path(forResource: "Click", ofType: "wav")
            self.setupAudioPlayer(audioFileURL: URL(fileURLWithPath: sound!))
            
            metronome_enabled = true
            sender.setTitle("Stop Metronome", for: .normal)
        } else {
            metronome_enabled = false
            sender.setTitle("Start Metronome", for: .normal)
        }
    }
    
    private func start() {
        print("Starting metronome, BPM: \(bpm)")
        player.prepareToPlay()
        nextTick = DispatchTime.now()
        tick()
    }

    private func stop() {
        player.stop()
        print("Stoping metronome")
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

        player.play()
        onTick?(nextTick)
    }
    
    func interpretCommand(command: String) {
        print(command)
        
        if command.contains("metronome"){
            // switch to metronome mode
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
                self.recordForTempoAnalysis = true
                
                // start recording to get new temo
                self.recordButton.sendActions(for: .touchUpInside)
            }
        }
        else if command.contains("record for"){
            let strArr = command.split(separator: " ")
            var numBars = 0
            
            for item in strArr {
                let part = item.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                
                if let intVal = Int(part) {
                    numBars = intVal
                    break
                }
                else {
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
                self.recordLoopPlayback = true
                self.numBarsLoopPlayback = numBars
                
                let interval: TimeInterval = Double(numBars) / (Double(self.bpm) / 60.0)
                
                let sound = Bundle.main.path(forResource: "Click", ofType: "wav")
                self.setupAudioPlayer(audioFileURL: URL(fileURLWithPath: sound!))
                self.player.prepareToPlay()
                
                let metronomeInterval: TimeInterval = 60.0 / TimeInterval(bpm)
                
                self.player.play()
                let timer = Timer.scheduledTimer(withTimeInterval: metronomeInterval, repeats: true, block: { timer in
                    self.player.play()
                })
                
                DispatchQueue.main.asyncAfter(deadline: .now() + metronomeInterval * 3.9) { [weak self] in
                    timer.invalidate()
                    
                    // start recording
                    self?.setupRecorder(recordingFileName: self!.loopPlaybackFileName)
                    self?.recordButton.sendActions(for: .touchUpInside)
                    self?.recordButton.isEnabled = false
                    
                    // stop recording
                    DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
                        self?.recordButton.isEnabled = true
                        self?.recordButton.sendActions(for: .touchUpInside)
                    }
                }
            }
        }
        else if command.contains("start"){
            // start either metronome or loop, depending on mode
        }
    }
    
    func startLoopPlayback() {
        // set up audio player for loop playback
        self.setupAudioPlayer(audioFileURL: getFileURL(fileName: self.loopPlaybackFileName))
        
        self.player.numberOfLoops = -1
        self.player.volume = 80.0

        self.player.prepareToPlay()
        self.player.play()
    }
    
    // AVAudioRecorderDelegate delegate function performed upon completion of audio recording
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Successfully recorded")
       // call get transcribed audio text
        
        if self.recordForTempoAnalysis {
            self.recordForTempoAnalysis = false
            self.bpm = findRecordingTempo()
            // set metronome to new beatsPerMinute
        }
        else if self.recordLoopPlayback {
            startLoopPlayback()
            
            // reset audio recorder
            self.recordLoopPlayback = false
            self.setupRecorder(recordingFileName: self.fileName)
        }
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
    
    func findRecordingTempo() -> Int {
        let audioData : Array = readAudioFile()
        
        var peaks : [Int] = []
        let windowSize = 3000
        
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
}

