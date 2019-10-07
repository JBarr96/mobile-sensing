//
//  GestureAnalyzer.m
//  AudioLab
//
//  Created by Remus Tumac on 10/6/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import "GestureAnalyzer.h"
#import "FFTHelper.h"
#import "Novocaine.h"
#import "CircularBuffer.h"

#define BUFFER_SIZE 16384
#define SAMPLING_RATE 44100.0
#define DF ((float)SAMPLING_RATE/(float)BUFFER_SIZE)

@interface GestureAnalyzer()
@property (nonatomic) float frequency;
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;
@end

@implementation GestureAnalyzer

// initialize the GestureAnalyzer
- (id)init{
    if (self = [super init]){
        __block GestureAnalyzer * __weak  weakSelf = self;
        
        // set the audio manager to listen to the microphone
        [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
            [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
        }];
        
        __block float phase = 0.0;
        __block float samplingRate = self.audioManager.samplingRate;
        
        // set the audio manager to play one desired frequency
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
        
        return self;
    }
    return nil;
}

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

-(FFTHelper*)fftHelper{
    if(!_fftHelper){
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    return _fftHelper;
}

// array for the FFT magnitude data
-(float*)fftMagnitude{
    if(!_fftMagnitude){
        _fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
    }
    return _fftMagnitude;
}

// function to read the latest FFT data and look for hand gestures
-(int)getGesture:(float)frequency{
    self.frequency = frequency;
    
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    
    // pull in the most recent microphone data
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:self.fftMagnitude];
    
    // retreive base frequency FFT value
    int fftCurrentFrequencyIndex = self.frequency / DF;
    float baseSignalValue = fabsf(self.fftMagnitude[fftCurrentFrequencyIndex]);
    
    // calculate signal value on the left of base frequency
    float signalLeft = 0;
    for(int i = fftCurrentFrequencyIndex - 5; i > fftCurrentFrequencyIndex - 8; i--) {
        signalLeft += fabsf(self.fftMagnitude[i]);
    }
    signalLeft = signalLeft / 3;
    
    // calculate signal value on the right of base frequency
    float signalRight = 0;
    for(int i = fftCurrentFrequencyIndex + 5; i < fftCurrentFrequencyIndex + 8; i++) {
        signalRight += fabsf(self.fftMagnitude[i]);
    }
    signalRight = signalRight / 3;
    
    float ratioLeft = baseSignalValue / signalLeft;
    float ratioRight = baseSignalValue / signalRight;
    
    free(arrayData);
    
    // compare ratios to find if gesturing away or towards
    if(ratioLeft < ratioRight * 0.75){
        return 1; // gesturing towards
    }
    else if(ratioRight < ratioLeft * 0.8){
        return -1; // gesturing away
    }

    return 0; // not gesturing
}

// function to pause the audiomanager and set all blocks to nil
-(void)pauseAudioManager{
    [self.audioManager pause];
    [self.audioManager setOutputBlock:nil];
    [self.audioManager setInputBlock:nil];
}

-(void)dealloc {
    free(self.fftMagnitude);
    self.fftMagnitude = nil;
}

@end
