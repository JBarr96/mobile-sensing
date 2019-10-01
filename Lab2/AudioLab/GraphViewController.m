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

#define BUFFER_SIZE 16384
#define FFTSIZE BUFFER_SIZE/2
#define SAMPLING_RATE 44100.0

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
    float* fftMagnitude = malloc(sizeof(float)*FFTSIZE);
    float df;
    df = (float)SAMPLING_RATE/(float)BUFFER_SIZE;
    
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
    float* peakfftpos = malloc(sizeof(float)*BUFFER_SIZE);
    int arrayPtr = 0;

    int windowsize = 5;


    //sliding window
    for(int i = 50; i < BUFFER_SIZE/2 - windowsize; i++){
        float windowmax = -1000;
        int maxpos = 0;
        for(int j = i; j < i + windowsize; j++){
            if(fftMagnitude[j] > windowmax){
                windowmax = fftMagnitude[j];
                maxpos = j;
            }
        }
        if(maxpos == i + windowsize/2){
            peakfft[arrayPtr] = windowmax;
            peakfftpos[arrayPtr] = maxpos;
            arrayPtr += 1;
        }
    }
    
    float maxActualFFT1 = -1000;
    float maxActualFFT2 = -1000;
    float maxActualPos1 = -1;
    float maxActualPos2 = -1;
    
    // calculate the max of the max
    for(int i = 0; i < BUFFER_SIZE; i++){
        // if the current item is larger than the first max
        if(peakfft[i] > maxActualFFT1){
            // set the second max to the previous first max
            maxActualFFT2 = maxActualFFT1;
            maxActualPos2 = maxActualPos1;
            
            // set the first max to the current item
            maxActualFFT1 = peakfft[i];
            maxActualPos1 = peakfftpos[i];
        }
        // otherwise, if the current item is larger than the second max
        else if (peakfft[i] > maxActualFFT2){
            // simply set the second max to the current item (does not affect first max at all)
            maxActualFFT2 = peakfft[i];
            maxActualPos2 = peakfftpos[i];
        }
    }
    
    // calculate the the actual frequencies of the maximum FFTs
    int maxFreq1 = (int)(maxActualPos1 * df);
    int maxFreq2 = (int)(maxActualPos2 * df);
    
    // update the labels
    self.MaxFreq1Label.text = [NSString stringWithFormat:@"Max Freq 1: %d", maxFreq1];
    self.MaxFreq2Label.text = [NSString stringWithFormat:@"Max Freq 2: %d", maxFreq2];
    
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
