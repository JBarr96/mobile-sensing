//
//  MaxCalculator.h
//  AudioLab
//
//  Created by Johnathan Barr on 10/1/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

@interface MaxCalculator: NSObject
- (id)init;
- (int*) calcMax;
-(float*)getArrayData;
-(float*)getFFTData;
-(void)pauseAudioManager;
@property (nonatomic) float* arrayData;
@property (nonatomic) float* fftMagnitude;
@end
