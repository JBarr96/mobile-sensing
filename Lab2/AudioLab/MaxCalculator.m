//
//  MaxCalculator.m
//  AudioLab
//
//  Created by Johnathan Barr on 10/1/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MaxCalculator.h"
#import "GraphViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "FFTHelper.h"

#define BUFFER_SIZE 16384
#define FFTSIZE BUFFER_SIZE/2
#define SAMPLING_RATE 44100.0
#define DF (float)SAMPLING_RATE/(float)BUFFER_SIZE
#define WINDOW_SIZE 7

@interface MaxCalculator ()
@property (strong, nonatomic) GraphViewController *graphview;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) FFTHelper *fftHelper;
-(void)refreshData;
-(void)refreshArrayData;
-(void)refreshFFTData;
@end


@implementation MaxCalculator

#pragma mark Lazy Instantiation

// array for the raw data being read in from the microphone
-(float*)arrayData{
    if(!_arrayData){
        _arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    }
    return _arrayData;
}

// array for the FFT magnitude data
-(float*)fftMagnitude{
    if(!_fftMagnitude){
        _fftMagnitude = malloc(sizeof(float)*FFTSIZE);
    }
    return _fftMagnitude;
}

// Novocaine audioManager for processing audio
-(Novocaine*)audioManager{
    if(!_audioManager){
        _audioManager = [Novocaine audioManager];
    }
    return _audioManager;
}

// circular buffer for filling with
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

// function to initialize with a GraphViewController
// this is needed to allow for updating of the labels
- (id)initWithView: (GraphViewController*)view
{
    if (self = [super init])
    {
        _graphview = view;
        __block MaxCalculator * __weak  weakSelf = self;
        [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
            [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
        }];

        [self.audioManager play];
        [self refreshData];
        return self;
    }
    return nil;
}



-(void)refreshArrayData{
    // refresh array data
    [self.buffer fetchFreshData:self.arrayData withNumSamples:BUFFER_SIZE];
}

-(float*)getArrayData{
    self.refreshArrayData;
    return self.arrayData;
}

-(void)refreshFFTData{
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:self.arrayData
                   andCopydBMagnitudeToBuffer:self.fftMagnitude];
}

-(float*)getFFTData{
    self.refreshFFTData;
    return self.fftMagnitude;
}

// function to refresh both the arrayData buffer and FFT data
-(void)refreshData{
    self.refreshArrayData;
    self.refreshFFTData;
}

// function for actually processing the FFT and updating the view
-(int*)calcMax{
    // pull in the most recent data into the array and FFT
    [self refreshData];
    
    // array to be populated with local FFT magnitude maxima
    float* peakfft = malloc(sizeof(float)*BUFFER_SIZE);
    // array to be populated with the array indices of the local maxima within the FFT array
    float* peakfftpos = malloc(sizeof(float)*BUFFER_SIZE);
    // pointer to keep track of where in the previous arrays to insert the next value
    int arrayPtr = 0;


    //sliding window over the the f
    // start at 50 to eliminate the erronious low end frequencies and stop when the end of the last window would reach the end of the buffer
    for(int i = 50; i < FFTSIZE - WINDOW_SIZE; i++){
        // variables for the maximum of the window and its array index
        float windowmax = -1000;
        int maxpos = 0;
        // iterate over the window...
        for(int j = i; j < i + WINDOW_SIZE; j++){
            // if the current magnitude is greater than the current maximum...
            if(self.fftMagnitude[j] > WINDOW_SIZE){
                // store the magnitude and array position
                windowmax = self.fftMagnitude[j];
                maxpos = j;
            }
        }
        // if the maximum is in the middle of the window, it is a local maximum
        if(maxpos == i + WINDOW_SIZE/2){
            // and thus save it and its index to the maxima array and increment the pointer
            peakfft[arrayPtr] = windowmax;
            peakfftpos[arrayPtr] = maxpos;
            arrayPtr += 1;
        }
    }
    
    // create variables to be used to find the two absolute maxima
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
    
    // free up local arrays to prevent memory leak
    free(peakfft);
    free(peakfftpos);
    
    // calculate the the actual frequencies of the maximum FFTs
    int maxFreq1 = (int)(maxActualPos1 * DF);
    int maxFreq2 = (int)(maxActualPos2 * DF);
    
    int* maxFreqs = malloc(sizeof(int)*2);
    maxFreqs[0] = maxFreq1;
    maxFreqs[1] = maxFreq2;
    
    return maxFreqs;

}

-(void)pauseAudioManager{
    [self.audioManager pause];
    [self.audioManager setOutputBlock:nil];
    [self.audioManager setInputBlock:nil];
}

@end

