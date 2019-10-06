//
//  ViewController.h
//  AudioLab
//
//  Created by Eric Larson on 8/24/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface GraphViewController : GLKViewController
@property (weak, nonatomic) IBOutlet UILabel *MaxFreq1Label;
@property (weak, nonatomic) IBOutlet UILabel *MaxFreq2Label;
@end

