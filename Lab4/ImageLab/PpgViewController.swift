//
//  PpgViewController.swift
//  ImageLab
//
//  Created by Johnathan Barr on 10/28/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

import UIKit
import Charts
import Foundation


class PpgViewController: UIViewController  {
    
    var videoManager:VideoAnalgesic! = nil
    let bridge = OpenCVBridge()

    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var heartRateLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        
        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)

        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
        
        self.bridge.processType = 1
        
        self.bridge.setTransforms(self.videoManager.transform)
        
        lineChartView.xAxis.drawGridLinesEnabled = false
        lineChartView.leftAxis.drawGridLinesEnabled = false
        lineChartView.rightAxis.drawGridLinesEnabled = false
        
        lineChartView.xAxis.drawLabelsEnabled = false
        lineChartView.leftAxis.drawLabelsEnabled = false
        lineChartView.rightAxis.drawLabelsEnabled = false
        
        lineChartView.legend.enabled = false
        
        lineChartView.drawBordersEnabled = false
    }
    
    func processImage(inputImage:CIImage) -> CIImage{
        self.videoManager.turnOnFlashwithLevel(1)
        
        var retImage = inputImage

        self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
        let redArray = self.bridge.processImage()!
        
        DispatchQueue.main.async(){
            self.setChart(values: redArray)
            
            if(self.bridge.heartRate == 0) {
                self.heartRateLabel.text = "Heart rate: measuring ..."
            }
            else {
                self.heartRateLabel.text = "Heart rate: \(self.bridge.heartRate)"
            }
        }
        
        retImage = self.bridge.getImage()
        
        return retImage
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.videoManager.turnOffFlash()
        self.videoManager.shutdown()
        
        lineChartView.delegate = nil
        lineChartView.xAxis.valueFormatter = nil
    }
    
    func setChart(values: UnsafeMutablePointer<Float>) {
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<130 {
            let dataEntry = ChartDataEntry(x: Double(i), y: Double(values[i]))
            dataEntries.append(dataEntry)
        }
        
        let lineChartDataSet = LineChartDataSet(entries: dataEntries)
        lineChartDataSet.drawCirclesEnabled = false
        lineChartDataSet.drawValuesEnabled = false
        let lineChartData = LineChartData(dataSet: lineChartDataSet)
        lineChartView.data = lineChartData
        lineChartView.setNeedsDisplay()
    }
}
