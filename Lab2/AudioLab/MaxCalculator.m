//
//  MaxCalculator.m
//  AudioLab
//
//  Created by Johnathan Barr on 10/1/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MaxCalculator.h"

#define BUFFER_SIZE 16384
#define FFTSIZE BUFFER_SIZE/2
#define SAMPLING_RATE 44100.0
#define DF (float)SAMPLING_RATE/(float)BUFFER_SIZE
#define WINDOW_SIZE 5

@interface MaxCalculator ()

@end

@implementation MaxCalculator

-(int*)calcMax: (float*)fftMagnitude{
    float* peakfft = malloc(sizeof(float)*BUFFER_SIZE);
    float* peakfftpos = malloc(sizeof(float)*BUFFER_SIZE);
    int arrayPtr = 0;


    //sliding window over the the f
    for(int i = 50; i < FFTSIZE - WINDOW_SIZE; i++){
        float windowmax = -1000;
        int maxpos = 0;
        for(int j = i; j < i + WINDOW_SIZE; j++){
            if(fftMagnitude[j] > WINDOW_SIZE){
                windowmax = fftMagnitude[j];
                maxpos = j;
            }
        }
        if(maxpos == i + WINDOW_SIZE/2){
            peakfft[arrayPtr] = windowmax;
            peakfftpos[arrayPtr] = maxpos;
            arrayPtr += 1;
        }
    }
    
    // create variables to be used to find the two maxima
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
    int maxFreq1 = (int)(maxActualPos1 * DF);
    int maxFreq2 = (int)(maxActualPos2 * DF);
    
    free(peakfft);
    free(peakfftpos);
    
    int* result = malloc(sizeof(int)*2);
    result[0] = maxFreq1;
    result[1] = maxFreq2;
    
    return result;
}

@end

