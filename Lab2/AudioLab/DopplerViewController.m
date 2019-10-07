//
//  DopplerViewController.m
//  AudioLab
//
//  Created by Johnathan Barr on 9/26/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import "DopplerViewController.h"
#import "SMUGraphHelper.h"
#import "GestureAnalyzer.h"

#define BUFFER_SIZE 16384

@interface DopplerViewController ()
@property (weak, nonatomic) IBOutlet UILabel *motionIndicatorLabel;
@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) GestureAnalyzer *gestureAnalyzer;
@property (nonatomic) float frequency;
@end


@implementation DopplerViewController

#pragma mark Lazy Instantiation
-(SMUGraphHelper*)graphHelper{
    if(!_graphHelper){
        _graphHelper = [[SMUGraphHelper alloc]initWithController:self
                                        preferredFramesPerSecond:15
                                                       numGraphs:2
                                                       plotStyle:PlotStyleSeparated
                                               maxPointsPerGraph:BUFFER_SIZE];
    }
    return _graphHelper;
}

-(GestureAnalyzer*)gestureAnalyzer{
    if(!_gestureAnalyzer){
        _gestureAnalyzer = [[GestureAnalyzer alloc]init];
    }
    
    return _gestureAnalyzer;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // set default frequency
    self.frequency = 17500;
    self.frequencyLabel.text = [NSString stringWithFormat:@"%d Hz", (int) self.frequency];
    
    // set the graphs to only be on the bottom half of the screen
    [self.graphHelper setScreenBoundsBottomHalf];
}

//update frequency property and label when slider changes
-(IBAction)changeFrequency:(UISlider *)sender{
    self.frequency = sender.value;
    self.frequencyLabel.text = [NSString stringWithFormat:@"%d Hz", (int) self.frequency];
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
-(void)update{
    // get gesture reading
    int gesture = [self.gestureAnalyzer getGesture:self.frequency];
    
    // update gesture label
    if(gesture == 1){
        self.motionIndicatorLabel.text = @"Gesturing Towards";
    }
    else if(gesture == -1){
        self.motionIndicatorLabel.text = @"Gesturing Away";
    }
    else{
        self.motionIndicatorLabel.text = @"Not Gesturing";
    }
    
    // graph the FFT Magnitude Data
    [self.graphHelper setGraphData:self.gestureAnalyzer.fftMagnitude
                    withDataLength:BUFFER_SIZE/2
                     forGraphIndex:0
                 withNormalization:64.0
                     withZeroValue:-60];
    
    // update the graph
    [self.graphHelper update];
}

//  override the GLKView draw function, from OpenGLES
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    [self.graphHelper draw]; // draw the graph
}

// pause the audiomanager and set all blocks to nil for switching between modules
-(void)viewWillDisappear:(BOOL)animated{
    [self.gestureAnalyzer pauseAudioManager];
}

@end
