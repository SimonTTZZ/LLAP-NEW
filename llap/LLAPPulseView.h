//
//  LLAPPulseView.h
//  llap
//
//  Created by LLAP Vis on 2026/10/31.
//  Copyright © 2016 Nanjing University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LLAPPulseView : UIView

@property (nonatomic, assign) CGFloat distanceMM;
@property (nonatomic, assign) CGFloat maxDistanceMM;
@property (nonatomic, assign) BOOL isRunning;

- (void)setDistanceMM:(CGFloat)distanceMM animated:(BOOL)animated;

@end
