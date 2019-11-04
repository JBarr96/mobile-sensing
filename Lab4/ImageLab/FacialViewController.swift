//
//  FacialViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//
//  Johnathan Barr and Remus Tumac

import UIKit
import AVFoundation

class FacialViewController: UIViewController   {

    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    let pinchFilterIndex = 2
    var detector:CIDetector! = nil
    let bridge = OpenCVBridge()
    @IBOutlet weak var detailLabel: UILabel!
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        
        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.front)
        
        // create dictionary for face detection
        // HINT: you need to manipulate these proerties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyLow,CIDetectorTracking:true] as [String : Any]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: self.videoManager.getCIContext(), // perform on the GPU is possible
            options: (optsDetector as [String : AnyObject]))
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
    
    }
    
    //MARK: Process image output
    func processImage(inputImage:CIImage) -> CIImage{
        
        // detect faces
        let faces = getFaces(img: inputImage)
        
        // if no faces, just return original image
        if faces.count == 0 { return inputImage }
        
        // apply all necessary filters (depending on features detected)
        let retImage = applyFiltersToFaces(inputImage: inputImage, faces: faces)
        
        // return the altered image
        return retImage
    }
    
    //MARK: Apply filters and apply feature detectors
    func applyFiltersToFaces(inputImage:CIImage,faces:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        var filterCenter = CGPoint()
        var labelString = ""
        
        // variable to keep track of how many faces are in the frame (to show which person is blinking/smiling/etc.)
        var faceCount = 1
        
        // for all faces retrieved
        for face in faces {
            //set where to apply filter
            filterCenter.x = face.bounds.midX
            filterCenter.y = face.bounds.midY
            
            // both eyes closed
            if face.leftEyeClosed && face.rightEyeClosed{
                labelString += "Person \(faceCount) is blinking with BOTH eyes\n"
            }else{
                // if they have a left eye position
                if !face.leftEyeClosed && face.hasLeftEyePosition{
                    retImage = applyFiltersToEye(inputImage: retImage, eyePosition: face.leftEyePosition)
                }
                // otherwise they are blinking with their left eye
                else{
                    labelString += "Person \(faceCount) is blinking with their LEFT eye\n"
                }
                
                // if they have a right eye position
                if !face.rightEyeClosed && face.hasRightEyePosition{
                    retImage = applyFiltersToEye(inputImage: retImage, eyePosition: face.rightEyePosition)
                }
                // otherwise they are blinkin with their right eye
                else{
                    labelString += "Person \(faceCount) is blinking with their RIGHT eye\n"
                }
            }
            
            // if they have a mouthposition
            if face.hasMouthPosition{
                // apply a filter to the mouth
                retImage = applyFiltersToMouth(inputImage: retImage, mouthPosition: face.mouthPosition, smiling: face.hasSmile)
                // display whether or not the person is smiling
                if face.hasSmile{
                    labelString += "Person \(faceCount) is smiling\n"
                }
            }
            
            // apply a swirl filter to the entire face
            let faceFilter = CIFilter(name:"CITwirlDistortion")!
            faceFilter.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
            faceFilter.setValue(95, forKey: "inputRadius")
            faceFilter.setValue(0.75, forKey: "inputAngle")
            faceFilter.setValue(retImage, forKey: kCIInputImageKey)
            retImage = faceFilter.outputImage!
            
            // increment the number of faces
            faceCount += 1
        }
        
        // update the details label with any information on the main queue
        DispatchQueue.main.async {
            self.detailLabel.text = labelString
        }
        
        // return the altered image
        return retImage
    }
    
    // function to apply the bump distortion filter to a given eye's position
    func applyFiltersToEye(inputImage:CIImage, eyePosition:CGPoint)->CIImage{
        let eyeFilter = CIFilter(name:"CIBumpDistortion")!
        eyeFilter.setValue(inputImage, forKey: kCIInputImageKey)
        eyeFilter.setValue(CIVector(cgPoint: eyePosition), forKey: "inputCenter")
        eyeFilter.setValue(0.5, forKey: "inputScale")
        eyeFilter.setValue(50, forKey: "inputRadius")

        return eyeFilter.outputImage!
    }
    
    // function to apply a filter to a given mouth's position
    func applyFiltersToMouth(inputImage:CIImage, mouthPosition: CGPoint, smiling: Bool)->CIImage{
        // using a bump filter as the base
        let mouthFilter = CIFilter(name:"CIBumpDistortion")!
        mouthFilter.setValue(50, forKey: "inputRadius")
        
        // if the person is smiling, have it bulge outward
        if smiling{
            mouthFilter.setValue(1, forKey: "inputScale")
        }
        // otherwise, have it pinch inwards
        else{
            mouthFilter.setValue(-1, forKey: "inputScale")
        }
        
        mouthFilter.setValue(inputImage, forKey: kCIInputImageKey)
        mouthFilter.setValue(CIVector(cgPoint: mouthPosition), forKey: "inputCenter")
        

        return mouthFilter.outputImage!
    }
    
    // function to get faces from a given image
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation, CIDetectorSmile: true, CIDetectorEyeBlink: true] as [String : Any]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
}

