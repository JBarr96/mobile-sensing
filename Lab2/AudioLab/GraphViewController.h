//
//  ViewController.h
//  AudioLab
//
//  Created by Eric Larson on 8/24/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "CircularBuffer.h"
#import "FFTHelper.h"

@interface GraphViewController : GLKViewController
// all public properties that will be need to be accessed by the maxCalculator model
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (weak, nonatomic) IBOutlet UILabel *MaxFreq1Label;
@property (weak, nonatomic) IBOutlet UILabel *MaxFreq2Label;
@end

