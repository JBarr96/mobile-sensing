//
//  FacialViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import AVFoundation

class FacialViewController: UIViewController   {

    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    let pinchFilterIndex = 2
    var detector:CIDetector! = nil
    let bridge = OpenCVBridge()
    
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
        
        var retImage = applyFiltersToFaces(inputImage: inputImage, features: faces)
        
        return retImage
    }
    
    //MARK: Setup filtering
    func setupFilters(){
        filters = []
        
        let filterPinch = CIFilter(name:"CIBumpDistortion")!
        filterPinch.setValue(-0.5, forKey: "inputScale")
        filterPinch.setValue(75, forKey: "inputRadius")
        filters.append(filterPinch)
        
    }
    
    //MARK: Apply filters and apply feature detectors
    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        var filterCenter = CGPoint()
        
        for f in features {
            //set where to apply filter
            filterCenter.x = f.bounds.midX
            filterCenter.y = f.bounds.midY
            
            // both eyes closed
            if !(f.hasLeftEyePosition && f.hasRightEyePosition){
                
            }else{
                // if they have a left eye position
                if f.hasLeftEyePosition{
                    retImage = applyFiltersToEye(inputImage: retImage, eyePosition: f.leftEyePosition)
                }
                // otherwise they are blinking with their left eye
                else{
                    
                }
                
                // if they have a right eye position
                if f.hasRightEyePosition{
                    retImage = applyFiltersToEye(inputImage: retImage, eyePosition: f.rightEyePosition)
                }
                // otherwise they are blinkin with their right eye
                else{
                    
                }
            }
            
            if f.hasMouthPosition{
                retImage = applyFiltersToMouth(inputImage: retImage, mouthPosition: f.mouthPosition, smile: f.hasSmile)
            }
            
            let faceFilter = CIFilter(name:"CIBumpDistortion")!
            faceFilter.setValue(0.5, forKey: "inputScale")
            faceFilter.setValue(75, forKey: "inputRadius")
            faceFilter.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
            faceFilter.setValue(retImage, forKey: kCIInputImageKey)
            
            // could also manipualte the radius of the filter based on face size!
            retImage = faceFilter.outputImage!
        }
        return retImage
    }
    
    func applyFiltersToEye(inputImage:CIImage, eyePosition:CGPoint)->CIImage{
        var retImage = inputImage
        
        let eyeFilter = CIFilter(name: "CIBumpDistortion")
        return retImage
    }
    
    func applyFiltersToMouth(inputImage:CIImage, mouthPosition: CGPoint, smile: Bool)->CIImage{
        var retImage = inputImage
        return retImage
    }
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
}

