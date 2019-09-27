//
//  ViewController.m
//  AudioLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "GraphViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "SMUGraphHelper.h"
#import "FFTHelper.h"

#define BUFFER_SIZE 2048*4
#define FFTSIZE BUFFER_SIZE/2

@interface GraphViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (weak, nonatomic) IBOutlet UILabel *MaxFreq1Label;
@property (weak, nonatomic) IBOutlet UILabel *MaxFreq2Label;
@property (nonatomic) float *maxArray;
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
                                                       numGraphs:3
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

-(float*)maxArray{
    if(!_maxArray){
        _maxArray = malloc(sizeof(float)*20);
    }
    return _maxArray;
}


#pragma mark VC Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
   
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
    // just plot the audio stream
    
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    int step = FFTSIZE/20;
    float* fftMagnitude = malloc(sizeof(float)*FFTSIZE);
    float df = 44100/FFTSIZE;
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
    //send off for graphing
    [self.graphHelper setGraphData:arrayData
                    withDataLength:BUFFER_SIZE
                     forGraphIndex:0];
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    // graph the FFT Data
    [self.graphHelper setGraphData:fftMagnitude
                    withDataLength:FFTSIZE
                     forGraphIndex:1
                 withNormalization:64.0
                     withZeroValue:-60];
    
    for(int i = 0; i < 20; i++) {
        self.maxArray[i] = -1000;
    }
    
    float* peakfft = malloc(sizeof(float)*BUFFER_SIZE);
    float* peakInterpol = malloc(sizeof(float)*BUFFER_SIZE);
    int arrayPtr = 0;
    
    float f2 = 0;
    float m1 = 0;
    float m2 = 0;
    float m3 = 0;

    for(int i = 0; i < BUFFER_SIZE/2 - 3; i++){
        f2 = i*df;
        m1 = fftMagnitude[i];
        m2 = fftMagnitude[i+1];
        m3 = fftMagnitude[i+2];
        if(m2 > m1 && m2 > m3){
            peakfft[arrayPtr] = f2;
            peakInterpol[arrayPtr] = f2 + ((m3-m1)/(m3-2*m2+m1)) * (df/2);
        }
    }
    
    float maxActualFFT = 0;
    float maxActualInterpol = 0;
    for(int i = 0; i < BUFFER_SIZE; i++){
        if(peakInterpol[i] > maxActualInterpol){
            maxActualInterpol = peakInterpol[i];
            maxActualFFT = peakfft[i];
        }
    }
    
    self.MaxFreq1Label.text = [NSString stringWithFormat:@"Max  Frequency 1: %f", maxActualInterpol];
    
//    int arrayIndex = 0;
//    for(int i = 0; i < BUFFER_SIZE/2; i++){
//        if (count < step){
//            if (self.maxArray[arrayIndex] < fftMagnitude[i]) {
//                self.maxArray[arrayIndex] = fftMagnitude[i];
//            }
//        } else {
//            arrayIndex++;
//            count = 0;
//        }
//        count++;
//    }
    
    // graph the FFT Data
    [self.graphHelper setGraphData:self.maxArray
                    withDataLength:20
                     forGraphIndex:2
                 withNormalization:64.0
                     withZeroValue:-60];
    
    [self.graphHelper update]; // update the graph
    free(arrayData);
    free(fftMagnitude);
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}


@end
