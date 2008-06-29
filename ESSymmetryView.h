//
//  ESSymmetryView.h
//  Symmetry
//
//  Created by  Sven on 22.05.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "MyDocument.h"
#import "MyDocument+Animation.h"

#define ESSYMMETRYPBOARDTYPE @"ESSSymmetryPboardType"

@class MyDocument;

typedef struct {
	CGFloat r;
	CGFloat phi;
} ESPolarPoint;


@interface ESSymmetryView : NSView {
	IBOutlet MyDocument * theDocument;

	NSBezierPath * path;	
	NSAffineTransform * moveToMiddle;
	NSAffineTransform * moveFromMiddle;
	
	CALayer * mouseLayer;
	CALayer * guideLayer;
	CALayer * handleLayer;
	NSString * clickedPointName;
	NSString * previousGuidesPoint;
	
	NSTrackingArea * endPointTA;
	NSTrackingArea * endHandleTA;
	NSTrackingArea * midPointTA;
	NSTrackingArea * midHandleTA;
	NSTrackingArea * widthHandleTA;
	NSTrackingArea * thickCornerHandleTA;
	
	NSDictionary * oldDocumentValues;
	
	CALayer * introLayer;
	CALayer * demoLayer;
	NSInteger currentDemoStep;
	NSDictionary * preAnimationDocumentValues;
	NSArray * lastAnimations;

	NSArray * stringsFromFile;
}

@property (retain) MyDocument * theDocument;
@property (retain) NSBezierPath * path;
@property (readonly) NSAffineTransform * moveToMiddle;
@property (readonly) NSAffineTransform * moveFromMiddle;
@property (retain) CALayer * mouseLayer;
@property (retain) CALayer * guideLayer;
@property (retain) CALayer * handleLayer;
@property (retain) NSString * clickedPointName;
@property (retain) NSString * previousGuidesPoint;
@property (retain) NSTrackingArea * endPointTA;
@property (retain) NSTrackingArea * endHandleTA;
@property (retain) NSTrackingArea * midPointTA;
@property (retain) NSTrackingArea * midHandleTA;
@property (retain) NSTrackingArea * widthHandleTA;
@property (retain) NSTrackingArea * thickCornerHandleTA;
@property (retain) NSDictionary * oldDocumentValues;

@property (retain) CALayer * introLayer;
@property (retain) CALayer * demoLayer;
@property NSInteger currentDemoStep;
@property (retain) NSDictionary * preAnimationDocumentValues;
@property (retain) NSArray * lastAnimations;

@property (readonly) CGFloat shapeRadius;
@property (readonly) CGFloat canvasRadius;
@property (readonly) NSPoint startPoint;
@property (readonly) NSPoint otherMidPoint;
@property (readonly) NSPoint midmidPoint;
@property (readonly) NSPoint midPoint;
@property (readonly) NSPoint midHandle;
@property (readonly) NSPoint endPoint;
@property (readonly) NSPoint endHandle;
@property (readonly) NSPoint middle;
@property (readonly) NSPoint innerEndPoint;
@property (readonly) NSPoint innerMidmidPoint;
@property (readonly) BOOL useCoreAnimation;
@property (readonly) NSColor * guideColor;


- (NSString*) trackingAreaNameForMouseLocation;
- (void) drawHandlesForFundamentalPath;
- (void) drawGuidesForPoint:(NSString *) pointName;

- (void) drawPoint: (NSPoint) pt;
- (void) updateCursor;

- (void) handleDragForEvent: (NSEvent*) event;

- (BOOL) point: (NSPoint) point inRect: (NSRect) rect;

- (ESPolarPoint) polarPointForPoint: (NSPoint) point origin:(NSPoint) origin;
- (NSPoint) pointForPolarPoint: (ESPolarPoint) polar origin:(NSPoint) origin;
@end



