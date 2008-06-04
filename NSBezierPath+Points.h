//
//  NSBezierPath+Points.h
//  RoundRect
//
//  Created by  Sven on 24.05.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSBezierPath (ESPoints)  

- (void) drawPointsAndHandles;
- (void) drawPoint: (NSPoint) pt;
- (void) drawPoint: (NSPoint) pt inColor: (NSColor*) pointColor;
- (void) drawHandlePoint: (NSPoint) pt;
- (void) drawHandlePoint: (NSPoint) pt inColor: (NSColor*) pointColor;
- (void) drawPointsInColor: (NSColor*) pointColor withHandlesInColor: (NSColor *) handleColor;
- (NSPoint) drawPathElement:(int) n withPreviousPoint: (NSPoint) previous;
- (NSPoint) drawPathElement:(int) n  withPreviousPoint: (NSPoint) previous inColor: (NSColor*) pointColor withHandlesInColor: (NSColor*) handleColor;
@end
