//
//  ViewController.h
//  llap
//
//  Created by LLAP on 2016.
//  Copyright © 2016 Nanjing University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LLAPPulseView.h"
#import "AudioController.h"

@interface ViewController : UIViewController

@property (nonatomic, strong) LLAPPulseView *pulseView;
@property (nonatomic, strong) AudioController *audioController;
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong) UILabel *distanceLabel;
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, assign) BOOL isRunning;

@end
