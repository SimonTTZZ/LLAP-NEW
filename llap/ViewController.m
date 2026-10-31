//
//  ViewController.m
//  llap
//
//  Created by LLAP on 2016.
//  Copyright © 2016 Nanjing University. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:0.02 green:0.04 blue:0.08 alpha:1.0];

    self.audioController = [[AudioController alloc] init];
    self.isRunning = NO;

    [self setupPulseView];
    [self setupControls];
    [self setupAudioSession];
}

- (void)setupPulseView {
    CGFloat size = MIN(self.view.bounds.size.width, self.view.bounds.size.height) - 60;
    CGFloat x = (self.view.bounds.size.width - size) / 2.0;
    CGFloat y = 80;

    self.pulseView = [[LLAPPulseView alloc] initWithFrame:CGRectMake(x, y, size, size)];
    self.pulseView.maxDistanceMM = 500.0;
    [self.view addSubview:self.pulseView];
}

- (void)setupControls {
    CGFloat centerX = self.view.bounds.size.width / 2.0;
    CGFloat bottomY = self.view.bounds.size.height - 100;

    self.distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, bottomY - 50, self.view.bounds.size.width, 30)];
    self.distanceLabel.textAlignment = NSTextAlignmentCenter;
    self.distanceLabel.textColor = [UIColor colorWithRed:0.3 green:0.9 blue:1.0 alpha:1.0];
    self.distanceLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightMedium];
    self.distanceLabel.text = @"0.0 mm";
    [self.view addSubview:self.distanceLabel];

    self.toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.toggleButton.frame = CGRectMake(centerX - 70, bottomY, 140, 44);
    self.toggleButton.layer.cornerRadius = 22;
    self.toggleButton.layer.borderWidth = 1.5;
    self.toggleButton.layer.borderColor = [UIColor colorWithRed:0.3 green:0.9 blue:1.0 alpha:0.6].CGColor;
    self.toggleButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [self.toggleButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.toggleButton setTitleColor:[UIColor colorWithRed:0.3 green:0.9 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [self.toggleButton addTarget:self action:@selector(toggleTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.toggleButton];
}

- (void)setupAudioSession {
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
             withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionMixWithOthers
                   error:&error];
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"Audio session setup error: %@", error);
    }
}

- (void)toggleTapped:(UIButton *)sender {
    if (self.isRunning) {
        [self stopTracking];
    } else {
        [self startTracking];
    }
}

- (void)startTracking {
    OSStatus status = [self.audioController startIOUnit];
    if (status == noErr) {
        [self.audioController playMySound];
        self.isRunning = YES;
        self.pulseView.isRunning = YES;
        [self.toggleButton setTitle:@"Stop" forState:UIControlStateNormal];

        self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                            target:self
                                                          selector:@selector(updateDistance)
                                                          userInfo:nil
                                                           repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.updateTimer forMode:NSRunLoopCommonModes];
    } else {
        NSLog(@"Failed to start audio unit, status: %d", (int)status);
    }
}

- (void)stopTracking {
    [self.updateTimer invalidate];
    self.updateTimer = nil;

    [self.audioController stopMySound];
    [self.audioController stopIOUnit];

    self.isRunning = NO;
    self.pulseView.isRunning = NO;
    [self.toggleButton setTitle:@"Start" forState:UIControlStateNormal];
}

- (void)updateDistance {
    Float32 distance = self.audioController.audiodistance;
    CGFloat distanceMM = distance * 1000.0;
    [self.pulseView setDistanceMM:distanceMM animated:YES];
    self.distanceLabel.text = [NSString stringWithFormat:@"%.1f mm", distanceMM];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isRunning) {
        [self stopTracking];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
