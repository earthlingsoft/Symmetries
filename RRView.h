//
//  RRView.h
//  RoundRect
//
//  Created by  Sven on 22.05.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyDocument.h" 
#import <QuartzCore/QuartzCore.h>

typedef struct {
	CGFloat r;
	CGFloat phi;
} ESPolarPoint;


@interface RRView : NSView {
	IBOutlet MyDocument * theDocument;

	NSBezierPath * path;	
	NSAffineTransform * moveToMiddle;
	NSAffineTransform * moveFromMiddle;
	
	CALayer * mouseLayer;
	CALayer * guideLayer;
	CALayer * handleLayer;
	NSString * clickedPointName;
	
	NSTrackingArea * endPointTA;
	NSTrackingArea * endHandleTA;
	NSTrackingArea * midPointTA;
	NSTrackingArea * midHandleTA;
	NSTrackingArea * widthHandleTA;
	NSTrackingArea * thickCornerHandleTA;
	
}

@property (retain) MyDocument * theDocument;
@property (retain) NSBezierPath * path;
@property (readonly) NSAffineTransform * moveToMiddle;
@property (readonly) NSAffineTransform * moveFromMiddle;
@property (retain) CALayer * mouseLayer;
@property (retain) CALayer * guideLayer;
@property (retain) CALayer * handleLayer;
@property (retain) NSString * clickedPointName;
@property (retain) NSTrackingArea * endPointTA;
@property (retain) NSTrackingArea * endHandleTA;
@property (retain) NSTrackingArea * midPointTA;
@property (retain) NSTrackingArea * midHandleTA;
@property (retain) NSTrackingArea * widthHandleTA;
@property (retain) NSTrackingArea * thickCornerHandleTA;


@property (readonly) CGFloat shapeRadius;
@property (readonly) CGFloat canvasRadius;
@property (readonly) NSPoint startPoint;
@property (readonly) NSPoint midmidPoint;
@property (readonly) NSPoint midPoint;
@property (readonly) NSPoint midHandle;
@property (readonly) NSPoint endPoint;
@property (readonly) NSPoint endHandle;
@property (readonly) NSPoint middle;
@property (readonly) NSPoint innerEndPoint;
@property (readonly) NSPoint innerMidmidPoint;
@property (readonly) BOOL useCoreAnimation;

- (NSString*) trackingAreaNameForMouseLocation;
- (void) drawHandlesForFundamentalPath;
- (void) drawGuidesForPoint:(NSString *) pointName;

- (NSBezierPath *) pathWithSize: (CGFloat) s  cornerDelta: (CGFloat) cF;

- (void) drawPoint: (NSPoint) pt;

- (ESPolarPoint) polarPointForPoint: (NSPoint) point origin:(NSPoint) origin;
- (NSPoint) pointForPolarPoint: (ESPolarPoint) polar origin:(NSPoint) origin;
@end



