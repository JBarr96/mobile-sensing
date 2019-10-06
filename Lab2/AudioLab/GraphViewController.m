//
//  ViewController.m
//  AudioLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "GraphViewController.h"
#import "SMUGraphHelper.h"
#import "MaxCalculator.h"

#define BUFFER_SIZE 16384
#define FFTSIZE BUFFER_SIZE/2

@interface GraphViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *LockInSwitch;
@property (nonatomic) Boolean lockin;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) MaxCalculator *maxCalculator;
@end



@implementation GraphViewController

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

-(MaxCalculator*)maxCalculator{
    if(!_maxCalculator){
        _maxCalculator = [[MaxCalculator alloc]init];
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
    
    // set the initial position of the lock switch to false
    [self.LockInSwitch setOn: false animated: true];
    self.lockin = false;
   
    // set the graphs to only be on the bottom half of the screen
    [self.graphHelper setScreenBoundsBottomHalf];
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    
    if(self.lockin == false){
        // call on the maxCalculator model to perform audio analysis and store results
        int* maxFreqs = [self.maxCalculator calcMax];
    

        //send off for graphing
        [self.graphHelper setGraphData:self.maxCalculator.getArrayData
                        withDataLength:BUFFER_SIZE
                         forGraphIndex:0];

        // graph the FFT Data
        [self.graphHelper setGraphData:self.maxCalculator.getFFTData
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
    self.maxCalculator.pauseAudioManager;
}

@end
