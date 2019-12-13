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
    
    var recordForTempoAnalysis = false
    
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
        
        do{
            player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
            print("loaded file with volume \(player.volume) and \(player.duration)")
        }catch{
            print(error)
        }
        print("playing \(player.isPlaying)")
        
        //set up the audio session and recorder
//        setupAudio()
        setupRecorder()

        
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
                self.transcriptionLabel.text = transcription
                
                self.interpretCommand(command: transcription.lowercased())
            }
            else{
                transcription = ""
            }
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
        } else {
            soundRecorder.stop()
            print("Stopped recording")
            sender.setTitle("Record", for: .normal)
        }
    }
    
    @IBAction func startStopMetronome(_ sender: UIButton) {
        if (sender.titleLabel?.text == "Start Metronome"){
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

        print("Tick")
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
        else if command.contains("record"){
            // record loop
        }
        else if command.contains("start"){
            // start either metronome or loop, depending on mode
        }
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
        else {
            transcribeAudioAndTakeAction()
        }
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
            print(i)
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

