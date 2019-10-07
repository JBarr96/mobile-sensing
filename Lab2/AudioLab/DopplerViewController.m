//
//  DopplerViewController.m
//  AudioLab
//
//  Created by Johnathan Barr on 9/26/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import "DopplerViewController.h"
#import "SMUGraphHelper.h"
#import "CircularBuffer.h"
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
    
    self.frequency = 17500;
    self.frequencyLabel.text = [NSString stringWithFormat:@"%d Hz", (int) self.frequency];
    
    [self.graphHelper setScreenBoundsBottomHalf];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(IBAction)changeFrequency:(UISlider *)sender{
    self.frequency = sender.value;
    self.frequencyLabel.text = [NSString stringWithFormat:@"%d Hz", (int) self.frequency];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.gestureAnalyzer pauseAudioManager];
}

-(void)update{
    // get audio stream data
    int gesture = [self.gestureAnalyzer getGesture:self.frequency];
    
    if(gesture == 1){
        self.motionIndicatorLabel.text = @"Gesturing Towards";
    }
    else if(gesture == -1){
        self.motionIndicatorLabel.text = @"Gesturing Away";
    }
    else{
        self.motionIndicatorLabel.text = @"Not Gesturing";
    }
    
    // graph the FFT Data
    [self.graphHelper setGraphData:self.gestureAnalyzer.fftMagnitude
                    withDataLength:BUFFER_SIZE/2
                     forGraphIndex:0
                 withNormalization:64.0
                     withZeroValue:-60];
    
    [self.graphHelper update]; // update the graph
}

//  override the GLKView draw function, from OpenGLES
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    [self.graphHelper draw]; // draw the graph
}

@end
