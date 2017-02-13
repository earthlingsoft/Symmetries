//
//  ESSymmetryView.m
//  Symmetries
//
//  Created by  Sven on 22.05.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "ESSymmetryView.h"
#import "NSBezierPath+ESPoints.h"
#import "NSBezierPath+ESSymmetry.h"
#import "NSImage+Extras.h"
#import "ESSymmetryAnimation.h"
#import "ESSymmetryTotalAnimation.h"
#import "ESCursors.h"

#define HANDLELINEWIDTH 1.5
#define HANDLESIZE 4.0
#define HANDLEEXTRATRACKINGSIZE 4.0
#define POINTSIZE 6.0
#define LENGTH(point) sqrt(point.x * point.x + point.y * point.y)
#define STICKYANGLE 0.13
#define	STICKYLENGTH 6.0
#define POINTCOLOR [NSColor redColor]
#define HANDLECOLOR [NSColor colorWithCalibratedRed:0.35 green:1.0 blue:0.3 alpha:1.0]
#define HANDLECOLOR2 [NSColor colorWithDeviceRed:0.0 green:0.88 blue:0.0 alpha:1.0]
#define HANDLECOLOR3 [NSColor colorWithDeviceRed:0.3 green:0.85 blue:0.0 alpha:1.0]

@implementation ESSymmetryView

@synthesize theDocument;
@synthesize path;
@synthesize mouseLayer;
@synthesize guideLayer;
@synthesize handleLayer;
@synthesize clickedPointName;
@synthesize previousGuidesPoint;
@synthesize endPointTA;
@synthesize endHandleTA;
@synthesize midPointTA;
@synthesize midHandleTA;
@synthesize widthHandleTA;
@synthesize thickCornerHandleTA;
@synthesize oldDocumentValues;
@synthesize introLayer;
@synthesize demoLayer;
@synthesize currentDemoStep;
@synthesize preAnimationDocumentValues;
@synthesize lastAnimations;
@synthesize spaceOut;


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}


- (void) frameChanged: (NSNotification*) notification {
	//NSLog(@"framechange");
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:0.0] forKey:kCATransactionAnimationDuration];
	
	CGRect newBounds = NSRectToCGRect(self.bounds);
	
	self.guideLayer.bounds = newBounds;
	self.handleLayer.bounds = newBounds;
	self.introLayer.bounds = newBounds;
	if (self.demoLayer) {
		self.demoLayer.position = CGPointMake(self.layer.bounds.size.width/2.0, self.layer.bounds.size.height/2.0);

		for (CALayer * layer in self.demoLayer.sublayers) {
			layer.bounds = newBounds;
			NSInteger nr = [[[layer.name componentsSeparatedByString:@"-"] objectAtIndex:1] intValue];
			if (nr < self.currentDemoStep) { layer.position = CGPointMake( -newBounds.size.width , 0.0); }
			else if (nr > self.currentDemoStep) {layer.position = CGPointMake(newBounds.size.width, 0.0);}
		}
	}
	
	[CATransaction commit];
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
	
	// set up layer for intro
	newLayer = [CALayer layer];
	newLayer.name = @"introLayer";
	newLayer.delegate = self;
	newLayer.opacity = 0.0;
	newLayer.anchorPoint = CGPointMake(0.0, 0.0);
	newLayer.contentsGravity = kCAGravityResizeAspect;
	[mainLayer addSublayer: newLayer];
	self.introLayer = newLayer;

	// set up sizing stuff
	[self frameChanged: nil];
	[self.window disableCursorRects];	
	
	// negative value <==> no demo
	self.currentDemoStep = -1;
}	



/*
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([object isEqual:self.theDocument]) {
		[self setNeedsDisplay:YES];
	}
}
*/


#pragma mark MOUSE HANDLING

- (void)scrollWheel:(NSEvent *)theEvent {
	theDocument.size = MAX(MIN(theDocument.size + [theEvent deltaY]/100.0, 1.0), 0.0);
	theDocument.cornerFraction = MAX(MIN(theDocument.cornerFraction - [theEvent deltaX]/100.0, 1.0), -1.0);
	
	if (self.theDocument.runningAnimation){
		[self.theDocument.totalAnimation addProperty:@"cornerCount"];
		[self.theDocument.totalAnimation addProperty:@"size"];
	}		
}


- (void) mouseEntered:(NSEvent*) event {
	//NSString * pointName = [(NSDictionary*)[event userData] objectForKey: @"name"];
	//NSLog([ @"mouseEntered - " stringByAppendingString:pointName]);
	
	[self setNeedsDisplay:YES];
}



- (void) mouseExited:(NSEvent*) event {
	//NSString * pointName = [(NSDictionary*)[event userData] objectForKey: @"name"];
	//NSLog([@"mouseExited - " stringByAppendingString:pointName]);
	
	if (self.useCoreAnimation) {
		self.guideLayer.opacity = 0.0;
	}
	else {
		[self setNeedsDisplay:YES];
	}
}


/*
 called when the mouse enters/leaves tracking areas, 
 also called during drags even when NSTrackingEnabledDuringMouseDrag is not set
	=> actively avoid being called during drags (clickedPointName != nil)
*/
- (void)cursorUpdate:(NSEvent *)event {
	// NSString * TAName = [(NSDictionary*)[event userData] objectForKey:@"name"];
	// NSLog(@"cursorUpdate - %@", TAName);
	// NSRect tr = event.trackingArea.rect;
	
	// NSPoint pt = [self convertPoint:[event locationInWindow] fromView:nil];
	// NSLog(@"\tmouse Location: %f, %f", pt.x, pt.y );
	// NSLog(@"\ttracking Rect : %f, %f, %f, %f", tr.origin.x, tr.origin.y, tr.size.width, tr.size.height);
	
	if (! self.clickedPointName) {
		[self updateCursor];
	}
}



- (void) mouseDown: (NSEvent*) event {
	NSString * TAName = [self trackingAreaNameForMouseLocation];
	// NSLog([@"Clicked on " stringByAppendingString:(TAName) ? (TAName) : (@"-")]);
		
	if (TAName) {
		self.clickedPointName = TAName;
		[self setNeedsDisplay: YES];
		[self updateCursor];
		
		// store current values of the document before changes happen
		self.oldDocumentValues = self.theDocument.dictionary;
	}
	else {
		self.clickedPointName = nil;
	}	
}



- (void) mouseUp: (NSEvent*) event {
	NSString * TAName = [self trackingAreaNameForMouseLocation];
	//NSLog(@"mouseUp");

	// handle double (multiple) clicks
	if ([event clickCount] > 1) {
		// a multi-click
		if ([TAName isEqualToString:@"midPoint"]) {
			theDocument.twoMidPoints = !theDocument.twoMidPoints;
		}
		// the point may have moved away from beneath the mouse => update cursor
		[self updateCursor];
	}		
	
	self.clickedPointName = nil;
	[self updateCursor];
	[self setNeedsDisplay:YES];	
	
	if (self.oldDocumentValues && ![self.oldDocumentValues isEqualToDictionary: self.theDocument.dictionary]) {
		// the document's values changed since the last mouse down => setup undo
		[self.theDocument.undoManager registerUndoWithTarget:self.theDocument selector:@selector(setValuesForUndoFromDictionary:) object:self.oldDocumentValues]; 
	}
	self.oldDocumentValues = nil;
}



- (void) mouseDragged: (NSEvent*) event {
	NSPoint realMouseLocation = [self convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];

	if (self.clickedPointName != nil) {
		// we want to follow this click
		NSString * TAName = self.clickedPointName;
		//NSLog(@"-mouseDragged after click on %@", TAName);
		
		NSPoint mouseLocation = [self.moveFromMiddle transformPoint:realMouseLocation];
		BOOL stickyValues = !([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask);
		
		if ([TAName isEqualToString:@"endPoint"]) {
			CGFloat length = LENGTH(mouseLocation) / self.canvasRadius;
			self.theDocument.size = MIN(length, 1.0);
			
			CGFloat safeXValue = MAX(MIN(mouseLocation.x / self.shapeRadius , 1.0), -1.0);
			self.theDocument.cornerCount = MIN(round( 2 * pi / acos(safeXValue)), ESSYM_CORNERCOUNT_MAX);
	
			if (self.theDocument.runningAnimation){
				[self.theDocument.totalAnimation addProperty:@"cornerCount"];
				[self.theDocument.totalAnimation addProperty:@"size"];
			}	
		}
		else if ([TAName isEqualToString:@"endHandle"]) {
			ESPolarPoint polar = [self polarPointForPoint: realMouseLocation origin: self.endPoint];		
			CGFloat straightTangentLength = MAX(MIN(polar.r / self.shapeRadius, 1.0), 0.0);
			if (stickyValues && (polar.r < STICKYLENGTH)) {
				straightTangentLength = 0.0;
			}
			self.theDocument.straightTangentLength = straightTangentLength;
			
			CGFloat straightTangentDirection = polar.phi - 2.0 * pi/theDocument.cornerCount+ pi / 2.0;
			if (stickyValues) {
				if ( fabs(straightTangentDirection) < STICKYANGLE) {
					straightTangentDirection = 0.0;
				}
				else if (fabs(straightTangentDirection + pi) < STICKYANGLE) {
					straightTangentDirection = pi;
				}
				else if (fabs(straightTangentDirection + pi/2.0) < STICKYANGLE) {
					straightTangentDirection = - pi/2.0;
				}
				else if (fabs(straightTangentDirection - pi/2.0) < STICKYANGLE) {
					straightTangentDirection = pi/2.0;
				}
			}
			self.theDocument.straightTangentDirection = straightTangentDirection;
	
			if (self.theDocument.runningAnimation){
				[self.theDocument.totalAnimation addProperty:@"straightTangentDirection"];
				[self.theDocument.totalAnimation addProperty:@"straightTangentLength"];
			}				
		}
		else if ([TAName isEqualToString:@"midPoint"]) {
			NSPoint midTangent = NSMakePoint(self.endPoint.x - self.startPoint.x, self.endPoint.y - self.startPoint.y);
			NSAffineTransform * rotator = [NSAffineTransform transform];
			[rotator rotateByRadians: -pi/theDocument.cornerCount];
			NSPoint rotatedMouse = [rotator transformPoint:mouseLocation];

			self.theDocument.cornerFraction = MAX(MIN(rotatedMouse.x / self.shapeRadius / sqrt(2.0), 1.0), -1.0);
			
			if (theDocument.twoMidPoints) {
				CGFloat midPointsDistance =  MAX(MIN(rotatedMouse.y / LENGTH(midTangent), 1.0),-1.0);
				if (stickyValues) {
					if (abs(rotatedMouse.y) < STICKYLENGTH) {
						midPointsDistance = 0.0;
					}
				}
				self.theDocument.midPointsDistance = midPointsDistance;		
			}

			if (self.theDocument.runningAnimation){
				[self.theDocument.totalAnimation addProperty:@"cornerFraction"];
				[self.theDocument.totalAnimation addProperty:@"midPointsDistance"];
			}				
		}
		else if ([TAName isEqualToString:@"midHandle"]) {
			ESPolarPoint polar = [self polarPointForPoint: realMouseLocation origin: self.midPoint];
			
			NSPoint startToEndVector = NSMakePoint(self.endPoint.x - self.startPoint.x , self.endPoint.y - self.startPoint.y);
			CGFloat startToEndDistance = LENGTH(startToEndVector);
			self.theDocument.diagonalTangentLength = MAX(MIN(polar.r / startToEndDistance, 1.0), 0.0);
			
			CGFloat diagonalTangentDirection = polar.phi - pi / theDocument.cornerCount + pi * 0.5;
			if (stickyValues) {
				if ( fabs(diagonalTangentDirection) < STICKYANGLE) {
					diagonalTangentDirection = 0.0;
				}
				else if (fabs(diagonalTangentDirection + pi) < STICKYANGLE) {
					diagonalTangentDirection = pi;
				}
				else if (fabs(diagonalTangentDirection + pi/2.0) < STICKYANGLE) {
					diagonalTangentDirection = - pi/2.0;
				}
				else if (fabs(diagonalTangentDirection - pi/2.0) < STICKYANGLE) {
					diagonalTangentDirection = pi/2.0;
				}
			}
			self.theDocument.diagonalTangentDirection = diagonalTangentDirection;

			if (self.theDocument.runningAnimation){
				[self.theDocument.totalAnimation addProperty:@"diagonalTangentLength"];
				[self.theDocument.totalAnimation addProperty:@"diagonalTangentDirection"];
			}				
		}
		else if ([TAName isEqualToString:@"widthHandle"]) {
			NSPoint movedEndPoint = [self.moveFromMiddle transformPoint:self.endPoint];
			CGFloat scalarProduct = (movedEndPoint.x * mouseLocation.x + movedEndPoint.y * mouseLocation.y) / (movedEndPoint.x * movedEndPoint.x + movedEndPoint.y * movedEndPoint.y);
			self.theDocument.thickness = 1.0 - scalarProduct;
			
			if (self.theDocument.runningAnimation){
				[self.theDocument.totalAnimation addProperty:@"thickness"];
			}				
		}
		else if ([TAName isEqualToString:@"thickCornerHandle"]) {
			NSPoint movedMidMidPoint = [self.moveFromMiddle transformPoint:self.midmidPoint];
			CGFloat scalarProduct = (movedMidMidPoint.x * mouseLocation.x + movedMidMidPoint.y * mouseLocation.y) / (movedMidMidPoint.x * movedMidMidPoint.x + movedMidMidPoint.y * movedMidMidPoint.y);
			CGFloat thickenedCorner = 1.0 - 2.0 * scalarProduct;
			
			NSPoint distance = NSMakePoint(movedMidMidPoint.x / 2.0 - mouseLocation.x, movedMidMidPoint.y / 2.0 - mouseLocation.y);
			if (stickyValues && LENGTH(distance) < STICKYLENGTH)  {
				thickenedCorner = 0.0;
			}
			
			self.theDocument.thickenedCorner =  thickenedCorner;			
			
			if (self.theDocument.runningAnimation) {
				[self.theDocument.totalAnimation addProperty:@"thickenedCorner"];
			}				
		}
		else {
			// err, we shouldn't be here
			return;
		}
	}
	else {
		// The click was on no point => initiate drag and drop if it was far enough away
/*		BOOL handleDrag = YES;
		CGFloat rectExtraSize = 6.0;
		
		for (NSTrackingArea * TA in self.trackingAreas) {
			NSRect TARect = TA.rect; 
			NSRect newRect;
			newRect.origin.x = TARect.origin.x - rectExtraSize * 0.5;
			newRect.origin.y = TARect.origin.y - rectExtraSize * 0.5;
			newRect.size.width = TARect.size.width + rectExtraSize;
			newRect.size.height = TARect.size.height + rectExtraSize;
			if ( NSPointInRect(realMouseLocation, newRect) ) {
				// too close for comfort
				handleDrag = NO;
				break;
			}
		}
		if (handleDrag) {
			[self handleDragForEvent:event];
		}
*/
		[self handleDragForEvent:event];
	}
}






#pragma mark MOUSE TRACKING

- (NSString*) trackingAreaNameForMouseLocation {
	NSPoint mouseLocation = [self convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];
	//	NSLog (@"mouse: %f, %f", mouseLocation.x, mouseLocation.y);
	
	if ([self point:mouseLocation inRect:[self.endHandleTA rect]]) {
		return @"endHandle";
	}
	else if ([self point:mouseLocation inRect:[self.midHandleTA rect]]) {
		return @"midHandle";											
	}
	else if ([self point:mouseLocation inRect:[self.endPointTA rect]]) {
		return @"endPoint";
	}
	else if ([self point:mouseLocation inRect:[self.midPointTA rect]]) {
		return @"midPoint";
	}
	else if ([self point:mouseLocation inRect:[self.widthHandleTA rect]]) {
		return @"widthHandle";											
	}
	else if ([self point:mouseLocation inRect:[self.thickCornerHandleTA rect]]) {
		return @"thickCornerHandle";											
	}
	return nil;
}



/*
 Custom pointInRect method to work just right for mouse tracking
 (may be the same as NSMouseInRect)
*/
- (BOOL) point: (NSPoint) point inRect:(NSRect) rect {
	return (point.x >= rect.origin.x)
	&& (point.x < rect.origin.x + rect.size.width)
	&& (point.y > rect.origin.y)
	&& (point.y <= rect.origin.y + rect.size.height);
}




/*
 Set the mouse cursor to be a fancypants arrow appropriate to the current location and the standard pointer otherwise
*/
- (void) updateCursor {
	NSString * TAName;
	const BOOL isDragging = (clickedPointName != nil);
	
	if (isDragging) {
		TAName = self.clickedPointName;
	}
	else {
		TAName = [self trackingAreaNameForMouseLocation];
	}

	// NSLog (@"[ESSymmetryView updateCursor] for point %@", TAName);
		
	NSCursor * theCursor;
	CGFloat cursorSize = 16.0;
	
	if ([TAName isEqualToString:@"endPoint"]) {
		cursorSize = cursorSize + 2.0;
		NSImage * redDot = nil;
		if (isDragging) {
			redDot = [[NSImage alloc] initWithSize:NSMakeSize(POINTSIZE, POINTSIZE)];
			[redDot lockFocus];
			[[POINTCOLOR colorWithAlphaComponent:0.6] set];
			NSRectFill(NSMakeRect(0.0, 0.0, POINTSIZE, POINTSIZE));
			[redDot unlockFocus];
		}
		
		if (self.theDocument.size == ESSYM_SIZE_MIN) {
			// doesn't actually happen
			theCursor = [ESCursors curvedCursorWithRightArrow:YES upArrow:NO leftArrow:YES downArrow:YES forAngle: 2.0 * pi +  2.0 * pi / self.theDocument.cornerCount size:cursorSize underlay:redDot];
		}
		else if (self.theDocument.size == ESSYM_SIZE_MAX) {
			if (self.theDocument.cornerCount == ESSYM_CORNERCOUNT_MIN) {
				theCursor = [ESCursors curvedCursorWithRightArrow:YES upArrow:NO leftArrow:NO downArrow:YES forAngle:1.5 * pi +  2.0 * pi / self.theDocument.cornerCount size:cursorSize underlay:redDot];
			}
			else if (self.theDocument.cornerCount == ESSYM_CORNERCOUNT_MAX) {
				theCursor = [ESCursors curvedCursorWithRightArrow:NO upArrow:NO leftArrow:YES downArrow:YES forAngle:1.5 * pi +  2.0 * pi / self.theDocument.cornerCount size:cursorSize underlay:redDot];
			}
			else {
				theCursor = [ESCursors curvedCursorWithRightArrow:YES upArrow:NO leftArrow:YES downArrow:YES forAngle:1.5 * pi +  2.0 * pi / self.theDocument.cornerCount size:cursorSize underlay:redDot];
			}
		}
		else {
			if (self.theDocument.cornerCount == ESSYM_CORNERCOUNT_MIN) {
				theCursor = [ESCursors curvedCursorWithRightArrow:YES upArrow:YES leftArrow:NO downArrow:YES forAngle:1.5 * pi +  2.0 * pi / self.theDocument.cornerCount size:cursorSize underlay:redDot];
			}
			else if (self.theDocument.cornerCount == ESSYM_CORNERCOUNT_MAX) {
				theCursor = [ESCursors curvedCursorWithRightArrow:NO upArrow:YES leftArrow:YES downArrow:YES forAngle:1.5 * pi +  2.0 * pi / self.theDocument.cornerCount size:cursorSize underlay:redDot];
			}
			else {
				theCursor = [ESCursors curvedCursorWithRightArrow:YES upArrow:YES leftArrow:YES downArrow:YES forAngle:1.5 * pi +  2.0 * pi / self.theDocument.cornerCount size:cursorSize underlay:redDot];
			}
		}
	} 
	else if ([TAName isEqualToString:@"midPoint"]) {
		if (self.theDocument.twoMidPoints) {
			// two midpoints => draw variations of cross cursor
			if (self.theDocument.cornerFraction == ESSYM_CORNERFRACTION_MIN) {
				if (self.theDocument.midPointsDistance == ESSYM_MIDPOINTSDISTANCE_MIN) {
					theCursor = [ESCursors angleCursorForAngle: pi / self.theDocument.cornerCount withSize: cursorSize];					
				}
				else if (self.theDocument.midPointsDistance == ESSYM_MIDPOINTSDISTANCE_MAX) {
					theCursor = [ESCursors angleCursorForAngle: - pi / 2.0 + pi / self.theDocument.cornerCount withSize: cursorSize];					
				}
				else {
					theCursor = [ESCursors threeProngedCursorForAngle: pi + pi / 2.0 + pi / self.theDocument.cornerCount withSize: cursorSize];					
				}
			}
			else if (self.theDocument.cornerFraction == ESSYM_CORNERFRACTION_MAX) {
				if (self.theDocument.midPointsDistance == ESSYM_MIDPOINTSDISTANCE_MIN) {
					theCursor = [ESCursors angleCursorForAngle: .5 * pi + pi / self.theDocument.cornerCount withSize: cursorSize];					
				}
				else if (self.theDocument.midPointsDistance == ESSYM_MIDPOINTSDISTANCE_MAX) {
					theCursor = [ESCursors angleCursorForAngle: -.5 * pi - pi / 2.0 + pi / self.theDocument.cornerCount withSize: cursorSize];					
				}
				else {
					theCursor = [ESCursors threeProngedCursorForAngle: pi / 2.0 + pi / self.theDocument.cornerCount withSize: cursorSize];					
				}
			}
			else {
				if (self.theDocument.midPointsDistance == ESSYM_MIDPOINTSDISTANCE_MIN) {
					theCursor = [ESCursors threeProngedCursorForAngle: -0.5 * pi + pi / 2.0 + pi / self.theDocument.cornerCount withSize: cursorSize];					
					
				}
				else if (self.theDocument.midPointsDistance == ESSYM_MIDPOINTSDISTANCE_MAX) {
					theCursor = [ESCursors threeProngedCursorForAngle: 0.5 * pi + pi / 2.0 + pi / self.theDocument.cornerCount withSize: cursorSize];					
				}
				else {
					// standard cross cursor away from the borders
					theCursor = [ESCursors crossCursorForAngle: pi / 2.0 + pi / self.theDocument.cornerCount withSize: cursorSize];					
				}				
			}
		}
		else {
			// just a single midpoint => only draw cursor for cornerFraction direction
			if (self.theDocument.cornerFraction == ESSYM_CORNERFRACTION_MIN) {
				theCursor = [ESCursors halfStraightCursorForAngle: pi / self.theDocument.cornerCount  withSize:cursorSize];
			}
			else if (self.theDocument.cornerFraction == ESSYM_CORNERFRACTION_MAX) {
				theCursor = [ESCursors halfStraightCursorForAngle: pi + pi / self.theDocument.cornerCount  withSize:cursorSize];				
			}
			else {
				theCursor = [ESCursors straightCursorForAngle: pi / self.theDocument.cornerCount withSize:cursorSize];
			}
		}
	}
	else if ([TAName isEqualToString:@"endHandle"] || [TAName isEqualToString:@"midHandle"] ) {
		theCursor = [ESCursors crossCursorForAngle: 0.0 withSize:cursorSize];
	}
	else if ([TAName isEqualToString:@"widthHandle"]) {
		if (self.theDocument.thickness == ESSYM_THICKNESS_MIN) {
			theCursor = [ESCursors halfStraightCursorForAngle: pi + 2.0 * pi / self.theDocument.cornerCount  withSize:cursorSize];
		}
		else if (self.theDocument.thickness == ESSYM_THICKNESS_MAX) {
			theCursor = [ESCursors halfStraightCursorForAngle: 2.0 * pi / self.theDocument.cornerCount  withSize:cursorSize];			
		}
		else {
			theCursor = [ESCursors straightCursorForAngle: 2.0 * pi / self.theDocument.cornerCount withSize:cursorSize];
		}
	}
	else if ([TAName isEqualToString:@"thickCornerHandle"]) {
		if (self.theDocument.thickenedCorner == ESSYM_THICKENEDCORNER_MIN) {
			theCursor = [ESCursors halfStraightCursorForAngle: pi + pi / self.theDocument.cornerCount withSize:cursorSize];
		}
		else if (self.theDocument.thickenedCorner == ESSYM_THICKENEDCORNER_MAX) {
			theCursor = [ESCursors halfStraightCursorForAngle: pi / self.theDocument.cornerCount withSize:cursorSize];			
		}
		else {
			theCursor = [ESCursors straightCursorForAngle: pi / self.theDocument.cornerCount withSize:cursorSize];
		}
	}
	else {
		theCursor = [NSCursor arrowCursor];
	}
	
	[theCursor set];
}







#pragma mark DRAG & DROP 

/* We want to do drag and drop */
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	return NSDragOperationCopy;
}


- (void) handleDragForEvent: (NSEvent*) event {
	//NSLog(@"-handleDragForEvent:");
	NSDictionary * documentDict = self.theDocument.dictionary;
	NSImage * image = [[NSImage alloc] initWithData:[NSBezierPath PDFDataForDictionary: documentDict]];
	
	NSPasteboard * draggingPasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];

	// prepare dragging in different styles for registered and unregistered users
	NSData * TIFFData = [NSBezierPath TIFFDataForDictionary:documentDict size:self.theDocument.bitmapSize];
	NSData * PDFData = [NSBezierPath PDFDataForDictionary:documentDict];
	

	// declare Pboard types
	NSArray * pboardTypes = [NSArray arrayWithObjects:NSTIFFPboardType, ESSYMMETRYPBOARDTYPE, NSFilesPromisePboardType, nil];
	if (self.theDocument.registeredMode) {
		pboardTypes = [pboardTypes arrayByAddingObject:NSPDFPboardType];
	}
	[draggingPasteboard declareTypes:pboardTypes owner:self];
	
	// add image data 	
	[draggingPasteboard setData:TIFFData forType:NSTIFFPboardType];
	if (self.theDocument.registeredMode) {
		[draggingPasteboard setData:PDFData forType:NSPDFPboardType];
	}
	
		
	NSString * imageType = (NSString *) kUTTypeTIFF;
	NSString * imageExtension = @"tiff";
	if (self.theDocument.registeredMode) {
		imageType = (NSString *) kUTTypePDF;
		imageExtension = @"pdf";
	}

	// File Promise in a format accepted by Preview
	NSString * errorString;
	NSData * fileTypesData = [NSPropertyListSerialization dataFromPropertyList:[NSArray arrayWithObject:imageExtension] format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
	[draggingPasteboard setData:fileTypesData forType:NSFilesPromisePboardType];
	
	// File Promise in a format accepted by the Finder or GKON
	[draggingPasteboard setData:[imageType dataUsingEncoding:NSUTF8StringEncoding] forType:@"com.apple.pasteboard.promised-file-content-type"];
	
	
	// internal data format
	NSData * dictData = [NSArchiver archivedDataWithRootObject:documentDict];
	[draggingPasteboard setData:dictData forType:ESSYMMETRYPBOARDTYPE];

	
	NSPoint eventMousePosition = event.locationInWindow;
	NSPoint imagePosition = NSMakePoint(eventMousePosition.x - image.size.width /2.0,
										eventMousePosition.y - image.size.height / 2.0);

	NSMutableParagraphStyle * stringParagraphStyle = [[NSMutableParagraphStyle alloc] init];
	stringParagraphStyle.alignment = NSCenterTextAlignment;
	NSDictionary * stringAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont fontWithName:@"Lucida Grande Bold" size:24.], NSFontAttributeName,
		stringParagraphStyle, NSParagraphStyleAttributeName,
									   nil];
	NSAttributedString * aS = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Please Register", @"Message superimposed on drag image during the drag operation in unregistered version") attributes: stringAttributes];
	NSSize stringSize = [aS boundingRectWithSize:image.size options:NSStringDrawingUsesLineFragmentOrigin].size; //aS.size;

	NSImage * dragProxyImage = [[NSImage alloc] initWithSize: image.size];
	[dragProxyImage lockFocus];
    [image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:0.5];
	if (!self.theDocument.registeredMode) {
		[aS drawWithRect:NSMakeRect( 0, (image.size.height - stringSize.height) / 2. , 
							  image.size.width, stringSize.height)
			   options:NSStringDrawingUsesLineFragmentOrigin];
	}
	[dragProxyImage unlockFocus];
	
	[self dragImage:dragProxyImage at:imagePosition offset:NSZeroSize event:event pasteboard:draggingPasteboard source:self slideBack:YES];	
}


- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination {
	//NSLog(@"namesOfPromisedFilesDroppedAtDestination");
	if ([dropDestination isFileURL]) {
		NSString * folderName = [dropDestination path];
		NSString * fileName;
		NSString * fileNameExtension;
		NSURL * documentURL = self.theDocument.fileURL;
		if (documentURL && [documentURL isFileURL]) {
			fileName = [[documentURL.path lastPathComponent] stringByDeletingPathExtension];
		}
		else {
			fileName = @"Symmetry";
		}
		if (self.theDocument.registeredMode) {
			fileNameExtension = @"pdf";
		}
		else {
			fileNameExtension = @"tiff";
		}
		
		NSString * fullName = [fileName stringByAppendingPathExtension:fileNameExtension];
		NSString * fullPath = [folderName stringByAppendingPathComponent:fullName];
		int i = 2;
		// make sure we have a new name
		while ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
			fullName = [fileName stringByAppendingFormat:@"-%i.%@", i++, fileNameExtension];
			fullPath = [folderName stringByAppendingPathComponent:fullName];
		}
		
		// write the file 
		NSURL * destinationURL = [NSURL fileURLWithPath:fullPath];
		
		NSError * myError = nil;
		if (self.theDocument.registeredMode) {
			[self.theDocument writeToURL:destinationURL ofType: (NSString *) kUTTypePDF error:&myError];
		}
		else {
			[self.theDocument writeToURL:destinationURL ofType: (NSString *) kUTTypeTIFF error:&myError];
		}
		
		if (myError) {
			NSBeep();
			// NSLog(@"-namesOfPromisedFilesDroppedAtDestrination: image file writing failed (%@)", [myError description]);
			return nil;
		}
		else {
			return [NSArray arrayWithObject:fullName];
		}
	}
	else {
		return nil;
	}
}




#pragma mark DRAWING

- (void) drawGuidesForPoint:(NSString *) pointName {
	// NSLog([NSString stringWithFormat:@"drawGuidesForPoint %@", pointName]);

	NSString * thePointName = pointName;
	if (!pointName) {
		if (self.currentDemoStep >= 0) {
			// running demo
			switch (self.currentDemoStep) {
				case 1: case 2: thePointName = @"endPoint"; break;
				case 3: case 4: thePointName = @"midPoint"; break;
				case 5: thePointName = @"endHandle"; break;
				case 6: thePointName = @"midHandle"; break;
				case 7: thePointName = @"widthHandle"; break;
				case 8: thePointName = @"thickCornerHandle"; break;
				case 10: case 11: thePointName = @"midPoint"; break;
				default: break;
			}
		}
		else {
			thePointName = [self trackingAreaNameForMouseLocation];
			//	 NSLog([NSString stringWithFormat:@"   ... corrected to %@", thePointName]);
		}
	}	
	
	if (thePointName) {
		NSPoint origin = NSMakePoint(0.0, 0.0);
		CGFloat guideLineWidth = 8.0;
		NSBezierPath * bP = [NSBezierPath bezierPath];
		bP.lineCapStyle = NSRoundLineCapStyle;
		bP.lineWidth = guideLineWidth;

		// NSImage * image;
		if (self.useCoreAnimation) {
			// we want Core Animation - create image and draw there
			// image = [[NSImage alloc] initWithSize:self.frame.size];
			// [image lockFocus];
		}

		[self.guideColor set];

		if ([thePointName isEqualToString:@"endPoint"]) {
			// draw circle segment from 2pi/71 to pi
			CGFloat radius = LENGTH([self.moveFromMiddle transformPoint:self.endPoint]);
			[bP appendBezierPathWithArcWithCenter:origin radius:radius startAngle:360.0 / ESSYM_CORNERCOUNT_MAX endAngle:180.0];
			// draw vertical line
			[bP moveToPoint: origin];
			[bP lineToPoint: NSMakePoint(self.canvasRadius * cos(2.0 * pi / theDocument.cornerCount) , self.canvasRadius * sin(2.0 * pi / theDocument.cornerCount))];
			[bP transformUsingAffineTransform: self.moveToMiddle];
			[bP stroke];
		
			bP = [NSBezierPath bezierPath];
			for (int i = 2; i <= ESSYM_CORNERCOUNT_MAX; i++) {
				NSRect circleRect = NSMakeRect(radius * cos(2.0 * pi / i) - guideLineWidth, 
											   radius * sin(2.0 * pi / i) - guideLineWidth, 
											   2.0 * guideLineWidth, 
											   2.0 * guideLineWidth);
				[bP appendBezierPathWithOvalInRect:circleRect];
			}
			[bP transformUsingAffineTransform: self.moveToMiddle];
			[bP fill];
			
			if ([self.clickedPointName isEqualToString:@"endPoint"] && self.theDocument.cornerCount > 4) {
				// we are currently dragging -> give number of corners
				NSString * numberString = [NSString stringWithFormat:@"%li", self.theDocument.cornerCount];
				NSRange wholeString = NSMakeRange(0, numberString.length);
				NSMutableAttributedString * aString = [[NSMutableAttributedString alloc] initWithString:numberString];
				CGFloat fontSize = 72.0;
				NSFont * lucidaGrande = [NSFont fontWithName:@"Lucida Grande Bold" size:fontSize];
				[aString addAttribute:NSFontAttributeName value:lucidaGrande range:wholeString];
				[aString addAttribute:NSForegroundColorAttributeName value:self.guideColor range:wholeString];
				NSMutableParagraphStyle * myParagraphStyle = [[NSMutableParagraphStyle alloc] init];
				[myParagraphStyle setAlignment: NSRightTextAlignment];
				[aString addAttribute:NSParagraphStyleAttributeName value:myParagraphStyle range:wholeString];
				CGFloat numberDistance;
				if (self.theDocument.cornerCount < 14) {
					numberDistance = (self.theDocument.cornerCount * 5.0);
				}
				else {
					numberDistance = 70.0 + (self.theDocument.cornerCount - 14) * 2.5;
				}				
				numberDistance = MIN( numberDistance, 100.0);
				
				NSPoint basePoint = NSMakePoint((radius + numberDistance) * cos (2.0 * pi / self.theDocument.cornerCount), (radius +  numberDistance) * sin(2.0 * pi / self.theDocument.cornerCount));
				basePoint = [self.moveToMiddle transformPoint:basePoint];
				NSRect stringRect = NSMakeRect(basePoint.x - 100.0, basePoint.y, 100.0, fontSize);
				[aString drawInRect:stringRect];
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
			NSAffineTransform * at = [NSAffineTransform transform];
			[at rotateByRadians:-midmidMaximumPolar.phi];
			[at prependTransform:self.moveFromMiddle];
			NSPoint mmmPR = [at transformPoint:midmidMaximumPoint];

			if (theDocument.twoMidPoints) {
				// line for setting midPointsDistance
				NSPoint mPR = [at transformPoint:self.midPoint];
				NSPoint lineBeginR = NSMakePoint(mPR.x, LENGTH(midTangent));
				NSPoint lineEndR = NSMakePoint(mPR.x, -LENGTH(midTangent));
				[at invert];
				NSPoint lineBegin = [at transformPoint:lineBeginR];
				NSPoint lineEnd = [at transformPoint:lineEndR];
				[bP moveToPoint:lineBegin];
				[bP lineToPoint:lineEnd];
			}			
			
			// line parallel to -midmidmaximumpoint<->midmidmaximumpoint
			at = [NSAffineTransform transform];
			[at rotateByRadians:midmidMaximumPolar.phi];
			if (theDocument.twoMidPoints) {
				[at translateXBy:0.0 yBy:LENGTH(midTangent) * self.theDocument.midPointsDistance];
			}
			[at appendTransform:self.moveToMiddle];
			NSPoint line2Begin = [at transformPoint:mmmPR];
			NSAffineTransform * at2 = [NSAffineTransform transform];
			[at2 scaleXBy:-1.0 yBy:1.0];
			[at prependTransform: at2];
			NSPoint line2End = [at transformPoint:mmmPR];
			
			[bP moveToPoint:line2Begin];
			[bP lineToPoint:line2End];
			
			[self.guideColor set];
			[bP stroke];
		}
		else if ([thePointName isEqualToString:@"midHandle"]) {
			// line from -endHandle through endPoint to endHandle
			ESPolarPoint polar = [self polarPointForPoint:self.midHandle origin:self.midPoint];
			NSPoint startToEndVector = NSMakePoint(self.endPoint.x - self.startPoint.x , self.endPoint.y - self.startPoint.y);
			CGFloat startToEndDistance = LENGTH(startToEndVector);
			
			polar.r = startToEndDistance;
			polar.phi = polar.phi;
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
			NSPoint startPoint = self.middle;
			NSPoint endPoint = self.midmidPoint;
			
			bP = [NSBezierPath bezierPath];
			[bP moveToPoint:startPoint];
			[bP lineToPoint: endPoint];
			bP.lineWidth = guideLineWidth;
			bP.lineCapStyle = NSRoundLineCapStyle;
			[bP stroke];
		}
		
		
		// draw highlight of current point if adequate
		if (self.clickedPointName || self.currentDemoStep >= 0) {
			CGFloat diameter = 20.0;
			NSPoint gradientCenter = [[self valueForKey:thePointName] pointValue];
			NSGradient * gradient = [[NSGradient alloc] initWithColorsAndLocations:
									 [NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.2 alpha:0.8], 0.0,
									 [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.4 alpha:0.0], 0.7,
									 nil];

			NSRect gradientRect;
			gradientRect.origin.x = gradientCenter.x - diameter;
			gradientRect.origin.y = gradientCenter.y - diameter;
			gradientRect.size.width = 2.0 * diameter;
			gradientRect.size.height = 2.0 * diameter;
			[gradient drawInRect:gradientRect relativeCenterPosition:NSZeroPoint];
			
		}
		
		
		
		
		if (self.useCoreAnimation) {
		//	[image unlockFocus];
		//	CGImageRef imageRef = [image cgImage];
			[CATransaction begin];
			[CATransaction setValue:[NSNumber numberWithFloat:0.0f] forKey:kCATransactionAnimationDuration];
		//	self.guideLayer.contents = (id) imageRef;
			self.guideLayer.opacity = 1.0;
			[CATransaction commit];
		//	CGImageRelease(imageRef);
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
	[NSBezierPath setDefaultLineWidth:HANDLELINEWIDTH];
	
	// clear out old tracking areas
	[self removeTrackingArea:self.midHandleTA];
	[self removeTrackingArea:self.midPointTA];
	[self removeTrackingArea:self.endHandleTA];
	[self removeTrackingArea:self.endPointTA]; 
	[self removeTrackingArea:self.widthHandleTA]; 
	[self removeTrackingArea:self.thickCornerHandleTA]; 
	
	NSTrackingAreaOptions TAoptions = (NSTrackingMouseEnteredAndExited |
									   NSTrackingActiveInActiveApp | 
									   NSTrackingCursorUpdate);
	/* other flags: 	
		NSTrackingMouseMoved	
		NSTrackingEnabledDuringMouseDrag
	 
		[self addTrackingArea:[[NSTrackingArea alloc] initWithRect:self.bounds options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"global" forKey:@"name"]]];
	*/

	NSImage * image;
	BOOL usingCoreAnimation = self.useCoreAnimation;
	
	if (usingCoreAnimation) {
		image = [[NSImage alloc] initWithSize:self.frame.size];
		[image lockFocus];
	}

	
	// Handles first...
	//
	[HANDLECOLOR set];
	[NSBezierPath strokeLineFromPoint:self.endPoint toPoint:self.endHandle];
	[NSBezierPath strokeLineFromPoint:self.midPoint toPoint:self.midHandle];
	
	// ... handle control points next...
	NSRect rect = NSMakeRect(round(self.endHandle.x - HANDLESIZE * 0.5), 
							 round(self.endHandle.y - HANDLESIZE * 0.5), 
							 HANDLESIZE, HANDLESIZE);
	NSBezierPath * bP = [NSBezierPath bezierPathWithOvalInRect:rect];
	rect.origin.x = round(rect.origin.x - HANDLEEXTRATRACKINGSIZE / 2.0);
	rect.origin.y = round(rect.origin.y - 1.0);
	rect.size.width = HANDLESIZE + HANDLEEXTRATRACKINGSIZE;
	rect.size.height = HANDLESIZE + HANDLEEXTRATRACKINGSIZE;
	self.endHandleTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"endHandle" forKey:@"name"]];
	[self addTrackingArea:self.endHandleTA];
	
	rect = NSMakeRect(round(self.midHandle.x - HANDLESIZE * 0.5), 
					  round(self.midHandle.y - HANDLESIZE * 0.5), 
					  HANDLESIZE, 
					  HANDLESIZE);
	[bP appendBezierPathWithOvalInRect:rect];
	rect.origin.x = round(rect.origin.x - HANDLEEXTRATRACKINGSIZE / 2.0);
	rect.origin.y = round(rect.origin.y - HANDLEEXTRATRACKINGSIZE / 2.0);
	rect.size.width = HANDLESIZE + HANDLEEXTRATRACKINGSIZE;
	rect.size.height = HANDLESIZE + HANDLEEXTRATRACKINGSIZE;	
	self.midHandleTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"midHandle" forKey:@"name"]];	
	[self addTrackingArea:self.midHandleTA];
	[bP fill];
	
	if (self.theDocument.twoLines) {
		// handles for thickness and thickened corner
		CGFloat lineHandleWidth = 12.0;
		CGFloat lineHandleThickness = 6.0;
		bP = [NSBezierPath bezierPath];
		bP.lineCapStyle = NSRoundLineCapStyle;
		bP.lineWidth = lineHandleThickness;
		CGFloat phi = 0.5 * pi  + 2.0 * pi / self.theDocument.cornerCount;

		// ... thickness handle
		NSPoint lineStart = NSMakePoint(self.innerEndPoint.x - cos(phi) * lineHandleWidth,
										self.innerEndPoint.y - sin(phi) * lineHandleWidth);
		NSPoint lineEnd = NSMakePoint(self.innerEndPoint.x + cos(phi) * lineHandleWidth,
									  self.innerEndPoint.y + sin(phi) * lineHandleWidth);
		
		[bP moveToPoint:lineStart];
		[bP lineToPoint:lineEnd];
		rect = [bP bounds];
		rect.origin.x = round(rect.origin.x - lineHandleThickness * 0.5);
		rect.origin.y = round(rect.origin.y - lineHandleThickness * 0.5);
		rect.size.width = round(rect.size.width + lineHandleThickness);
		rect.size.height = round(rect.size.height + lineHandleThickness);
		self.widthHandleTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"widthHandle" forKey:@"name"]];
		[self addTrackingArea:self.widthHandleTA];
		
		// ... thickened corner handle
		phi = 0.5 * pi + pi / self.theDocument.cornerCount;
		lineStart = NSMakePoint(self.middleMidmidPoint.x - cos(phi) * lineHandleWidth,
								self.middleMidmidPoint.y - sin(phi) * lineHandleWidth);
		lineEnd = NSMakePoint(self.middleMidmidPoint.x + cos(phi) * lineHandleWidth,
							  self.middleMidmidPoint.y + sin(phi) * lineHandleWidth);
		
		NSBezierPath * bP2 = [NSBezierPath bezierPath];
		[bP2 moveToPoint:lineStart];
		[bP2 lineToPoint:lineEnd];
		rect = [bP2 bounds];
		rect.origin.x = round(rect.origin.x - lineHandleThickness * 0.5);
		rect.origin.y = round(rect.origin.y - lineHandleThickness * 0.5);
		rect.size.width = round(rect.size.width + lineHandleThickness);
		rect.size.height = round(rect.size.height + lineHandleThickness);
		self.thickCornerHandleTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"thickCornerHandle" forKey:@"name"]];
		[self addTrackingArea:self.thickCornerHandleTA];
			
		[bP appendBezierPath:bP2];
		[HANDLECOLOR set];
		[bP stroke];
		
		// a little bit of structure
		[HANDLECOLOR2 set];
		bP.lineWidth = 3.0;
		[bP stroke];
		[HANDLECOLOR3 set];
		bP.lineWidth = 1.0;
		[bP stroke];
		
	}
	

	// anchor points on top
	bP = [NSBezierPath bezierPath];
	[POINTCOLOR set];
	
	// a diamond for the mid point
	CGFloat pSize = POINTSIZE * sqrt(2);
	[bP moveToPoint:NSMakePoint(self.midPoint.x + 0.5 * pSize, self.midPoint.y)];
	[bP lineToPoint:NSMakePoint(self.midPoint.x, self.midPoint.y + 0.5 * pSize)];
	[bP lineToPoint:NSMakePoint(self.midPoint.x - 0.5 * pSize, self.midPoint.y)];
	[bP lineToPoint:NSMakePoint(self.midPoint.x, self.midPoint.y - 0.5 * pSize)];
	[bP closePath];
	rect = [bP bounds];
	rect.origin.x = round(rect.origin.x - HANDLEEXTRATRACKINGSIZE / 2.0);
	rect.origin.y = round(rect.origin.y - HANDLEEXTRATRACKINGSIZE / 2.0);
	rect.size.width = round(rect.size.width + HANDLEEXTRATRACKINGSIZE);
	rect.size.height = round(rect.size.height + HANDLEEXTRATRACKINGSIZE);
	self.midPointTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"midPoint" forKey:@"name"]];
	[self addTrackingArea:self.midPointTA];
	
	if (( [self.clickedPointName isEqualTo:@"midPoint"] && self.theDocument.twoMidPoints)
			|| self.currentDemoStep == 3 || self.currentDemoStep == 4 || self.currentDemoStep == 10 || self.currentDemoStep == 11) {
		// we are dragging with two mid points -> draw the oder mid point as well
		[bP moveToPoint:NSMakePoint(self.otherMidPoint.x + 0.5 * pSize, self.otherMidPoint.y)];
		[bP lineToPoint:NSMakePoint(self.otherMidPoint.x, self.otherMidPoint.y + 0.5 * pSize)];
		[bP lineToPoint:NSMakePoint(self.otherMidPoint.x - 0.5 * pSize, self.otherMidPoint.y)];
		[bP lineToPoint:NSMakePoint(self.otherMidPoint.x, self.otherMidPoint.y - 0.5 * pSize)];
		[bP closePath];		
	}
	
	
	// a square for the end point
	rect = NSMakeRect(round(self.endPoint.x - POINTSIZE * 0.5), 
					  round(self.endPoint.y - POINTSIZE * 0.5), 
					  POINTSIZE, 
					  POINTSIZE);
	[bP appendBezierPathWithRect:rect];
	rect.origin.x = round(rect.origin.x - HANDLEEXTRATRACKINGSIZE / 2.0);
	rect.origin.y = round(rect.origin.y - HANDLEEXTRATRACKINGSIZE / 2.0);
	rect.size.width = round(rect.size.width + HANDLEEXTRATRACKINGSIZE);
	rect.size.height = round(rect.size.height + HANDLEEXTRATRACKINGSIZE);
	self.endPointTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"endPoint" forKey:@"name"]];
	[self addTrackingArea:self.endPointTA];
	[bP fill];

	
	if (usingCoreAnimation) {
		[image unlockFocus];
		// put into layer	
		CGImageRef imageRef = [image cgImage];
		[CATransaction begin];
		[CATransaction setValue:[NSNumber numberWithFloat:0.0f] forKey:kCATransactionAnimationDuration];
		self.handleLayer.contents = (__bridge id) imageRef;
		self.handleLayer.opacity = 1.0;
		[CATransaction commit];
		CGImageRelease(imageRef);	
	}	
	else {
		self.handleLayer.opacity = 0.0;
	}
	// debugging -- draw trackingareas' rects when caps lock is pressed
/*
	if ([[NSApp currentEvent] modifierFlags] & NSAlphaShiftKeyMask) {
		[[NSColor orangeColor] set];
		[NSBezierPath strokeRect:self.endPointTA.rect];
		[NSBezierPath strokeRect:self.endHandleTA.rect];	
		[NSBezierPath strokeRect:self.midPointTA.rect];	
		[NSBezierPath strokeRect:self.midHandleTA.rect];
		if (self.theDocument.twoLines) {
			[NSBezierPath strokeRect:self.widthHandleTA.rect];
			[NSBezierPath strokeRect:self.thickCornerHandleTA.rect];
		}
	}
*/ 
}



- (void)drawRect:(NSRect)rect {
	// NSLog(@"-[ESSymmetryView drawRect:]");
	
	NSBezierPath * thePath = [NSBezierPath bezierPathWithDictionary:theDocument.dictionary size:self.shapeRadius];	
/*	if (self.theDocument.runningAnimation) {
		// while animating, take into account the rotation value
		NSAffineTransform * aT = [NSAffineTransform transform];
		[aT rotateByRadians: self.theDocument.rotation];
		[thePath transformUsingAffineTransform:aT];
	}
*/	
	[thePath transformUsingAffineTransform:self.moveToMiddle]; 
	[self setValue:thePath forKey:@"path"];
	
	// draw
	
	[theDocument.backgroundColor set];
	NSRectFill(self.bounds);
	
	// background
	if (spaceOut) {
		NSColor * startColor = [NSColor colorWithCalibratedHue:1.0 - [theDocument normalisePolarAngle: 1.0 * theDocument.straightTangentDirection + 1.0 * theDocument.diagonalTangentDirection] / (2.0 * pi)  saturation:0.8 - theDocument.size * 0.3  brightness:0.7 alpha:0.9];
		NSColor * endColor = [NSColor colorWithCalibratedHue:1.0 - [theDocument normalisePolarAngle: 2.0 * theDocument.straightTangentDirection - theDocument.diagonalTangentDirection + 2.0 * pi] / (2.0 * pi)  saturation:1.0 - theDocument.size * 0.3  brightness:0.7 alpha:0.9];
		NSGradient * gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
		[gradient drawInRect:self.bounds relativeCenterPosition:NSMakePoint(0.0, 0.0)];
	}
	
	
	// fill shape
	if (theDocument.twoLines) {
		if (!spaceOut) {
			[theDocument.fillColor set];
			[thePath fill];
		}
		else{
			CGFloat saturation = 1.0 - theDocument.size * 0.2;
			NSColor * startColor = [NSColor colorWithCalibratedHue: [theDocument normalisePolarAngle: 2.0 * theDocument.straightTangentDirection + theDocument.diagonalTangentDirection] / (2.0 * pi)  saturation:saturation brightness:0.9 alpha:1.0];
			NSColor * midColor = [NSColor colorWithCalibratedHue: [theDocument normalisePolarAngle: theDocument.straightTangentDirection + theDocument.diagonalTangentDirection] / ( 2.0 * pi) saturation:saturation brightness:0.9 alpha:0.8];
			NSColor * endColor = [NSColor colorWithCalibratedHue:[theDocument normalisePolarAngle: theDocument.straightTangentDirection -  theDocument.diagonalTangentDirection] / (2.0 * pi)  saturation:saturation brightness:0.9 alpha:1.0];
			NSGradient * gradient = [[NSGradient alloc] initWithColorsAndLocations: startColor, 0.0, midColor, 0.5 * 0.2 * theDocument.cornerFraction, endColor, 1.0, nil];
			[gradient drawInBezierPath:thePath relativeCenterPosition:NSMakePoint(0.0, 0.0)];
		}
	}

	if (theDocument.strokeThickness != 0.0) {
		[theDocument.strokeColor set];
		[thePath setLineWidth: theDocument.strokeThickness * self.canvasRadius / 10.0];
		[thePath stroke];
	}
	
	
	if ([NSGraphicsContext currentContextDrawingToScreen] ) {
		// draw handles and guides to the screen (only)
		if (theDocument.showHandles != 0) {
			self.handleLayer.opacity = 1.0;
			[self drawGuidesForPoint:self.clickedPointName];
			if (theDocument.showHandles == 2) {
				[thePath drawPointsInColor:[NSColor grayColor] withHandlesInColor:[NSColor grayColor]];
			}
			[self drawHandlesForFundamentalPath];
		}
		else {
			self.handleLayer.opacity = 0.0;
		}
		// Window resize widget
		[[NSImage imageNamed:@"Resize Widget.png"] drawAtPoint:NSMakePoint(self.window.frame.size.width - 13.0,  1.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];
	}
	
	// make sure the screen doesn't dim while we are in the foreground or the demo is running, may keep the screen from sleeping while running AppleScript	
	if ( [NSApp isActive] || self.theDocument.runningDemo) {
		UpdateSystemActivity(UsrActivity);
	}
}


- (void) drawPoint: (NSPoint) pt {
	[[NSColor orangeColor] set];
	NSRect myRect = NSMakeRect(pt.x - 2.0, pt.y -2.0, 4.0, 4.0);
	[NSBezierPath fillRect:myRect];
}






#pragma mark VALUES


- (CGFloat) shapeRadius {
	return self.canvasRadius * self.theDocument.size;
}


- (CGFloat) canvasRadius {
	NSSize mySize  = self.frame.size;
	return MIN(mySize.width, mySize.height) * 0.5 * 0.9;
}


- (BOOL) useCoreAnimation {
	return [[[NSUserDefaults standardUserDefaults] valueForKey:@"useCoreAnimation"] boolValue];
	// return YES;
}


- (NSColor *) guideColor {
	return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:0.6];
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


- (NSPoint) otherMidPoint {
	if (theDocument.twoMidPoints) {
		NSPoint points[3];
		[self.path  elementAtIndex:1 associatedPoints:points];
		return points[2];
	}
	else {
		// in the single midpoint case this is the same as the midpoint
		return self.midPoint;
	}
}
		

- (NSPoint) midmidPoint {
	if (theDocument.twoMidPoints) {
		ESPolarPoint midmidPolar;
		midmidPolar.phi = pi / (theDocument.cornerCount); 
		midmidPolar.r = theDocument.cornerFraction * self.shapeRadius * sqrt(2.0);
		NSPoint midmidPoint = [self pointForPolarPoint:midmidPolar origin:self.middle];
		return midmidPoint;
	}
	else {
		// in the single midpoint case this is the same as the midpoint
		return self.midPoint;
	}
}

	
- (NSPoint) midPoint {
	NSPoint points[3];
	NSInteger index = (theDocument.twoMidPoints) ? (2) : (1);
	[self.path  elementAtIndex:index associatedPoints:points];
	return points[2];
}

	
- (NSPoint) midHandle {
	NSPoint points[3];
	NSInteger index = (theDocument.twoMidPoints) ? (3) : (2);
	[self.path  elementAtIndex:index associatedPoints:points];
	return points[0];			
}

	
- (NSPoint) endPoint {
	NSPoint points[3];
	NSInteger index = (theDocument.twoMidPoints) ? (3) : (2);
	[self.path  elementAtIndex:index associatedPoints:points];
	return points[2];
}

	
- (NSPoint) endHandle {
	NSPoint points[3];
	NSInteger index = (theDocument.twoMidPoints) ? (3) : (2);
	[self.path  elementAtIndex:index associatedPoints:points];
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
	NSInteger offset = (theDocument.twoMidPoints) ? (6) : (5);
	[self.path  elementAtIndex:([self.path elementCount] - offset) associatedPoints:points];
	return points[2];
}

- (NSPoint) widthHandle {
	return self.innerEndPoint;
}

	
- (NSPoint) innerMidmidPoint {
	ESPolarPoint midmidPolar;
	midmidPolar.phi = pi / (theDocument.cornerCount); 
	midmidPolar.r = theDocument.cornerFraction * self.shapeRadius * sqrt(2.0) * (1-self.theDocument.thickness) * (1- self.theDocument.thickenedCorner);
	NSPoint immp = [self pointForPolarPoint:midmidPolar origin:self.middle];
	return immp;
}


	
/* this one doesn't actually exist */
- (NSPoint) innerUncorrectedMidmidPoint {
	ESPolarPoint midmidPolar;
	midmidPolar.phi = pi / (theDocument.cornerCount); 
	midmidPolar.r = theDocument.cornerFraction * self.shapeRadius * sqrt(2.0) * (1-self.theDocument.thickness);
	NSPoint midmidPoint = [self pointForPolarPoint:midmidPolar origin:self.middle];
	return midmidPoint;	
}


- (NSPoint) middleMidmidPoint {
	ESPolarPoint polar = [self polarPointForPoint:self.midmidPoint origin:self.middle];
	polar.r = (- self.theDocument.thickenedCorner + 1.0) / 2.0 * polar.r ; 
	NSPoint pt = [self pointForPolarPoint:polar origin:self.middle];
	return pt;
}

- (NSPoint) thickCornerHandle{
	return self.middleMidmidPoint;
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
	NSPoint shiftedPoint = NSMakePoint(point.x - origin.x, 
									   point.y - origin.y);
	polarPoint.r = LENGTH(shiftedPoint);
	if (polarPoint.r != 0) {
		CGFloat sign = 1.0;
		if (shiftedPoint.y < 0 ) { sign = -1.0; }
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
