//
//  MaxCalculator.h
//  AudioLab
//
//  Created by Johnathan Barr on 10/1/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import "GraphViewController.h"

@interface MaxCalculator: NSObject
- (id)initWithView: (GraphViewController*)view;
- (void) calcMax;
@property (nonatomic) float* arrayData;
@property (nonatomic) float* fftMagnitude;
@end
