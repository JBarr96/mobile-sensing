//
//  DopplerViewController.m
//  AudioLab
//
//  Created by Johnathan Barr on 9/26/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import "DopplerViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "SMUGraphHelper.h"
#import "FFTHelper.h"

#define BUFFER_SIZE 16384
#define SAMPLING_RATE 44100.0
#define DF ((float)SAMPLING_RATE/(float)BUFFER_SIZE)

@interface DopplerViewController ()
@property (weak, nonatomic) IBOutlet UILabel *motionIndicatorLabel;
@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;
@property (nonatomic) float frequency;
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) FFTHelper *fftHelper;
@end


@implementation DopplerViewController

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

-(void)viewDidLoad{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.frequency = 17500;
    self.frequencyLabel.text = [NSString stringWithFormat:@"%d Hz", (int) self.frequency];

    [self.graphHelper setScreenBoundsBottomHalf];
    
    __block DopplerViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    
    [self.audioManager play];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.audioManager = [Novocaine audioManager];

    __block float phase = 0.0;
    __block float samplingRate = self.audioManager.samplingRate;
    __block DopplerViewController * __weak weakSelf = self;

    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
         double phaseIncrement = 2 * M_PI * weakSelf.frequency / samplingRate;
         double sineWaveRepeatMax = 2 * M_PI;
         
         for (int i=0; i < numFrames; ++i){
             float theta = phase;
             data[i] = sin(theta);

             phase += phaseIncrement;
             if (phase >= sineWaveRepeatMax) phase -= sineWaveRepeatMax;
         }
     }];
    
    [self.audioManager play];
}

-(IBAction)changeFrequency:(UISlider *)sender{
    self.frequency = sender.value;
    self.frequencyLabel.text = [NSString stringWithFormat:@"%d Hz", (int) self.frequency];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.audioManager pause];
    [self.audioManager setOutputBlock:nil];
    [self.audioManager setInputBlock:nil];
}

-(void)update{
    // get audio stream data
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    int fftCurrentFrequencyIndex = self.frequency / DF;
    float baseSignalValue = fabsf(fftMagnitude[fftCurrentFrequencyIndex]);
    
    float signalLeft = 0;
    for(int i = fftCurrentFrequencyIndex - 5; i > fftCurrentFrequencyIndex - 8; i--) {
        signalLeft += fabsf(fftMagnitude[i]);
    }
    signalLeft = signalLeft / 3;
    
    float signalRight = 0;
    for(int i = fftCurrentFrequencyIndex + 5; i < fftCurrentFrequencyIndex + 8; i++) {
        signalRight += fabsf(fftMagnitude[i]);
    }
    signalRight = signalRight / 3;

    float ratioLeft = baseSignalValue / signalLeft;
    float ratioRight = baseSignalValue / signalRight;
    
    if(ratioLeft < ratioRight * 0.75){
        self.motionIndicatorLabel.text = @"Gesturing Towards";
    }
    else if(ratioRight < ratioLeft * 0.8){
        self.motionIndicatorLabel.text = @"Gesturing Away";
    }
    else{
        self.motionIndicatorLabel.text = @"Not Gesturing";
    }
    
    // graph the FFT Data
    [self.graphHelper setGraphData:fftMagnitude
                    withDataLength:BUFFER_SIZE/2
                     forGraphIndex:0
                 withNormalization:64.0
                     withZeroValue:-60];
    
    [self.graphHelper update]; // update the graph
    free(arrayData);
    free(fftMagnitude);
}

//  override the GLKView draw function, from OpenGLES
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    [self.graphHelper draw]; // draw the graph
}

@end
