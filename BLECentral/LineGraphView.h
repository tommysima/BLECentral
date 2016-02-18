//
//  LineGraphView.h
//  MindView
//
//  Created by NeuroSky on 10/13/11.
//  Copyright 2012. All rights reserved.
//

#import <UIKit/UIKit.h>

#define AVERAGE_COUNT 50

@interface LineGraphView : UIView {
    
    NSMutableArray *data;
    
    double xAxisMin;
    int xAxisMax;
    double yAxisMin;
    double yAxisMax;
    int dataRate;
    int decimate;
    
    NSLock *dataLock;
    
    int startIndex;
    
    int index;
    double scaler;
    
    NSTimer *reDrawTimer;
    NSThread *redraw;
    
    UIColor * backgroundColor;
    UIColor * lineColor;
    UIColor * cursorColor;
    bool cursorEnabled;
    
    
@private
    UIPinchGestureRecognizer * pinch;
    UITapGestureRecognizer * taptap;
    bool newData;
    int decimateCount;
    
    /* DC offset removal */
    int averageCount;
    double average;
    bool offsetRemovalEnabled;
}

- (CGPoint)point2PixelsWithXValue:(double) xValue yValue:(double) yValue;
- (void)addPoint;
- (void)addValue:(double) value;
- (void)twoFingerPinch:(UIPinchGestureRecognizer *)recognizer;
- (void)doubleTap;

@property (assign) UIColor * backgroundColor;
@property (assign) UIColor * lineColor;
@property (assign) UIColor * cursorColor;
@property bool cursorEnabled;

@end
