//
//  RRView.m
//  RoundRect
//
//  Created by  Sven on 22.05.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "RRView.h"
#import "NSBezierPath+Points.h"
#import "NSImage-Extras.h"


#define MAXCORNERNUMBER 37
#define HANDLELINEWIDTH 1.5
#define HANDLESIZE 4.0
#define POINTSIZE 6.0
#define LENGTH(point) sqrt(point.x*point.x + point.y*point.y)


@implementation RRView

@synthesize theDocument;
@synthesize path;
@synthesize mouseLayer;
@synthesize guideLayer;
@synthesize handleLayer;
@synthesize clickedPointName;
@synthesize endPointTA;
@synthesize endHandleTA;
@synthesize midPointTA;
@synthesize midHandleTA;
@synthesize widthHandleTA;
@synthesize thickCornerHandleTA;


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}



- (void) frameChanged: (NSNotification*) notification {
	NSLog(@"framechange");
	self.guideLayer.bounds = NSRectToCGRect(self.bounds);
	self.handleLayer.bounds = NSRectToCGRect(self.bounds);

	[self setNeedsDisplay:YES];
}



- (void) awakeFromNib {
	[self setPostsBoundsChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:NSViewFrameDidChangeNotification object:self];
	[self frameChanged: nil];
	
	// We Love Core Animation:
	// get main layer
	self.wantsLayer = YES;
	CALayer* mainLayer = self.layer;
	mainLayer.name = @"mainLayer";
	mainLayer.delegate = self;
	[mainLayer setNeedsDisplay];

	// set up layer for extra drawing during interaction
	CALayer * newLayer = [CALayer layer];
	newLayer.name = @"mouseLayer";
	[mainLayer addSublayer: newLayer];
	self.mouseLayer = newLayer;
	
	// set up layer to display interaction guides for the user
	newLayer = [CALayer layer];
	newLayer.name = @"guideLayer";
	newLayer.opacity = 1.0;
	newLayer.anchorPoint = CGPointMake(0.0, 0.0);
	[self.mouseLayer addSublayer: newLayer];
	self.guideLayer = newLayer;
	
	// set up layer for handles
	newLayer = [CALayer layer];
	newLayer.name = @"handleLayer";
	newLayer.opacity = 1.0;
	newLayer.anchorPoint = CGPointMake(0.0, 0.0);
	[self.mouseLayer addSublayer: newLayer];
	self.handleLayer = newLayer;
	
	// set up sizing stuff
	[self frameChanged: nil];
	[self.window setAcceptsMouseMovedEvents:YES];
}	


/*
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"path"]) {
		NSPoint points[3];
		int i = 1;
		NSBezierPath * compoundPath = [self valueForKey:keyPath];
		[compoundPath elementAtIndex:i associatedPoints:points];
		start = points[0];
		[compoundPath elementAtIndex:++i associatedPoints:points];
		startTangent = points[0];
		mid1TangentIn = points[1];
		mid1 = points[2];
		[compoundPath elementAtIndex:++i associatedPoints:points];	
		mid1TangentOut = points[0];
		mid2TangentIn = points[1];
		mid2 = points[2];
		[compoundPath elementAtIndex:++i associatedPoints:points];
		mid2TangentOut = points[0];
		endTangent = points[1];
		end = points[2];
	}
}
*/



#pragma mark MOUSE HANDLING

- (void)scrollWheel:(NSEvent *)theEvent {
	theDocument.size = MAX(MIN(theDocument.size + [theEvent deltaY]/100.0, 1.0), 0.0);
	theDocument.cornerFraction = MAX(MIN(theDocument.cornerFraction - [theEvent deltaX]/100.0, 1.0), -1.0);
	[self setNeedsDisplay: YES];
}


- (void) mouseEntered:(NSEvent*) event {
	NSString * pointName = [(NSDictionary*)[event userData] objectForKey: @"name"];
	NSLog([pointName stringByAppendingString: @" - mouseEntered"]);
	[[NSCursor openHandCursor] push];
	
/*
	// show point marker - immediately
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:0.0f]
					 forKey:kCATransactionAnimationDuration];
	self.pointHighlightLayer.position = point;
	self.pointHighlightLayer.opacity = 0.5;
	[CATransaction commit];
	self.pointHighlightLayer.opacity = 0.8;
*/

	[self setNeedsDisplay:YES];
}



- (void) mouseExited:(NSEvent*) event {
	NSString * pointName = [(NSDictionary*)[event userData] objectForKey: @"name"];
	NSLog([pointName stringByAppendingString: @" - mouseExited"]);
	
	self.guideLayer.opacity = 0.0;
	[NSCursor pop];
}

/*
 - (void)cursorUpdate:(NSEvent *)event {
 NSString * TAName = [(NSDictionary*)[event userData] objectForKey:@"name"];
 return;
 NSLog(@"cursorUpdate");
 if ([TAName isEqual:@"endPoint"] || [TAName isEqual:@"endHandle"] || [TAName isEqual:@"midPoint"] || [TAName isEqual:@"midHandle"]) {
 [[NSCursor openHandCursor] set];
 }
 else {
 [[NSCursor arrowCursor] set];
 }
 }
 */


- (void) mouseMoved: (NSEvent*) event {
	NSString * TAName = [self trackingAreaNameForMouseLocation];
	NSLog([NSString stringWithFormat:@"mouseMoved: %@", (TAName) ? (TAName) : (@"")]);
	if (TAName) {
		[self setNeedsDisplay:YES];
	}
	else {
		self.guideLayer.opacity = 0.0;
	}
}


- (void) mouseDown: (NSEvent*) event {
	NSString * TAName = [self trackingAreaNameForMouseLocation];
		self.clickedPointName = TAName;
		NSLog([@"Clicked on " stringByAppendingString:(TAName) ? (TAName) : (@"")]);
		[[NSCursor closedHandCursor] push];
}


- (void) mouseUp: (NSEvent*) event {
	if (![self.clickedPointName isEqualToString:@""]) {
		[NSCursor pop];
	}
	self.clickedPointName = nil;
	// [self drawGuidesForPoint:[self trackingAreaNameForMouseLocation]];
	//	[set setNeedsDisplay:YES];
}




- (void) mouseDragged: (NSEvent*) event {
	if (self.clickedPointName != nil) {
		// we want to follow this click
		NSString * TAName = self.clickedPointName;
		
		NSPoint realMouseLocation = [self convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];
		NSPoint mouseLocation = [self.moveFromMiddle transformPoint:realMouseLocation];
		
		if ([TAName isEqualToString:@"endPoint"]) {
			CGFloat length = LENGTH(mouseLocation) / self.canvasRadius;
			theDocument.size = MIN(length, 1.0);
			CGFloat safeXValue = MAX(MIN(mouseLocation.x / self.shapeRadius , 1.0), -1.0);
			theDocument.cornerCount = MIN(round( 2 * pi / acos(safeXValue)), MAXCORNERNUMBER);
		}
		else if ([TAName isEqualToString:@"endHandle"]) {
			ESPolarPoint polar = [self polarPointForPoint: realMouseLocation origin: self.endPoint];
			theDocument.straightTangentLength = MAX(MIN(polar.r / self.shapeRadius, 1.0), 0.0);
			theDocument.straightTangentDirection = polar.phi + 2.0 * pi / theDocument.cornerCount - pi/2.0;
		}
		else if ([TAName isEqualToString:@"midPoint"]) {
			NSPoint midTangent = NSMakePoint(self.endPoint.x - self.startPoint.x, self.endPoint.y - self.startPoint.y);
			NSAffineTransform * rotator = [NSAffineTransform transform];
			[rotator rotateByRadians: -pi/theDocument.cornerCount];
			NSPoint rotatedMouse = [rotator transformPoint:mouseLocation];
			theDocument.cornerFraction = MAX(MIN(rotatedMouse.x / self.shapeRadius / sqrt(2.0), 1.0), -1.0);
			theDocument.midPointsDistance = MAX(MIN(rotatedMouse.y / LENGTH(midTangent), 1.0),-1.0);
		}
		else if ([TAName isEqualToString:@"midHandle"]) {
			ESPolarPoint polar = [self polarPointForPoint: realMouseLocation origin: self.midPoint];
			
			NSPoint startToEndVector = NSMakePoint(self.endPoint.x - self.startPoint.x , self.endPoint.y - self.startPoint.y);
			CGFloat startToEndDistance = LENGTH(startToEndVector);
			
			theDocument.diagonalTangentLength = MAX(MIN(polar.r / startToEndDistance, 1.0), 0.0);
			theDocument.diagonalTangentDirection = + polar.phi + pi / theDocument.cornerCount - pi * 0.5;
		}
		else if ([TAName isEqualToString:@"widthHandle"]) {
			ESPolarPoint endPolar = [self polarPointForPoint:self.endPoint origin:self.middle];
			ESPolarPoint mousePolar = [self polarPointForPoint:realMouseLocation origin:self.middle];
			theDocument.thickness = MAX(MIN(1.0 - mousePolar.r / endPolar.r, 1.0), 0.0);
		}
		else if ([TAName isEqualToString:@"thickCornerHandle"]) {
			ESPolarPoint polar = [self polarPointForPoint:realMouseLocation	origin:self.middle];
			theDocument.thickenedCorner = MAX(MIN(2.0 * (1.0 - polar.r / (theDocument.cornerFraction * self.shapeRadius * sqrt(2.0))), 1.0), 0.0);
			NSLog(@"%f", theDocument.thickenedCorner);
		}
		else {
			return;
		}
		[self setNeedsDisplay: YES];
		// [[NSGarbageCollector defaultCollector] collectIfNeeded]; // doesn't seem to change RAM usage
	}
}





#pragma mark DRAWING

- (void) drawGuidesForPoint:(NSString *) pointName {
	// NSLog([NSString stringWithFormat:@"drawGuidesForPoint %@", pointName]);

	NSString * thePointName = pointName;
	if (!pointName) {
		thePointName = [self trackingAreaNameForMouseLocation];
		// NSLog([NSString stringWithFormat:@"... corrected to %@", thePointName]);
	}	
	
	if (thePointName) {
		NSPoint origin = NSMakePoint(0.0, 0.0);
		CGFloat guideLineWidth = 8.0;
		NSColor * guideColor = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:0.8];
		NSBezierPath * bP = [NSBezierPath bezierPath];
		bP.lineCapStyle = NSRoundLineCapStyle;
		bP.lineWidth = guideLineWidth;

		NSImage * image;
		if (self.useCoreAnimation) {
			// we want Core Animation - create image and draw there
			image = [[NSImage alloc] initWithSize:self.frame.size];
			[image lockFocus];
		}

		[guideColor set];

		if ([thePointName isEqualToString:@"endPoint"]) {
			// draw circle segment from 2pi/71 to pi
			CGFloat radius = LENGTH([self.moveFromMiddle transformPoint:self.endPoint]);
			[bP appendBezierPathWithArcWithCenter:origin radius:radius startAngle:360.0 / MAXCORNERNUMBER endAngle:180.0];
			// draw vertical line
			[bP moveToPoint: origin];
			[bP lineToPoint: NSMakePoint(self.canvasRadius * cos(2.0 * pi / theDocument.cornerCount) , self.canvasRadius * sin(2.0 * pi / theDocument.cornerCount))];
			[bP transformUsingAffineTransform: self.moveToMiddle];
			[bP stroke];
		
			for (int i = 2; i <= MAXCORNERNUMBER; i++) {
				bP = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(radius * cos(2.0 * pi / i) - guideLineWidth, radius * sin(2.0 * pi / i) - guideLineWidth, 2.0 * guideLineWidth, 2.0 * guideLineWidth)];
				[bP transformUsingAffineTransform: self.moveToMiddle];
				[bP fill];
			}
		}
		else if ([thePointName isEqualToString:@"endHandle"]) {
			// line from endPoint through endHandle
			ESPolarPoint polar = [self polarPointForPoint:self.endHandle origin:self.endPoint];
			[bP moveToPoint:self.endPoint];
			[bP lineToPoint:NSMakePoint((self.endHandle.x - self.endPoint.x) / polar.r * self.shapeRadius + self.endPoint.x, (self.endHandle.y - self.endPoint.y) / polar.r * self.shapeRadius + self.endPoint.y )];

			// circle around endPoint through endHandle
			CGFloat distance = LENGTH(NSMakePoint(self.endPoint.x - self.endHandle.x, self.endPoint.y - self.endHandle.y));
			[bP appendBezierPathWithOvalInRect:NSMakeRect(self.endPoint.x - distance, self.endPoint.y - distance, 2.0* distance, 2.0 * distance)];

			// draw
			[bP stroke];
		}
		else if ([thePointName isEqualToString:@"midPoint"]) {
			// line through midPoint and midmidPoint
			ESPolarPoint midmidMaximumPolar;
			midmidMaximumPolar.phi =  pi / (theDocument.cornerCount);
			midmidMaximumPolar.r = self.shapeRadius * sqrt(2.0);
			NSPoint midmidMaximumPoint = [self pointForPolarPoint:midmidMaximumPolar origin:self.middle];

			// ESPolarPoint startEndPolar = [self polarPointForPoint:self.endPoint origin:self.startPoint];
			NSPoint midTangent = NSMakePoint((self.endPoint.x - self.startPoint.x), 
											 (self.endPoint.y - self.startPoint.y) );

			// line for setting midPointsDistance
			NSAffineTransform * at = [NSAffineTransform transform];
			[at rotateByRadians:-midmidMaximumPolar.phi];
			[at prependTransform:self.moveFromMiddle];
			NSPoint mPR = [at transformPoint:self.midPoint];
			NSPoint mmmPR = [at transformPoint:midmidMaximumPoint];
			NSPoint lineBeginR = NSMakePoint(mPR.x, LENGTH(midTangent));
			NSPoint lineEndR = NSMakePoint(mPR.x, -LENGTH(midTangent));
			[at invert];
			NSPoint lineBegin = [at transformPoint:lineBeginR];
			NSPoint lineEnd = [at transformPoint:lineEndR];
			[bP moveToPoint:lineBegin];
			[bP lineToPoint:lineEnd];
			
			
			// line parallel to -midmidmaximumpoint<->midmidmaximumpoint
			at = [NSAffineTransform transform];
			[at rotateByRadians:midmidMaximumPolar.phi];
			[at translateXBy:0.0 yBy:LENGTH(midTangent) * self.theDocument.midPointsDistance];
			[at appendTransform:self.moveToMiddle];
			NSPoint line2Begin = [at transformPoint:mmmPR];
			NSAffineTransform * at2 = [NSAffineTransform transform];
			[at2 scaleXBy:-1.0 yBy:1.0];
			[at prependTransform: at2];
			NSPoint line2End = [at transformPoint:mmmPR];
			
			[bP moveToPoint:line2Begin];
			[bP lineToPoint:line2End];
			
/*			NSBezierPath * bP2 = [NSBezierPath bezierPath];
			// auxiliary line from origin to hint at the underlying symmetry
			[bP2 moveToPoint: middle];
			[bP2 lineToPoint: midmidMaximumPoint];
			bP2.lineWidth = guideLineWidth;
			bP2.lineCapStyle = NSRoundLineCapStyle;

			[[NSColor lightGrayColor] set];
			[bP2 stroke];
 */
			[guideColor set];
			[bP stroke];
		}
		else if ([thePointName isEqualToString:@"midHandle"]) {
			// line from -endHandle through endPoint to endHandle
			ESPolarPoint polar = [self polarPointForPoint:self.midHandle origin:self.midPoint];
			NSPoint startToEndVector = NSMakePoint(self.endPoint.x - self.startPoint.x , self.endPoint.y - self.startPoint.y);
			CGFloat startToEndDistance = LENGTH(startToEndVector);
			
			polar.r = startToEndDistance;
			polar.phi = -polar.phi;
			NSPoint lineStart = [self pointForPolarPoint:polar origin:self.midPoint];
			polar.phi = pi + polar.phi;
			NSPoint lineEnd = [self pointForPolarPoint:polar origin:self.midPoint];
			
			CGFloat distance = LENGTH(NSMakePoint(self.midPoint.x - self.midHandle.x, self.midPoint.y - self.midHandle.y));
			if (distance == 0.0) distance = .00000000000001;

			bP = [NSBezierPath bezierPath];
			[bP moveToPoint: lineStart];
			[bP lineToPoint: lineEnd];
			
			// circle around midPoint through midHandle
			[bP appendBezierPathWithOvalInRect:NSMakeRect(self.midPoint.x - distance, self.midPoint.y - distance, 2.0* distance, 2.0 * distance)];
			
			// draw
			bP.lineWidth = guideLineWidth;
			bP.lineCapStyle = NSRoundLineCapStyle;
			[bP stroke];
		}
		else if ([thePointName isEqualToString:@"widthHandle"]) {
			// draw line from endPoint to the middle
			bP = [NSBezierPath bezierPath];
			[bP moveToPoint:self.middle];
			[bP lineToPoint: self.endPoint];
			bP.lineWidth = guideLineWidth;
			bP.lineCapStyle = NSRoundLineCapStyle;
			[bP stroke];
		}
		else if ([thePointName isEqualToString:@"thickCornerHandle"]) {
			// draw line from midPoint to innerMiddle						
			ESPolarPoint polar;
			polar.phi = pi / theDocument.cornerCount;
			polar.r = theDocument.cornerFraction * self.shapeRadius * sqrt(2.0);
			NSPoint endPoint = [self pointForPolarPoint:polar origin:self.middle];
			NSPoint startPoint = NSMakePoint((endPoint.x + self.middle.x) / 2.0,
											 (endPoint.y + self.middle.y) / 2.0);
			
			bP = [NSBezierPath bezierPath];
			[bP moveToPoint:startPoint];
			[bP lineToPoint: endPoint];
			bP.lineWidth = guideLineWidth;
			bP.lineCapStyle = NSRoundLineCapStyle;
			[bP stroke];
		}
		
		
		
		if (self.useCoreAnimation) {
			[image unlockFocus];
			CGImageRef imageRef = [image cgImage];
			[CATransaction begin];
			[CATransaction setValue:[NSNumber numberWithFloat:0.0f] forKey:kCATransactionAnimationDuration];
			self.guideLayer.contents = (id) imageRef;
			self.guideLayer.opacity = 1.0;
			[CATransaction commit];
			CGImageRelease(imageRef);
		}

	 }
	else {
		// pointName is nil -> hide
		if (self.useCoreAnimation) {
			self.guideLayer.opacity =  0.0;
		}
	}
}


/* 
 Draws handles for the fundamental area of the path and sets up its tracking areas.
*/
- (void) drawHandlesForFundamentalPath {
	NSColor * pointColor = [NSColor redColor];
	NSColor * handleColor = [NSColor greenColor];
	[NSBezierPath setDefaultLineWidth:HANDLELINEWIDTH];
	// NSColor * irrelevantColor = [NSColor lightGrayColor];
	
	// Tracking area setup
	[self removeTrackingArea:self.midHandleTA];
	[self removeTrackingArea:self.midPointTA];
	[self removeTrackingArea:self.endHandleTA];
	[self removeTrackingArea:self.endPointTA]; 
	[self removeTrackingArea:self.widthHandleTA]; 
	[self removeTrackingArea:self.thickCornerHandleTA]; 
	NSTrackingAreaOptions TAoptions = (NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved|NSTrackingActiveInActiveApp|NSTrackingEnabledDuringMouseDrag);


	NSImage * image;
	if (self.useCoreAnimation) {
		image = [[NSImage alloc] initWithSize:self.frame.size];
		[image lockFocus];
	}
		
	// Handles first...
	[handleColor set];
	[NSBezierPath strokeLineFromPoint:self.endPoint toPoint:self.endHandle];
	[NSBezierPath strokeLineFromPoint:self.midPoint toPoint:self.midHandle];
	
	// ... handle control points next...
	NSRect rect = NSMakeRect(self.endHandle.x - HANDLESIZE * 0.5, self.endHandle.y - HANDLESIZE * 0.5, 
							 HANDLESIZE, HANDLESIZE);
	NSBezierPath * bP = [NSBezierPath bezierPathWithOvalInRect:rect];
	self.endHandleTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"endHandle" forKey:@"name"]];
	[self addTrackingArea:self.endHandleTA];
	
	rect = NSMakeRect(self.midHandle.x - HANDLESIZE * 0.5, self.midHandle.y - HANDLESIZE * 0.5, 
					  HANDLESIZE, HANDLESIZE);
	[bP appendBezierPathWithOvalInRect:rect];
	self.midHandleTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"midHandle" forKey:@"name"]];	
	[self addTrackingArea:self.midHandleTA];
	
	[bP fill];
	
	// ... anchor points last
	bP = [NSBezierPath bezierPath];
	[pointColor set];
	// a rotated square for the mid point
	CGFloat pSize = POINTSIZE * sqrt(2);
	[bP moveToPoint:NSMakePoint(self.midPoint.x + 0.5 * pSize, self.midPoint.y)];
	[bP lineToPoint:NSMakePoint(self.midPoint.x, self.midPoint.y + 0.5 * pSize)];
	[bP lineToPoint:NSMakePoint(self.midPoint.x - 0.5 * pSize, self.midPoint.y)];
	[bP lineToPoint:NSMakePoint(self.midPoint.x, self.midPoint.y - 0.5 * pSize)];
	[bP closePath];
	rect = [bP bounds];
	self.midPointTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"midPoint" forKey:@"name"]];
	[self addTrackingArea:self.midPointTA];
	
	// a straight square for the end point
	rect = NSMakeRect(self.endPoint.x - POINTSIZE * 0.5, self.endPoint.y - POINTSIZE * 0.5, POINTSIZE, POINTSIZE);
	[bP appendBezierPathWithRect:rect];
	self.endPointTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"endPoint" forKey:@"name"]];
	[self addTrackingArea:self.endPointTA];
	[bP fill];


	// draw handles for thickness and thickened corner
	CGFloat lineHandleWidth = 12.0;
	CGFloat lineHandleThickness = 6.0;
	CGFloat phi = 0.5 * pi  + 2.0 * pi / self.theDocument.cornerCount;
	NSPoint lineStart = NSMakePoint(self.innerEndPoint.x - cos(phi) * lineHandleWidth,
									self.innerEndPoint.y - sin(phi) * lineHandleWidth);
	NSPoint lineEnd = NSMakePoint(self.innerEndPoint.x + cos(phi) * lineHandleWidth,
								  self.innerEndPoint.y + sin(phi) * lineHandleWidth);
	
	bP = [NSBezierPath bezierPath];
	[bP moveToPoint:lineStart];
	[bP lineToPoint:lineEnd];
	self.widthHandleTA = [[NSTrackingArea alloc] initWithRect:[bP bounds] options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"widthHandle" forKey:@"name"]];
	[self addTrackingArea:self.widthHandleTA];
	
	
	phi = 0.5 * pi + pi / self.theDocument.cornerCount;
	NSPoint middleMidmidPoint = NSMakePoint((self.innerMidmidPoint.x + self.midmidPoint.x) / 2.0,
											(self.innerMidmidPoint.y + self.midmidPoint.y) / 2.0);
	lineStart = NSMakePoint(middleMidmidPoint.x - cos(phi) * lineHandleWidth,
							middleMidmidPoint.y - sin(phi) * lineHandleWidth);
	lineEnd = NSMakePoint(middleMidmidPoint.x + cos(phi) * lineHandleWidth,
						  middleMidmidPoint.y + sin(phi) * lineHandleWidth);

	NSBezierPath * bP2 = [NSBezierPath bezierPath];
	[bP2 moveToPoint:lineStart];
	[bP2 lineToPoint:lineEnd];
	self.thickCornerHandleTA = [[NSTrackingArea alloc] initWithRect:[bP2 bounds] options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"thickCornerHandle" forKey:@"name"]];
	[self addTrackingArea:self.thickCornerHandleTA];
	
	
	[bP appendBezierPath:bP2];
	bP.lineCapStyle = NSRoundLineCapStyle;
	bP.lineWidth = lineHandleThickness;
	[handleColor set];
	[bP stroke];
	
	
	
	if (self.useCoreAnimation) {
		[image unlockFocus];
		// put into layer	
		CGImageRef imageRef = [image cgImage];
		[CATransaction begin];
		[CATransaction setValue:[NSNumber numberWithFloat:0.0f] forKey:kCATransactionAnimationDuration];
		self.handleLayer.contents = (id) imageRef;
		[CATransaction commit];
		CGImageRelease(imageRef);	
	}
}



- (void)drawRect:(NSRect)rect {
	NSLog(@"-drawRect:");
	// outer and inner path
	[[NSColor blackColor] set];
	NSBezierPath * path1 = [self pathWithSize: self.shapeRadius cornerDelta: 0.0];	
	NSBezierPath * path2 = [self pathWithSize: self.shapeRadius * (1-theDocument.thickness) 
								  cornerDelta: theDocument.thickenedCorner];
	
	// compound path
	[path1 appendBezierPath:[path2 bezierPathByReversingPath]];
	[path1 transformUsingAffineTransform: self.moveToMiddle];
	[self setValue: path1 forKey:@"path"];
	
	// draw
	[theDocument.backgroundColor set];
	[NSBezierPath fillRect:self.bounds];
	[theDocument.fillColor set];
	[path1 fill];
	[theDocument.strokeColor set];
	[path1 setLineWidth: theDocument.strokeThickness];
	[path1 stroke];
		
	// draw handles and guides
	if (theDocument.showHandles != 0) {
		self.handleLayer.opacity = 1.0;
		[self drawGuidesForPoint:self.clickedPointName];
		if (theDocument.showHandles == 2) {
			[path1 drawPointsInColor:[NSColor grayColor] withHandlesInColor:[NSColor grayColor]];
		}
		[self drawHandlesForFundamentalPath];
	}
	else {
		self.handleLayer.opacity = 0.0;
	}
}


- (void) drawPoint: (NSPoint) pt {
	[[NSColor orangeColor] set];
	NSRect myRect = NSMakeRect(pt.x - 2.0, pt.y -2.0, 4.0, 4.0);
	[NSBezierPath fillRect:myRect];
}


/*
 
 - (NSBezierPath *) pathWithSize: (CGFloat) s cornerCount:(NSUInteger) corners cornerFraction: (CGFloat) cF straightTangentLength:(CGFloat) sTL diagonalTangentLength: (CGFloat) dTL diagonalTangentDirection: (CGFloat) dTD {
 
 CGFloat phi = 2.0 * pi / corners;
 CGFloat halfPhi = pi / corners;
 CGFloat sinPhi = sin(phi);
 CGFloat cosPhi = cos(phi);	
 CGFloat sinHalfPhi = sin(halfPhi);
 CGFloat cosHalfPhi = cos(halfPhi);
 
 NSPoint startPoint = NSMakePoint(s, 0.0);
 NSPoint midPoint = NSMakePoint(cosHalfPhi * cF * s, 
 sinHalfPhi * cF * s);
 NSPoint endPoint = NSMakePoint(cosPhi * s, 
 sinPhi * s);
 
 NSPoint startHandle = NSMakePoint(startPoint.x, 
 sinPhi * s * sTL);
 NSPoint midTangentDirection = NSMakePoint((endPoint.x - startPoint.x) * dTL, 
 (endPoint.y - startPoint.y) * dTL );
 NSAffineTransform * rotateMidHandle = [NSAffineTransform transform];
 [rotateMidHandle rotateByRadians: pi * dTD];
 NSPoint midTangentDirectionIn = [rotateMidHandle transformPoint:midTangentDirection];
 [rotateMidHandle invert];
 NSPoint midTangentDirectionOut = [rotateMidHandle transformPoint:midTangentDirection];
 NSPoint midHandleIn = NSMakePoint(-midTangentDirectionIn.x * dTL * sinPhi + midPoint.x, 
 -midTangentDirectionIn.y * dTL * sinPhi + midPoint.y); 
 NSPoint midHandleOut = NSMakePoint(midTangentDirectionOut.x * dTL * sinPhi + midPoint.x,
 midTangentDirectionOut.y * dTL * sinPhi + midPoint.y); 
 NSPoint endHandle = NSMakePoint( sinPhi * s * sTL * sinPhi + endPoint.x, 
 -cosPhi * s * sTL * sinPhi + endPoint.y); 
 
 NSAffineTransform * rotate = [NSAffineTransform transform];	
 [rotate rotateByRadians: -phi];
 
 NSBezierPath * thePath = [NSBezierPath bezierPath];
 [thePath moveToPoint:startPoint];
 
 for (int i=0; i<corners; i++) {
 [thePath curveToPoint:midPoint controlPoint1:startHandle controlPoint2:midHandleIn];
 [thePath curveToPoint:endPoint controlPoint1:midHandleOut controlPoint2:endHandle];
 [thePath transformUsingAffineTransform:rotate];
 }
 
 [thePath closePath];
 
 return thePath;
 }
 
 */


- (NSBezierPath *) pathWithSize: (CGFloat) s cornerDelta: (CGFloat) cornerDelta {
	// determining the shape to draw
	NSUInteger corners = theDocument.cornerCount;
	CGFloat cF =  (theDocument.cornerFraction - cornerDelta) * sqrt(2.0);
	CGFloat sTL = theDocument.straightTangentLength;
	CGFloat sTD = theDocument.straightTangentDirection;
	CGFloat dTL = theDocument.diagonalTangentLength;
	CGFloat dTD = theDocument.diagonalTangentDirection;
	CGFloat midPointsDistance = theDocument.midPointsDistance;
	CGFloat phi = 2.0 * pi / corners;

	// anchor points
	NSPoint startPoint = NSMakePoint(s, 0.0);
	NSPoint midPoint = NSMakePoint(cos(0.5 * phi) * cF * s,  sin(0.5 * phi) * cF * s);
	NSPoint endPoint = NSMakePoint(cos(phi) * s,   sin(phi) * s);

	// handle directions
	NSPoint startHandleDirection = NSMakePoint(0,   s * sTL);
	NSPoint endHandleDirection = NSMakePoint( sin(phi) * s * sTL , 
											 -cos(phi) * s * sTL ); 	
	NSAffineTransform * rotateStartHandle = [NSAffineTransform transform];
	[rotateStartHandle rotateByRadians: sTD];
	NSPoint startHandleDirectionOut = [rotateStartHandle transformPoint:startHandleDirection];
	[rotateStartHandle invert];
	NSPoint endHandleDirectionIn = [rotateStartHandle transformPoint:endHandleDirection];
	
	NSPoint startHandle = NSMakePoint(startPoint.x + startHandleDirectionOut.x, 
									  startPoint.y + startHandleDirectionOut.y);
	NSPoint endHandle = NSMakePoint(endPoint.x + endHandleDirectionIn.x, 
									endPoint.y + endHandleDirectionIn.y);
	
	// middle tangents
	NSPoint midTangent = NSMakePoint((endPoint.x - startPoint.x), 
									 (endPoint.y - startPoint.y) );
	NSPoint midTangentDirection = NSMakePoint((endPoint.x - startPoint.x) * dTL, 
											  (endPoint.y - startPoint.y) * dTL );
	
	NSPoint mid1Point = NSMakePoint(midPoint.x - midTangent.x * midPointsDistance,
									midPoint.y - midTangent.y * midPointsDistance);
	NSPoint mid2Point = NSMakePoint(midPoint.x + midTangent.x * midPointsDistance,
									midPoint.y + midTangent.y * midPointsDistance);
	
	NSAffineTransform * rotateMidHandle = [NSAffineTransform transform];
	[rotateMidHandle rotateByRadians:dTD];
	NSPoint mid1HandleDirection = [rotateMidHandle transformPoint:midTangentDirection];
	NSPoint mid1HandleIn = NSMakePoint(mid1Point.x + mid1HandleDirection.x, mid1Point.y + mid1HandleDirection.y);
	NSPoint mid1HandleOut = NSMakePoint(mid1Point.x - mid1HandleDirection.x, mid1Point.y -mid1HandleDirection.y);
	
	[rotateMidHandle invert];
	NSPoint mid2HandleDirection = [rotateMidHandle transformPoint:midTangentDirection];
	NSPoint mid2HandleIn = NSMakePoint(mid2Point.x + mid2HandleDirection.x, mid2Point.y +mid2HandleDirection.y);
	NSPoint mid2HandleOut = NSMakePoint(mid2Point.x - mid2HandleDirection.x, mid2Point.y -mid2HandleDirection.y);
	

	// create resulting bezier path 
	NSAffineTransform * rotate = [NSAffineTransform transform];	
	[rotate rotateByRadians: -phi];
	
	NSBezierPath * thePath = [NSBezierPath bezierPath];
	[thePath moveToPoint:startPoint];
	
	for (int i=0; i<corners; i++) {
		[thePath curveToPoint:mid1Point controlPoint1:startHandle controlPoint2:mid1HandleIn];
		[thePath curveToPoint:mid2Point controlPoint1:mid1HandleOut controlPoint2:mid2HandleIn];
		[thePath curveToPoint:endPoint controlPoint1:mid2HandleOut controlPoint2:endHandle];
		[thePath transformUsingAffineTransform:rotate];
	}
	
	[thePath closePath];
	
	return thePath;
}




#pragma mark TRACKING

/*
- (void) setupTracking {
	NSRect rect;
	NSPoint pt;
	NSPoint points [3];
	
	[self removeTrackingArea:self.midHandleTA];
	[self removeTrackingArea:self.midPointTA];
	[self removeTrackingArea:self.endHandleTA];
	[self removeTrackingArea:self.endPointTA];
	
	NSTrackingAreaOptions TAoptions = (NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved|NSTrackingCursorUpdate|NSTrackingActiveInKeyWindow|NSTrackingEnabledDuringMouseDrag);
	
	[self.path elementAtIndex:2	associatedPoints:points];
	
	pt = self.midPoint;
	rect = NSMakeRect(pt.x - POINTSIZE * 0.5 * sqrt(2.0), pt.y - POINTSIZE * sqrt(2.0) * 0.5, POINTSIZE * sqrt(2.0), POINTSIZE * sqrt(2.0));
	self.midPointTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"midPoint" forKey:@"name"]];
	[self addTrackingArea:self.midPointTA];
	
	pt = self.midHandle;
	rect = NSMakeRect(pt.x - HANDLESIZE * 0.5, pt.y - HANDLESIZE * 0.5, HANDLESIZE, HANDLESIZE);
	self.midHandleTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"midHandle" forKey:@"name"]];
	[self addTrackingArea:self.midHandleTA];
	
	pt = self.endHandle;
	rect = NSMakeRect(pt.x - HANDLESIZE * 0.5, pt.y - HANDLESIZE * 0.5, HANDLESIZE, HANDLESIZE);
	self.endHandleTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"endHandle" forKey:@"name"]];
	[self addTrackingArea:self.endHandleTA];
	
	self.endPoint;
	rect = NSMakeRect(pt.x - POINTSIZE * 0.5, pt.y - POINTSIZE * 0.5, POINTSIZE, POINTSIZE);
	self.endPointTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"endPoint" forKey:@"name"]];
	[self addTrackingArea:self.endPointTA];
}
*/


- (NSString*) trackingAreaNameForMouseLocation {
	NSPoint mouseLocation = [self convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];
	if (NSPointInRect(mouseLocation, [self.endPointTA rect])) {
		return @"endPoint";
	}
	else if (NSPointInRect(mouseLocation, [self.endHandleTA rect])) {
		return @"endHandle";
	}
	else if (NSPointInRect(mouseLocation, [self.midPointTA rect])) {
		return @"midPoint";
	}
	else if (NSPointInRect(mouseLocation, [self.midHandleTA rect])) {
		return @"midHandle";											
	}
	else if (NSPointInRect(mouseLocation, [self.widthHandleTA rect])) {
		return @"widthHandle";											
	}
	else if (NSPointInRect(mouseLocation, [self.thickCornerHandleTA rect])) {
		return @"thickCornerHandle";											
	}
	return nil;
}

/*
- (NSPoint) pointForName: (NSString*) string {
	NSPoint pt;
	NSPoint points[3];
	if ([string isEqualToString:@"endPoint"]) {
		[self.path  elementAtIndex:3 associatedPoints:points];
		pt = points[2];
	}
	else if ([string isEqualToString:@"endHandle"]) {
		[self.path  elementAtIndex:3 associatedPoints:points];
		pt = points[1];
	}
	else if ([string isEqualToString:@"midPoint"]) {
		[self.path  elementAtIndex:2 associatedPoints:points];
		pt = points[2];
	}
	else if ([string isEqualToString:@"midHandle"]) {
		[self.path  elementAtIndex:3 associatedPoints:points];
		pt = points[0];		
	}
	else if ([string isEqualToString:@"startPoint"]) {
		[self.path elementAtIndex:0 associatedPoints:points];
		pt = points[0];
	}
	else {
		pt = NSMakePoint (0.0, 0.0);
	}
	return pt;
	
}
*/

#pragma mark VALUES


- (CGFloat) shapeRadius {
	return self.canvasRadius * self.theDocument.size;
}

- (CGFloat) canvasRadius {
	NSSize mySize  = self.frame.size;
	return MIN(mySize.width, mySize.height) * 0.5 * 0.9;
}

- (BOOL) useCoreAnimation {
	return [[[NSUserDefaults standardUserDefaults] valueForKey:@"useCoreAnimation"]boolValue];
}

# pragma mark POINTS

- (NSPoint) middle {
	return [self.moveToMiddle transformPoint:NSMakePoint(0.0, 0.0)];
}

- (NSPoint) startPoint {
	NSPoint points[3];
	[self.path elementAtIndex:0 associatedPoints:points];
	return points[0];	
}

- (NSPoint) midmidPoint {
	ESPolarPoint midmidPolar;
	midmidPolar.phi = pi / (theDocument.cornerCount); 
	midmidPolar.r = theDocument.cornerFraction * self.shapeRadius * sqrt(2.0);
	NSPoint midmidPoint = [self pointForPolarPoint:midmidPolar origin:self.middle];
	return midmidPoint;
}

- (NSPoint) midPoint {
	NSPoint points[3];
	[self.path  elementAtIndex:2 associatedPoints:points];
	return points[2];
}

- (NSPoint) midHandle {
	NSPoint points[3];
	[self.path  elementAtIndex:3 associatedPoints:points];
	return points[0];			
}

- (NSPoint) endPoint {
	NSPoint points[3];
	[self.path  elementAtIndex:3 associatedPoints:points];
	return points[2];
}

- (NSPoint) endHandle {
	NSPoint points[3];
	[self.path  elementAtIndex:3 associatedPoints:points];
	return points[1];	
}


/* points from inner half of the path
	the path has N = theDocument.cornerCount segments
	the path has a start point
	each segment has 3 points
	the second 
	the last point of the first segment of the second path is 
		number = 3 * N + 4
*/
- (NSPoint) innerEndPoint {
	NSPoint points[3];
	[self.path  elementAtIndex:([self.path elementCount] -6) associatedPoints:points];
	return points[2];
}

- (NSPoint) innerMidmidPoint {
	ESPolarPoint midmidPolar;
	midmidPolar.phi = pi / (theDocument.cornerCount); 
	midmidPolar.r = theDocument.cornerFraction * self.shapeRadius * sqrt(2.0) * (1-self.theDocument.thickness) * (1- self.theDocument.thickenedCorner);
	NSPoint midmidPoint = [self pointForPolarPoint:midmidPolar origin:self.middle];
	return midmidPoint;
}

/* this one doesn't actually exist */
- (NSPoint) innerUncorrectedMidmidPoint {
	ESPolarPoint midmidPolar;
	midmidPolar.phi = pi / (theDocument.cornerCount); 
	midmidPolar.r = theDocument.cornerFraction * self.shapeRadius * sqrt(2.0) * (1-self.theDocument.thickness);
	NSPoint midmidPoint = [self pointForPolarPoint:midmidPolar origin:self.middle];
	return midmidPoint;	
}



#pragma mark AFFINE TRANSFORMS

- (NSAffineTransform *) moveToMiddle {
	NSAffineTransform * aT= [NSAffineTransform transform];
	[aT translateXBy: self.frame.size.width * 0.5  yBy:self.frame.size.height * 0.5];
	return aT;	
}


- (NSAffineTransform *) moveFromMiddle {
	NSAffineTransform * aT= [NSAffineTransform transform];
	[aT translateXBy: - self.frame.size.width * 0.5  yBy: - self.frame.size.height * 0.5];
	return aT;	
}



#pragma mark POLAR COORDINATES
- (ESPolarPoint) polarPointForPoint: (NSPoint) point origin:(NSPoint) origin {
	ESPolarPoint polarPoint;
	NSPoint shiftedPoint = NSMakePoint(point.x - origin.x, point.y - origin.y);
	polarPoint.r = LENGTH(shiftedPoint);
	if (polarPoint.r != 0) {
		CGFloat sign = 1.0;
		if (shiftedPoint.y > 0 ) { sign = -1.0; }
		polarPoint.phi = sign * acos(shiftedPoint.x / polarPoint.r);
	}
	else {
		polarPoint.phi = 0;
	}
	return polarPoint;
}

- (NSPoint) pointForPolarPoint: (ESPolarPoint) polar origin:(NSPoint) origin {
	NSPoint pt;
	pt.x = origin.x + cos(polar.phi) * polar.r;
	pt.y = origin.y + sin(polar.phi) * polar.r;
	return pt;
}




@end
