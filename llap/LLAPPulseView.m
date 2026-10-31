//
//  LLAPPulseView.m
//  llap
//
//  Created by LLAP Vis on 2026/10/31.
//  Copyright © 2016 Nanjing University. All rights reserved.
//

#import "LLAPPulseView.h"

@interface LLAPPulseView ()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CFTimeInterval scanAngle;
@property (nonatomic, assign) CFTimeInterval lastTimestamp;

@end

@implementation LLAPPulseView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _maxDistanceMM = 500.0;
        _distanceMM = 0;
        _isRunning = NO;
        _scanAngle = 0;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_isRunning) {
        [self startScanAnimation];
    }
}

#pragma mark - Animation

- (void)setIsRunning:(BOOL)isRunning {
    _isRunning = isRunning;
    if (isRunning) {
        [self startScanAnimation];
    } else {
        [self stopScanAnimation];
    }
    [self setNeedsDisplay];
}

- (void)startScanAnimation {
    if (_displayLink) return;
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(scanTick:)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    _lastTimestamp = [NSDate date].timeIntervalSince1970;
}

- (void)stopScanAnimation {
    [_displayLink invalidate];
    _displayLink = nil;
}

- (void)scanTick:(CADisplayLink *)link {
    CFTimeInterval now = link.timestamp;
    CFTimeInterval delta = now - _lastTimestamp;
    _lastTimestamp = now;
    if (delta < 0 || delta > 0.1) delta = 0.016;
    _scanAngle += delta * 1.5;
    if (_scanAngle > M_PI * 2) _scanAngle -= M_PI * 2;
    [self setNeedsDisplay];
}

#pragma mark - Set Distance

- (void)setDistanceMM:(CGFloat)distanceMM {
    [self setDistanceMM:distanceMM animated:NO];
}

- (void)setDistanceMM:(CGFloat)distanceMM animated:(BOOL)animated {
    CGFloat clamped = MIN(MAX(distanceMM, 0), _maxDistanceMM);
    _distanceMM = clamped;
    [self setNeedsDisplay];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGSize size = rect.size;
    CGPoint center = CGPointMake(size.width / 2.0, size.height / 2.0);
    CGFloat maxRadius = MIN(size.width, size.height) / 2.0 - 20;

    UIColor *bgGradStart = [UIColor colorWithRed:0.05 green:0.10 blue:0.18 alpha:1.0];
    UIColor *bgGradEnd   = [UIColor colorWithRed:0.02 green:0.04 blue:0.08 alpha:1.0];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSArray *bgColors = @[(id)bgGradStart.CGColor, (id)bgGradEnd.CGColor];
    CGGradientRef bgGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)bgColors, NULL);
    CGContextDrawRadialGradient(ctx, bgGradient, center, 0, center, maxRadius + 30, 0);
    CGGradientRelease(bgGradient);

    CGContextSaveGState(ctx);
    CGContextAddArc(ctx, center.x, center.y, maxRadius, 0, M_PI * 2, YES);
    CGContextClip(ctx);

    for (int ring = 1; ring <= 5; ring++) {
        CGFloat r = maxRadius * ring / 5.0;
        UIColor *ringColor = [UIColor colorWithWhite:1.0 alpha:0.08 + ring * 0.02];
        CGContextSetStrokeColorWithColor(ctx, ringColor.CGColor);
        CGContextSetLineWidth(ctx, 1.0);
        CGContextAddArc(ctx, center.x, center.y, r, 0, M_PI * 2, NO);
        CGContextStrokePath(ctx);
    }

    for (int i = 0; i < 8; i++) {
        CGFloat angle = M_PI * 2 * i / 8.0;
        CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:1.0 alpha:0.08].CGColor);
        CGContextSetLineWidth(ctx, 1.0);
        CGContextMoveToPoint(ctx, center.x, center.y);
        CGContextAddLineToPoint(ctx,
                               center.x + cos(angle) * maxRadius,
                               center.y + sin(angle) * maxRadius);
        CGContextStrokePath(ctx);
    }

    if (_isRunning) {
        CGFloat coneAngle = M_PI / 8.0;
        UIColor *scanStart = [UIColor colorWithRed:0.2 green:0.8 blue:1.0 alpha:0.45];
        UIColor *scanEnd   = [UIColor colorWithRed:0.2 green:0.8 blue:1.0 alpha:0.0];
        NSArray *scanColors = @[(id)scanStart.CGColor, (id)scanEnd.CGColor];
        CGGradientRef scanGrad = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)scanColors, NULL);

        CGContextSaveGState(ctx);
        CGContextAddArc(ctx, center.x, center.y, maxRadius,
                        _scanAngle - coneAngle, _scanAngle + coneAngle, NO);
        CGContextAddLineToPoint(ctx, center.x, center.y);
        CGContextClosePath(ctx);
        CGContextClip(ctx);

        CGContextDrawRadialGradient(ctx, scanGrad, center, 0, center, maxRadius, 0);
        CGGradientRelease(scanGrad);

        CGContextRestoreGState(ctx);

        UIColor *lineColor = [UIColor colorWithRed:0.3 green:0.9 blue:1.0 alpha:0.85];
        CGContextSetStrokeColorWithColor(ctx, lineColor.CGColor);
        CGContextSetLineWidth(ctx, 2.0);
        CGContextMoveToPoint(ctx, center.x, center.y);
        CGContextAddLineToPoint(ctx,
                                center.x + cos(_scanAngle) * maxRadius,
                                center.y + sin(_scanAngle) * maxRadius);
        CGContextStrokePath(ctx);
    }

    CGContextRestoreGState(ctx);

    CGFloat ratio = MIN(_distanceMM / _maxDistanceMM, 1.0);
    CGFloat objRadius = maxRadius * ratio;

    if (ratio > 0.01) {
        UIColor *ringColor = [self colorForRatio:ratio];
        UIColor *ringGlow = [ringColor colorWithAlphaComponent:0.15];

        CGContextSetStrokeColorWithColor(ctx, ringGlow.CGColor);
        CGContextSetLineWidth(ctx, 12.0);
        CGContextAddArc(ctx, center.x, center.y, objRadius, 0, M_PI * 2, NO);
        CGContextStrokePath(ctx);

        CGContextSetStrokeColorWithColor(ctx, ringGlow.CGColor);
        CGContextSetLineWidth(ctx, 6.0);
        CGContextAddArc(ctx, center.x, center.y, objRadius, 0, M_PI * 2, NO);
        CGContextStrokePath(ctx);

        CGContextSetStrokeColorWithColor(ctx, ringColor.CGColor);
        CGContextSetLineWidth(ctx, 2.0);
        CGContextAddArc(ctx, center.x, center.y, objRadius, 0, M_PI * 2, NO);
        CGContextStrokePath(ctx);

        CGPoint objectPoint = CGPointMake(center.x + maxRadius * 0.65, center.y);
        UIColor *dotGlow = [ringColor colorWithAlphaComponent:0.3];
        CGContextSetFillColorWithColor(ctx, dotGlow.CGColor);
        CGContextAddArc(ctx, objectPoint.x, objectPoint.y, 14, 0, M_PI * 2, YES);
        CGContextFillPath(ctx);
        CGContextSetFillColorWithColor(ctx, ringColor.CGColor);
        CGContextAddArc(ctx, objectPoint.x, objectPoint.y, 7, 0, M_PI * 2, YES);
        CGContextFillPath(ctx);

        CGContextSetStrokeColorWithColor(ctx, [ringColor colorWithAlphaComponent:0.4].CGColor);
        CGContextSetLineWidth(ctx, 1.0);
        CGFloat dashPattern[] = {4, 4};
        CGContextSetLineDash(ctx, 0, dashPattern, 2);
        CGContextMoveToPoint(ctx, center.x, center.y);
        CGContextAddLineToPoint(ctx, objectPoint.x, objectPoint.y);
        CGContextStrokePath(ctx);
        CGContextSetLineDash(ctx, 0, NULL, 0);
    }

    UIColor *centerOuter = [UIColor colorWithRed:0.3 green:0.9 blue:1.0 alpha:0.25];
    CGContextSetFillColorWithColor(ctx, centerOuter.CGColor);
    CGContextAddArc(ctx, center.x, center.y, 18, 0, M_PI * 2, YES);
    CGContextFillPath(ctx);

    UIColor *centerInner = [UIColor colorWithRed:0.3 green:0.9 blue:1.0 alpha:1.0];
    CGContextSetFillColorWithColor(ctx, centerInner.CGColor);
    CGContextAddArc(ctx, center.x, center.y, 10, 0, M_PI * 2, YES);
    CGContextFillPath(ctx);

    UIColor *centerDot = [UIColor whiteColor];
    CGContextSetFillColorWithColor(ctx, centerDot.CGColor);
    CGContextAddArc(ctx, center.x, center.y, 4, 0, M_PI * 2, YES);
    CGContextFillPath(ctx);

    NSDictionary *innerAttrs = @{
        NSFontAttributeName: [UIFont systemFontOfSize:10 weight:UIFontWeightMedium],
        NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.35]
    };
    NSString *label0 = @"0";
    NSString *label1 = @"250";
    NSString *label2 = @"500mm";
    [label0 drawAtPoint:CGPointMake(center.x - 6, center.y + maxRadius - 18)
         withAttributes:innerAttrs];
    [label1 drawAtPoint:CGPointMake(center.x + maxRadius / 2 - 14, center.y - 8)
         withAttributes:innerAttrs];
    [label2 drawAtPoint:CGPointMake(center.x + maxRadius - 32, center.y - 8)
         withAttributes:innerAttrs];

    CGColorSpaceRelease(colorSpace);
}

- (UIColor *)colorForRatio:(CGFloat)ratio {
    if (ratio < 0.33) {
        return [UIColor colorWithRed:0.2 green:1.0 blue:0.5 alpha:1.0];
    } else if (ratio < 0.66) {
        return [UIColor colorWithRed:1.0 green:0.85 blue:0.2 alpha:1.0];
    } else {
        return [UIColor colorWithRed:1.0 green:0.35 blue:0.3 alpha:1.0];
    }
}

- (void)dealloc {
    [self stopScanAnimation];
}

@end
