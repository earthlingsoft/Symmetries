//
//  ESSymmetryView.m
//  Symmetry
//
//  Created by  Sven on 22.05.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "ESSymmetryView.h"
#import "NSBezierPath+Points.h"
#import "NSBezierPath+ESSymmetry.h"
#import "NSImage+Extras.h"

#define MAXCORNERNUMBER 37
#define HANDLELINEWIDTH 1.5
#define HANDLESIZE 4.0
#define POINTSIZE 6.0
#define LENGTH(point) sqrt(point.x*point.x + point.y*point.y)
#define STICKYANGLE 0.05
#define	STICKYLENGTH 4.0


@implementation ESSymmetryView

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
@synthesize oldDocumentValues;
@synthesize introLayer;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}



- (void) frameChanged: (NSNotification*) notification {
	NSLog(@"framechange");
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:0.0] forKey:kCATransactionAnimationDuration];
	self.guideLayer.bounds = NSRectToCGRect(self.bounds);
	self.handleLayer.bounds = NSRectToCGRect(self.bounds);
	self.introLayer.bounds = NSRectToCGRect(self.bounds);
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
	
	// set up layer for intro
	newLayer = [CALayer layer];
	newLayer.name = @"introLayer";
	newLayer.opacity = 0.0;
	newLayer.anchorPoint = CGPointMake(0.0, 0.0);
	[mainLayer addSublayer: newLayer];
	self.introLayer = newLayer;
	
	// set up sizing stuff
	[self frameChanged: nil];
	[self.window disableCursorRects];

	
	
/*	CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath: @"delegate.theDocument.straightTangentDirection"];
	animation.duration = 10.0;
	animation.repeatCount = 20;
	animation.fromValue = [NSNumber numberWithFloat:0.0];
	animation.toValue = [NSNumber numberWithFloat:2.0 * pi];
	[mainLayer addAnimation:animation forKey:@"angleAnimation"];
	[self.theDocument addObserver:self forKeyPath:@"straightTangentDirection" options:NSKeyValueObservingOptionNew context:nil];
 */
	
	[self intro];
}	


- (void) intro {
	NSString * welcomeText1 = NSLocalizedString(@"Welcome", @"Welcome");
	NSString * welcomeText2 = NSLocalizedString(@"Click whatever looks clickable.", @"Click whatever looks clickable.");
	NSString * welcomeText3 = NSLocalizedString(@"There's a Demo in the Help menu. And a Readme as well.", @"There's a Demo in the Help menu. And a Readme as well.");	

	NSString * welcomeText = [NSString stringWithFormat:@"%@\n%@\n%@", welcomeText1, welcomeText2, welcomeText3];
	
	NSMutableAttributedString * aString = [[NSMutableAttributedString alloc] initWithString:welcomeText];
	
	NSMutableDictionary * textAttributes = [NSMutableDictionary dictionaryWithCapacity:3];
	NSFont * font = [NSFont fontWithName:@"Lucida Grande Bold" size:72.0];
	[textAttributes setObject:font forKey:NSFontAttributeName];
	NSMutableParagraphStyle * myParagraphStyle = [[NSMutableParagraphStyle alloc] init];
	[myParagraphStyle setAlignment: NSCenterTextAlignment];
	[textAttributes setObject:myParagraphStyle forKey:NSParagraphStyleAttributeName];
	[textAttributes setObject:self.guideColor forKey:NSForegroundColorAttributeName];
	
	NSRange range = NSMakeRange(0, welcomeText1.length + 1);
	[aString setAttributes:textAttributes range:range];
	font = [NSFont fontWithName:@"Lucida Grande Bold" size: 32.0];
	[textAttributes setObject:font forKey:NSFontAttributeName];
	range = NSMakeRange(welcomeText1.length + 1, welcomeText2.length + 1);
	[aString setAttributes:textAttributes range:range];
	font = [NSFont fontWithName:@"Lucida Grande Bold" size: 18.0];
	[textAttributes setObject:font forKey:NSFontAttributeName];
	range = NSMakeRange(welcomeText1.length + 1 + welcomeText2.length + 1, welcomeText3.length);
	[aString setAttributes:textAttributes range:range];
	
	NSImage * image = [[NSImage alloc] initWithSize:self.bounds.size];
	[image lockFocus];
	NSRect stringRect = NSMakeRect(0.0, 32.0, self.bounds.size.width, 72.0 + 48.0 + 48.0);
	[aString drawInRect:stringRect];
	[image unlockFocus];
	
	CGImageRef imageRef = [image cgImage];
	self.introLayer.contents = (id) imageRef;
	self.introLayer.opacity = 1.0;
	
	CAKeyframeAnimation * myAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
	myAnimation.keyTimes = [NSArray arrayWithObjects: 
							[NSNumber numberWithFloat:0.0],
							[NSNumber numberWithFloat:0.8],
							[NSNumber numberWithFloat:1.0],
								nil];
	myAnimation.timingFunctions = [NSArray arrayWithObjects:
						[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear],
						[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
								   nil];
	myAnimation.values = [NSArray arrayWithObjects:
							[NSNumber numberWithFloat:1.0],
							[NSNumber numberWithFloat:1.0],
							[NSNumber numberWithFloat:0.0],
								nil];
	myAnimation.delegate = self;
	myAnimation.duration = 8.0;
	myAnimation.removedOnCompletion = NO;
	myAnimation.fillMode = kCAFillModeForwards;
	[self.introLayer addAnimation:myAnimation forKey:@"textFadeOut"];
}


/* 
	animation delegate
*/
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:0.0] forKey:kCATransactionAnimationDuration];
	self.introLayer.hidden = YES;
	[self.introLayer removeAnimationForKey:@"textFadeOut"];
	[CATransaction commit];
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
	// [self setNeedsDisplay: YES];
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
		[[NSCursor closedHandCursor] set];
		
		// store current values of the document before changes happen
		self.oldDocumentValues = [self.theDocument dictionary];
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
	}		
	
	self.clickedPointName = nil;
	[self updateCursor];
	[self setNeedsDisplay:YES];	
	
	if (self.oldDocumentValues && ![self.oldDocumentValues isEqualToDictionary: [self.theDocument dictionary]]) {
		// the document's values changed since the last mouse down => setup undo
		[self.theDocument.undoManager registerUndoWithTarget:self.theDocument selector:@selector(setValuesForUndoFromDictionary:) object:self.oldDocumentValues]; 
	}
	self.oldDocumentValues = nil;
}




- (void) mouseDragged: (NSEvent*) event {
	if (self.clickedPointName != nil) {
		// we want to follow this click
		NSString * TAName = self.clickedPointName;
		NSLog(@"-mouseDragged after click on %@", TAName);
		
		NSPoint realMouseLocation = [self convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];
		NSPoint mouseLocation = [self.moveFromMiddle transformPoint:realMouseLocation];
		BOOL stickyValues = !([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask);
		
		if ([TAName isEqualToString:@"endPoint"]) {
			CGFloat length = LENGTH(mouseLocation) / self.canvasRadius;
			theDocument.size = MIN(length, 1.0);
			CGFloat safeXValue = MAX(MIN(mouseLocation.x / self.shapeRadius , 1.0), -1.0);
			theDocument.cornerCount = MIN(round( 2 * pi / acos(safeXValue)), MAXCORNERNUMBER);
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
		}
		else if ([TAName isEqualToString:@"midHandle"]) {
			ESPolarPoint polar = [self polarPointForPoint: realMouseLocation origin: self.midPoint];
			
			NSPoint startToEndVector = NSMakePoint(self.endPoint.x - self.startPoint.x , self.endPoint.y - self.startPoint.y);
			CGFloat startToEndDistance = LENGTH(startToEndVector);

			theDocument.diagonalTangentLength = MAX(MIN(polar.r / startToEndDistance, 1.0), 0.0);
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
			theDocument.diagonalTangentDirection = diagonalTangentDirection;
		}
		else if ([TAName isEqualToString:@"widthHandle"]) {
			ESPolarPoint endPolar = [self polarPointForPoint:self.endPoint origin:self.middle];
			ESPolarPoint mousePolar = [self polarPointForPoint:realMouseLocation origin:self.middle];
			CGFloat thickness = MAX(MIN(1.0 - mousePolar.r / endPolar.r, 1.0), 0.0);
			if (abs(mousePolar.phi - endPolar.phi) > pi/2.0 ) {
				// we're on the wrong side of the origin => end value
				thickness = 1.0;
			}
			theDocument.thickness = thickness;
		}
		else if ([TAName isEqualToString:@"thickCornerHandle"]) {
			ESPolarPoint mousePolar = [self polarPointForPoint:realMouseLocation	origin:self.middle];
			ESPolarPoint midmidPolar = [self polarPointForPoint:self.midmidPoint origin:self.middle];
			CGFloat thickenedCorner = 1.0 - 2.0 * mousePolar.r / midmidPolar.r;
			thickenedCorner = MAX(MIN(thickenedCorner, 1.0), -1.0 );
			if (stickyValues && fabs(mousePolar.r - midmidPolar.r/2.0 ) < STICKYLENGTH)  {
				thickenedCorner = 0.0;
			}
			if (abs(mousePolar.phi - midmidPolar.phi) > pi/2.0 ) {
				// we're on the wrong side of the origin => maximum value
				thickenedCorner = 1.0;
			}
			theDocument.thickenedCorner =  thickenedCorner;			
			//NSLog(@"%f", theDocument.thickenedCorner);
		}
		else {
			// err, we shouldn't be here
			return;
		}
	}
	else {
		// The click was on no point => initiate drag and drop
		[self handleDragForEvent:event];
	}
}



#pragma mark DRAG & DROP 

/* We want to do drag and drop */
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal  {
	return NSDragOperationCopy;
}


- (void) handleDragForEvent: (NSEvent*) event {
	NSLog(@"-handleDragForEvent:");
	NSDictionary * documentDict = [self.theDocument dictionary];
	NSData * pdfData = [NSBezierPath PDFDataForDictionary: documentDict];
	NSImage * image = [[NSImage alloc] initWithData:pdfData];
	
	NSPasteboard * draggingPasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	[draggingPasteboard declareTypes:[NSArray arrayWithObjects:NSPDFPboardType, ESSYMMETRYPBOARDTYPE, NSFilesPromisePboardType, nil] owner:self];
	
	[draggingPasteboard setData:pdfData forType:NSPDFPboardType];
	NSString * errorString;
	NSData * fileTypesData = [NSPropertyListSerialization dataFromPropertyList:[NSArray arrayWithObject:@"pdf"] format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
	[draggingPasteboard setData:fileTypesData forType:NSFilesPromisePboardType];
	[draggingPasteboard setData:[@"com.adobe.pdf" dataUsingEncoding:NSUTF8StringEncoding] forType:@"com.apple.pasteboard.promised-file-content-type"];
	NSData * dictData = [NSArchiver archivedDataWithRootObject:documentDict];
	[draggingPasteboard setData:dictData forType:ESSYMMETRYPBOARDTYPE];

	NSPoint eventMousePosition = event.locationInWindow;
	NSPoint imagePosition = NSMakePoint(image.size.width * eventMousePosition.x / self.bounds.size.width,
										image.size.height * eventMousePosition.y / self.bounds.size.height);

	NSImage * dragProxyImage = [[NSImage alloc] initWithSize: image.size];
	[dragProxyImage lockFocus];
	[image compositeToPoint:NSZeroPoint operation:NSCompositeCopy fraction: 0.5];
	[dragProxyImage unlockFocus];
	
	[self dragImage:dragProxyImage at:imagePosition offset:NSZeroSize event:event pasteboard:draggingPasteboard source:self slideBack:YES];	
}


- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination {
	NSLog(@"namesOfPromisedFilesDroppedAtDestination");
	if ([dropDestination isFileURL]) {
		NSString * folderName = [dropDestination path];
		NSString * fileName;
		NSURL * documentURL = self.theDocument.fileURL;
		if (documentURL && [documentURL isFileURL]) {
			fileName = [[documentURL.path lastPathComponent] stringByDeletingPathExtension];
		}
		else {
			fileName = @"Symmetry";
		}
		NSString * fullName = [fileName stringByAppendingPathExtension:@"pdf"];
		NSString * fullPath = [folderName stringByAppendingPathComponent:fullName];
		int i = 2;
		// make sure we have a new name
		while ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
			fullName = [fileName stringByAppendingFormat:@"-%i.pdf", i++];
			fullPath = [folderName stringByAppendingPathComponent:fullName];
		}
		
		// write the file 
		NSDictionary * documentDict = [self.theDocument dictionary];
		NSData * pdfData = [NSBezierPath PDFDataForDictionary: documentDict];
		NSURL * destinationURL = [NSURL fileURLWithPath:fullPath];
		[pdfData writeToURL:destinationURL atomically:YES];
		return [NSArray arrayWithObject:fullName];
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
		thePointName = [self trackingAreaNameForMouseLocation];
		// NSLog([NSString stringWithFormat:@"   ... corrected to %@", thePointName]);
	}	
	
	if (thePointName) {
		NSPoint origin = NSMakePoint(0.0, 0.0);
		CGFloat guideLineWidth = 8.0;
		NSBezierPath * bP = [NSBezierPath bezierPath];
		bP.lineCapStyle = NSRoundLineCapStyle;
		bP.lineWidth = guideLineWidth;

		NSImage * image;
		if (self.useCoreAnimation) {
			// we want Core Animation - create image and draw there
			image = [[NSImage alloc] initWithSize:self.frame.size];
			[image lockFocus];
		}

		[self.guideColor set];

		if ([thePointName isEqualToString:@"endPoint"]) {
			// draw circle segment from 2pi/71 to pi
			CGFloat radius = LENGTH([self.moveFromMiddle transformPoint:self.endPoint]);
			[bP appendBezierPathWithArcWithCenter:origin radius:radius startAngle:360.0 / MAXCORNERNUMBER endAngle:180.0];
			// draw vertical line
			[bP moveToPoint: origin];
			[bP lineToPoint: NSMakePoint(self.canvasRadius * cos(2.0 * pi / theDocument.cornerCount) , self.canvasRadius * sin(2.0 * pi / theDocument.cornerCount))];
			[bP transformUsingAffineTransform: self.moveToMiddle];
			[bP stroke];
		
			bP = [NSBezierPath bezierPath];
			for (int i = 2; i <= MAXCORNERNUMBER; i++) {
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
				NSString * numberString = [NSString stringWithFormat:@"%i", self.theDocument.cornerCount];
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
	if (self.useCoreAnimation) {
		image = [[NSImage alloc] initWithSize:self.frame.size];
		[image lockFocus];
	}
		
	// Handles first...
	//
	[handleColor set];
	[NSBezierPath strokeLineFromPoint:self.endPoint toPoint:self.endHandle];
	[NSBezierPath strokeLineFromPoint:self.midPoint toPoint:self.midHandle];
	
	// ... handle control points next...
	NSRect rect = NSMakeRect(round(self.endHandle.x - HANDLESIZE * 0.5), 
							 round(self.endHandle.y - HANDLESIZE * 0.5), 
							 HANDLESIZE, HANDLESIZE);
	NSBezierPath * bP = [NSBezierPath bezierPathWithOvalInRect:rect];
	rect.origin.x = round(rect.origin.x - 1.0);
	rect.origin.y = round(rect.origin.y - 1.0);
	rect.size.width = HANDLESIZE + 2.0;
	rect.size.height = HANDLESIZE + 2.0;
	self.endHandleTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"endHandle" forKey:@"name"]];
	[self addTrackingArea:self.endHandleTA];
	
	rect = NSMakeRect(round(self.midHandle.x - HANDLESIZE * 0.5), 
					  round(self.midHandle.y - HANDLESIZE * 0.5), 
					  HANDLESIZE, 
					  HANDLESIZE);
	[bP appendBezierPathWithOvalInRect:rect];
	rect.origin.x = round(rect.origin.x - 1.0);
	rect.origin.y = round(rect.origin.y - 1.0);
	rect.size.width = HANDLESIZE + 2.0;
	rect.size.height = HANDLESIZE + 2.0;	
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
		ESPolarPoint polar = [self polarPointForPoint:self.midmidPoint origin:self.middle];
		polar.r = (- self.theDocument.thickenedCorner + 1.0) / 2.0 * polar.r ; 
		NSPoint middleMidmidPoint = [self pointForPolarPoint:polar origin:self.middle];
		lineStart = NSMakePoint(middleMidmidPoint.x - cos(phi) * lineHandleWidth,
								middleMidmidPoint.y - sin(phi) * lineHandleWidth);
		lineEnd = NSMakePoint(middleMidmidPoint.x + cos(phi) * lineHandleWidth,
							  middleMidmidPoint.y + sin(phi) * lineHandleWidth);
		
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
		[handleColor set];
		[bP stroke];
	}
	

	// anchor points on top
	bP = [NSBezierPath bezierPath];
	[pointColor set];
	
	// a diamond for the mid point
	CGFloat pSize = POINTSIZE * sqrt(2);
	[bP moveToPoint:NSMakePoint(self.midPoint.x + 0.5 * pSize, self.midPoint.y)];
	[bP lineToPoint:NSMakePoint(self.midPoint.x, self.midPoint.y + 0.5 * pSize)];
	[bP lineToPoint:NSMakePoint(self.midPoint.x - 0.5 * pSize, self.midPoint.y)];
	[bP lineToPoint:NSMakePoint(self.midPoint.x, self.midPoint.y - 0.5 * pSize)];
	[bP closePath];
	rect = [bP bounds];
	rect.origin.x = round(rect.origin.x);
	rect.origin.y = round(rect.origin.y);
	rect.size.width = round(rect.size.width);
	rect.size.height = round(rect.size.height);
	self.midPointTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"midPoint" forKey:@"name"]];
	[self addTrackingArea:self.midPointTA];
	
	if (self.clickedPointName && self.theDocument.twoMidPoints) {
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
	self.endPointTA = [[NSTrackingArea alloc] initWithRect:rect options:TAoptions owner:self userInfo:[NSDictionary dictionaryWithObject:@"endPoint" forKey:@"name"]];
	[self addTrackingArea:self.endPointTA];
	[bP fill];

	
	if (self.useCoreAnimation) {
		[image unlockFocus];
		// put into layer	
		CGImageRef imageRef = [image cgImage];
		[CATransaction begin];
		[CATransaction setValue:[NSNumber numberWithFloat:0.0f] forKey:kCATransactionAnimationDuration];
		self.handleLayer.contents = (id) imageRef;
		self.handleLayer.opacity = 1.0;
		[CATransaction commit];
		CGImageRelease(imageRef);	
	}	
	else {
		self.handleLayer.opacity = 0.0;
	}
	// debugging -- draw trackingareas' rects when caps lock is pressed
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
}



- (void)drawRect:(NSRect)rect {
	// NSLog(@"-drawRect:");
	
	NSBezierPath * thePath = [NSBezierPath bezierPathWithDictionary:theDocument.dictionary size:self.shapeRadius];	
	[thePath transformUsingAffineTransform:self.moveToMiddle]; 
	[self setValue:thePath forKey:@"path"];
	
	// draw
	[theDocument.backgroundColor set];
	NSRectFill(self.bounds);
	if (theDocument.twoLines) {
		[theDocument.fillColor set];
		[thePath fill];
	}
	[theDocument.strokeColor set];
	[thePath setLineWidth: theDocument.strokeThickness * self.canvasRadius / 10.0];
	[thePath stroke];
		
	// draw handles and guides
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
}


- (void) drawPoint: (NSPoint) pt {
	[[NSColor orangeColor] set];
	NSRect myRect = NSMakeRect(pt.x - 2.0, pt.y -2.0, 4.0, 4.0);
	[NSBezierPath fillRect:myRect];
}


	

#pragma mark MOUSE TRACKING

- (NSString*) trackingAreaNameForMouseLocation {
	NSPoint mouseLocation = [self convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];
	//	NSLog (@"mouse: %f, %f", mouseLocation.x, mouseLocation.y);

	if ([self point:mouseLocation inRect:[self.endPointTA rect]]) {
		return @"endPoint";
	}
	else if ([self point:mouseLocation inRect:[self.endHandleTA rect]]) {
		return @"endHandle";
	}
	else if ([self point:mouseLocation inRect:[self.midPointTA rect]]) {
		return @"midPoint";
	}
	else if ([self point:mouseLocation inRect:[self.midHandleTA rect]]) {
		return @"midHandle";											
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
	Set the mouse cursor to be open hand inside one of the tracking areas and arrow outside them
*/
- (void) updateCursor {
	NSString * TAName = [self trackingAreaNameForMouseLocation];

	if (TAName) {
		[[NSCursor openHandCursor] set];
	}
	else {
		[[NSCursor arrowCursor] set];
	}
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
	return [[[NSUserDefaults standardUserDefaults] valueForKey:@"useCoreAnimation"]boolValue];
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
