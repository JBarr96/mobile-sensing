//
//  GestureAnalyzer.h
//  AudioLab
//
//  Created by Remus Tumac on 10/6/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GestureAnalyzer : NSObject
-(int)getGesture:(float)frequency;
-(void)pauseAudioManager;
@property (nonatomic) float* fftMagnitude;
@end
