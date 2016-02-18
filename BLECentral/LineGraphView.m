//
//  LineGraphView.m
//  MindView
//
//  Created by NeuroSky on 10/13/11.
//  Copyright 2012. All rights reserved.
//

#import "LineGraphView.h"

@implementation LineGraphView

@synthesize backgroundColor = _backgroundColor;
@synthesize lineColor = _lineColor;
@synthesize cursorColor = _cursorColor;
@synthesize cursorEnabled = _cursorEnabled;

- (id)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }    
    return self;
}

- (void)initialize {
    
    xAxisMin = 0;    //seconds
    xAxisMax = 3;    //seconds
    yAxisMin = -2048;
    yAxisMax = 2048;
    dataRate = 512;  //Hz
    decimate = 4;
    decimateCount = 0;
    averageCount = 0;
    offsetRemovalEnabled = YES;
    
    data = [[NSMutableArray alloc] initWithCapacity:(dataRate * xAxisMax)];
    
    index = 0;
    scaler = 0.3;
    
    dataLock = [[NSLock alloc] init];
       
    redraw = [[NSThread alloc] initWithTarget:self selector:@selector(redrawThread) object:nil];
    [redraw start];
    
    if(backgroundColor == nil) {
        backgroundColor = [UIColor clearColor];
        self.backgroundColor = backgroundColor;
    }
    
    //self.backgroundColor = [UIColor clearColor];
    lineColor = [UIColor blackColor];
    cursorColor = [UIColor redColor];
    cursorEnabled = YES;
    
    pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerPinch:)];
    [self addGestureRecognizer:pinch];
    taptap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap)];
    taptap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:taptap];
}

- (void)dealloc {
    [reDrawTimer invalidate];
//    [data release];
//    [dataLock release];
//    [super dealloc];    
}

- (void)drawRect:(CGRect)clientRect {

    if(data.count > 1) {    
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path removeAllPoints];
//        [path setLineWidth:0.5];
        [path setLineWidth:1.5];
        [path moveToPoint:CGPointMake(0, clientRect.size.height/2)];
        
        for(int i = 0; i < data.count; i++) {
            
            NSNumber *tempValue = (NSNumber *)[data objectAtIndex:i]; 
            
            CGPoint tempPixel = [self point2PixelsWithXValue:i
                                                      yValue:([tempValue doubleValue] * scaler)];
            [path addLineToPoint:tempPixel];
            //NSLog(@"x x %f %d", [tempValue doubleValue], i);
        }
        
        [lineColor set]; 
        [path stroke];
        if(cursorEnabled) {
            UIBezierPath *cursor = [UIBezierPath bezierPath];
            [cursor removeAllPoints];
            //            [cursor setLineWidth:0.8];
            [cursor setLineWidth:2];
            [cursor moveToPoint:[self point2PixelsWithXValue:index yValue:yAxisMax]];
            [cursor addLineToPoint:[self point2PixelsWithXValue:index yValue:yAxisMin]];
            [cursorColor set];
            [cursor stroke];
        }
        newData = NO;
    }    
}

- (CGPoint)point2PixelsWithXValue:(double) xValue yValue:(double) yValue {
    CGPoint temp = {0, 0};
    
    temp.x = xValue * self.frame.size.width / (dataRate / decimate * xAxisMax);
    temp.y = ((yValue - yAxisMin) / (yAxisMax - yAxisMin) * self.frame.size.height);
    
    temp.y = self.bounds.size.height - temp.y;
    //NSLog(@"pixel: %f, %f", temp.x, temp.y);
    return temp;
}

-(void)addPoint{
    int f = 10;
    double x = index++ / dataRate;
    double y = sin(2 * M_PI * x * f);
    NSValue *temp = [NSValue valueWithCGPoint:CGPointMake(x,y)];
    
    [dataLock lock];
    [data addObject:temp];
    if(data.count > xAxisMax * dataRate) {
        [data removeObjectAtIndex:0];
    }
    [dataLock unlock];
}

-(void)addValue:(double) value {
    decimateCount++;
    if (decimateCount < decimate) {
        return;
    } else {
        decimateCount = 0;
    }
    if (index > dataRate / decimate * xAxisMax - 1) {
        index = 0;
    }
    
    if(offsetRemovalEnabled){
        if(averageCount < AVERAGE_COUNT) averageCount++;
        average = (average*(averageCount - 1) + value)/averageCount;
    }else {
        average = 0;
    }
    
    [dataLock lock];
    
    if(data.count < dataRate / decimate * xAxisMax) {
        [data insertObject:[NSNumber numberWithDouble:value - average] atIndex:index];
    }else {
        [data replaceObjectAtIndex:index withObject:[NSNumber numberWithDouble:value - average] ];
    }

    //NSLog(@"data count: %d", data.count);   

    index++;
    [dataLock unlock];
    newData = YES;
}

- (void)twoFingerPinch:(UIPinchGestureRecognizer *)recognizer {
    scaler += recognizer.scale - 1;
    if(scaler < 0.4)
        scaler = 0.4;
    else if (scaler > 5)
        scaler = 5;
    //NSLog(@"Pinch scale: %f", scaler);
}

- (void)doubleTap {
    scaler = 1;
}

-(void)redrawThread {
    while (true) {
        if (newData) {
            //[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
        }
        [NSThread sleepForTimeInterval:0.03];
    }
    
}

@end
