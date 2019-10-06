//
//  ViewController.m
//  AudioLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "GraphViewController.h"
#import "Novocaine.h"
#import "SMUGraphHelper.h"
#import "MaxCalculator.h"

#define BUFFER_SIZE 16384
#define FFTSIZE BUFFER_SIZE/2

@interface GraphViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *LockInSwitch;
@property (nonatomic) Boolean lockin;
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) MaxCalculator *maxCalculator;
@end



@implementation GraphViewController

#pragma mark Lazy Instantiation
-(Novocaine*)audioManager{
    if(!_audioManager){
        _audioManager = [Novocaine audioManager];
    }
    return _audioManager;
}

-(CircularBuffer*)buffer{
    if(!_buffer){
        _buffer = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:BUFFER_SIZE];
    }
    return _buffer;
}

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

-(FFTHelper*)fftHelper{
    if(!_fftHelper){
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    
    return _fftHelper;
}

-(MaxCalculator*)maxCalculator{
    if(!_maxCalculator){
        _maxCalculator = [[MaxCalculator alloc]initWithView: self];
    }
    
    return _maxCalculator;
}

- (IBAction)LockInSwitchDidChange:(UISwitch *)sender {
    if ([sender isOn]) {
        self.lockin = true;
    }
    else{
        self.lockin = false;
    }
}

#pragma mark VC Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.LockInSwitch setOn: false animated: true];
    self.lockin = false;
   
    [self.graphHelper setScreenBoundsBottomHalf];
    
    __block GraphViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    
    [self.audioManager play];
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    
    if(self.lockin == false){
        // call on the maxCalculator model to perform audio analysis
        int* maxFreqs = [self.maxCalculator calcMax];
    

        //send off for graphing
        [self.graphHelper setGraphData:self.maxCalculator.arrayData
                        withDataLength:BUFFER_SIZE
                         forGraphIndex:0];

        // graph the FFT Data
        [self.graphHelper setGraphData:self.maxCalculator.fftMagnitude
                        withDataLength:FFTSIZE
                         forGraphIndex:1
                     withNormalization:64.0
                         withZeroValue:-60];

        // update the labels
        self.MaxFreq1Label.text = [NSString stringWithFormat:@"Max Freq 1: %d", maxFreqs[0]];
        self.MaxFreq2Label.text = [NSString stringWithFormat:@"Max Freq 2: %d", maxFreqs[1]];
        
        // update the graph
        [self.graphHelper update];
    }
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

// pause the audiomanager and set all blocks to nil for switching between modules
-(void)viewWillDisappear:(BOOL)animated{
    [self.audioManager pause];
    [self.audioManager setOutputBlock:nil];
    [self.audioManager setInputBlock:nil];
}

@end
