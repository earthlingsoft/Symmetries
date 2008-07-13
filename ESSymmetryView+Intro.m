//
//  ESSymmetryView+Intro.m
//  Symmetries
//
//  Created by  Sven on 27.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "ESSymmetryView+Intro.h"
#import "ESSymmetryAnimation.h"

@implementation ESSymmetryView (Intro)

#pragma mark INTRO

- (void) intro {
	// NSLog(@"[ESSymmetryView intro]");

	self.introLayer.opacity = 1.0;
	[self.introLayer setNeedsDisplay];
	
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
	myAnimation.duration = 7.0;
	myAnimation.removedOnCompletion = NO;
	myAnimation.fillMode = kCAFillModeForwards;
	[self.introLayer addAnimation:myAnimation forKey:@"textFadeOut"];	
}



- (NSAttributedString*) introString {
	return [self.stringsFromFile objectAtIndex:0];
}




#pragma mark DRAWING

- (void) drawLayerWithAttributedString: (NSAttributedString *) aS inContext:(CGContextRef)ctx {
	
	NSSize windowMinSize = NSMakeSize(600.0, 581.0); // self.window.minSize;
	NSSize windowSize = self.window.frame.size;
	NSRect stringRect = NSMakeRect((windowSize.width - windowMinSize.width) /2.0 + 32.0 , 32.0, windowMinSize.width - 64.0, aS.size.height + 32.0);
	NSBezierPath * bP = [NSBezierPath bezierPathWithRoundedRect:stringRect xRadius:16.0 yRadius:16.0];
	[[NSColor colorWithDeviceWhite:0.3 alpha:0.8] set];
	[bP fill];
	[[NSColor colorWithDeviceWhite:0.1 alpha:0.9] set];
	bP.lineWidth = 6.0;
	[bP stroke];
	stringRect.origin.y -= 12.0;
	
	NSMutableAttributedString * mAS = [aS mutableCopy];
	[mAS addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithDeviceWhite:0.9 alpha:0.9] range: NSMakeRange(0, mAS.string.length)];	
	[mAS drawInRect:stringRect];
}






#pragma mark DEMO
#define DEMOPAGECOUNT 13

- (void) startDemo:(id) sender {
	NSLog(@"-startDemo:");
	
	// If demo is already running, stop it
	if (self.currentDemoStep >= 0) {
		[self endDemo:nil];
		return;
	}
	
	// store previous values
	self.preAnimationDocumentValues = self.theDocument.dictionary;
	
	// make sure Welcome Layer is hidden
	[self.introLayer removeAllAnimations];
	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:0.1] forKey:kCATransactionAnimationDuration];
	self.introLayer.opacity = 0.0;
	[CATransaction commit];
	
	
	// Set up necessary things in the document
	self.theDocument.showHandles = 1;
	self.theDocument.twoLines = YES;
	
	// set up layers if necessary
	if (!self.demoLayer) {
		CALayer * newLayer;
	
		newLayer = [CALayer layer];
		newLayer.name = @"demoLayer";
		newLayer.delegate = self;
		newLayer.opacity = 1.0;
		newLayer.contentsGravity = kCAGravityResize;
		newLayer.position = CGPointMake(self.layer.bounds.size.width/2.0, self.layer.bounds.size.height/2.0);
		[self.layer addSublayer: newLayer];
		self.demoLayer = newLayer;
				
		for (int i = 0; i < DEMOPAGECOUNT; i++) { 
			newLayer = [CALayer layer];
			newLayer.name = [@"demo.page-" stringByAppendingFormat:@"%i", i];
			newLayer.delegate = self;
			newLayer.opacity = 1.0;
			newLayer.contentsGravity = kCAGravityBottom;
			newLayer.bounds = NSRectToCGRect(self.bounds);
			newLayer.position = CGPointMake( self.layer.bounds.size.width, 0.0);
			[newLayer setNeedsDisplay];
			
			CAConstraint * constraint;
			constraint = [CAConstraint constraintWithAttribute:kCAConstraintMidX relativeTo:@"superlayer" attribute:kCAConstraintMidX];
			[newLayer addConstraint:constraint];
			constraint = [CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMinY];
			[newLayer addConstraint:constraint];			
			[self.demoLayer addSublayer: newLayer];
		}
	}
		
	[self gotoDemoStep:0];
}


- (void) endDemo: (id) sender {
	NSLog(@"-endDemo:");
	// clean up whatever may need to be cleaned up
	for (NSAnimation* animation in self.lastAnimations) {
		if (animation.isAnimating) {
			[animation stopAnimation];
		}
	}
	self.currentDemoStep = -1;
	[self.demoLayer removeFromSuperlayer];
	self.demoLayer = nil;
	if (! [self.theDocument.dictionary  isEqualToDictionary:self.preAnimationDocumentValues] ) {
		ESSymmetryAnimation * animation = [[ESSymmetryAnimation alloc] initWithDuration:0.3 animationCurve:NSAnimationEaseInOut];
		animation.valueObject = self.theDocument;
		animation.animationBlockingMode = NSAnimationNonblocking;
		animation.startValues = self.theDocument.dictionary;
		animation.targetValues = self.preAnimationDocumentValues;
		
		[animation startAnimation];
	}

}


- (void) nextDemoStep {
	[self gotoDemoStep: self.currentDemoStep + 1];
}


- (void) gotoDemoStep: (NSUInteger) nr {
	NSLog(@"[ESSymmetryView+Intro gotoDemoStep:%i]", nr);
	NSArray * sublayers = self.demoLayer.sublayers;
	NSUInteger demoSteps = sublayers.count;
	
	for (NSUInteger i = 0; i < demoSteps; i++) {
		// go through all pages
		if ( i > MIN(nr -1, self.currentDemoStep - 1) || i < MAX(nr + 1, self.currentDemoStep + 1) ) {
			// page needs to be moved
			CALayer * page = [sublayers objectAtIndex: i];
			if (i < nr) { // pages going to the left
				page.position = CGPointMake(-self.layer.bounds.size.width, 0.0);
			}
			else if ( i == nr ) { // displayed page
				page.position = CGPointMake(0.0,0.0);
			}
			else if ( i > nr ) {
				page.position = CGPointMake(self.layer.bounds.size.width, 0.0);
			}
		}
	}
	
	if (nr >= demoSteps) {
		// we're past the last step => clean up and bail out
		[self endDemo:nil];
		return;
	}
	else {
		self.currentDemoStep = nr;
	}
	
	// animate a bit
	
	ESSymmetryAnimation * animation;
	ESSymmetryAnimation * animation2;
	ESSymmetryAnimation * animation3; 	
	ESSymmetryAnimation * animation4;	
	ESSymmetryAnimation * animation5;
	
	switch (self.currentDemoStep) {
		case 0: // Intro: animate to a reasonable size with some fiddling on the way
		{ 
			animation = [[ESSymmetryAnimation alloc] initWithDuration:5.0 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithFloat:self.theDocument.size], 
									 @"size",
									 [NSNumber numberWithFloat:self.theDocument.straightTangentDirection], 
									 @"straightTangentDirection",
									 [NSNumber numberWithFloat:self.theDocument.diagonalTangentLength], 
									 @"diagonalTangentLength",
									 [NSNumber numberWithFloat: self.theDocument.thickness],
									 @"thickness",
									 [NSNumber numberWithFloat: self.theDocument.midPointsDistance],
									 @"midPointsDistance",
									 nil];
			
			animation.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat:0.6], 
									  @"size",
									  [NSNumber numberWithFloat:self.theDocument.straightTangentDirection + 2.7* pi], 
									  @"straightTangentDirection",
									  [NSNumber numberWithFloat: 0.5], 
									  @"diagonalTangentLength",
									  [NSNumber numberWithFloat:0.2],
									  @"thickness",
									  [NSNumber numberWithFloat: 0.3],
									  @"midPointsDistance",
									  nil];

			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:3.5 animationCurve:NSAnimationEaseInOut];
			animation2.delegate = self;
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithFloat:self.theDocument.cornerCount], 
									 @"cornerCount",
									 [NSNumber numberWithFloat:self.theDocument.straightTangentLength], 
									 @"straightTangentLength",
									 [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection], 
									 @"diagonalTangentDirection",
									 [NSNumber numberWithFloat: self.theDocument.thickenedCorner],
									 @"thickenedCorner",
									 [NSNumber numberWithFloat: self.theDocument.cornerFraction],
									  @"cornerFraction",
									 nil];
			
			animation2.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInt:5], 
									  @"cornerCount",
									  [NSNumber numberWithFloat: 0.3], 
									  @"straightTangentLength",
									  [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection - 2.5*pi], 
									  @"diagonalTangentDirection",
									  [NSNumber numberWithFloat:0.3],
									  @"thickenedCorner",
									   [NSNumber numberWithFloat: 0.71],
									   @"cornerFraction",
									  nil];
			
			[animation2 startWhenAnimation:animation reachesProgress:0.8];
			[animation startAnimation];
			
			self.lastAnimations = [NSArray arrayWithObjects:animation, animation2, nil];
			
			break;
		}
		
		case 1: // Start Point: corner count
		{ 
			animation  = [[ESSymmetryAnimation alloc] initWithDuration:2.5 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithInt:self.theDocument.cornerCount], 
									 @"cornerCount", nil];
			animation.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInt: self.theDocument.cornerCount], 
									  @"cornerCount",  nil];
			
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:2.0 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithInt:self.theDocument.cornerCount], 
									 @"cornerCount", nil];
			animation2.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInt: 2], 
									  @"cornerCount",  nil];
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:5.0 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithInt:2], 
									 @"cornerCount", nil];
			animation3.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInt: 37], 
									  @"cornerCount",  nil];
			
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:3.5 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.delegate = self;
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithInt:37], 
									  @"cornerCount", nil];
			animation4.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithInt: 5], 
									   @"cornerCount", nil];

			
			[animation startAnimation];
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation4 startWhenAnimation:animation3 reachesProgress:1.0];

			self.lastAnimations = [NSArray arrayWithObjects:animation, animation2, animation3, animation4, nil];
			break;
		}
			
		case 2: { // Start Point: size direction
			animation = [[ESSymmetryAnimation alloc] initWithDuration:2.0 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithFloat:self.theDocument.size], 
									 @"size", nil];
			animation.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: 1.0], 
									  @"size",  nil];
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:5.0 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat:1.0], 
									  @"size", nil];
			animation2.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 0.01], 
									   @"size",  nil];
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:3.5 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.delegate = self;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithFloat:0.01], 
									  @"size", nil]; 
			animation3.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 0.7], 
									   @"size", nil];
			
			
			[animation startAnimation];
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			
			self.lastAnimations = [NSArray arrayWithObjects:animation, animation2, animation3, nil];
			break;		
		}
			
		case 3:	// Mid point: cornerFraction axis
		{  
			animation = [[ESSymmetryAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithFloat:self.theDocument.cornerFraction], 
									 @"cornerFraction", nil];
			animation.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: self.theDocument.cornerFraction], 
									  @"cornerFraction",  nil];
			
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:1.0 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithFloat:self.theDocument.cornerFraction], 
									 @"cornerFraction", nil];
			animation.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: 1.0], 
									  @"cornerFraction",  nil];
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:2.5 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithFloat:1.0], 
									  @"cornerFraction", nil];
			animation3.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: -1.0], 
									   @"cornerFraction",  nil];
						
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:2.5 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.delegate = self;
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: -1.0], 
									  @"cornerFraction", 
									  nil];
			animation4.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 0.71], 
									   @"cornerFraction", 
									   nil];
			
			
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation4 startWhenAnimation:animation3 reachesProgress:1.0];
			[animation startAnimation];
			
			self.lastAnimations = [NSArray arrayWithObjects:animation, animation2, animation3, animation4, nil];
			
			break;
		}
						
		case 4: // Mid point: midPointsDistance axis
		{ 
			animation = [[ESSymmetryAnimation alloc] initWithDuration:0.5 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithFloat:self.theDocument.midPointsDistance], 
									 @"midPointsDistance", nil];
			animation.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: 1.0], 
									  @"midPointsDistance",  nil];
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:1.2 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat:1.0], 
									  @"midPointsDistance", nil];
			animation2.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 0.0], 
									   @"midPointsDistance",  nil];
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:0.5 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: 0.0], 
									  @"midPointsDistance", 
									  nil];
			animation3.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 0.0], 
									   @"midPointsDistance", 
									   nil];
		
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:1.2 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: 0.0], 
									  @"midPointsDistance", 
									  nil];
			animation4.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: -1.0], 
									   @"midPointsDistance", 
									   nil];
			
			animation5 = [[ESSymmetryAnimation alloc] initWithDuration:1.7 animationCurve:NSAnimationEaseInOut];
			animation5.valueObject = self.theDocument;
			animation5.delegate = self;
			animation5.animationBlockingMode = NSAnimationNonblocking;
			animation5.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: -1.0], 
									  @"midPointsDistance", 
									  nil];
			animation5.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 0.3], 
									   @"midPointsDistance", 
									   nil];
			
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation4 startWhenAnimation:animation3 reachesProgress:1.0];
			[animation5 startWhenAnimation:animation4 reachesProgress:1.0];
			[animation startAnimation];
			
			self.lastAnimations = [NSArray arrayWithObjects:animation, animation2, animation3, animation4, animation5, nil];

			break;
		}			
						
		case 5: // End point Handle: Rotate and resize a bit
		{ 
			animation = [[ESSymmetryAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithFloat:self.theDocument.straightTangentDirection], 
									 @"straightTangentDirection", nil];
			animation.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: self.theDocument.straightTangentDirection], 
									  @"straightTangentDirection",  nil];

			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:5.0 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.delegate = self;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithFloat:self.theDocument.straightTangentDirection], 
									 @"straightTangentDirection", nil];
			animation2.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: self.theDocument.straightTangentDirection + 2.5 * pi], 
									  @"straightTangentDirection",  nil];
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:1.2 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat:self.theDocument.straightTangentLength], 
									  @"straightTangentLength", nil];
			animation3.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 1.0], 
									   @"straightTangentLength",  nil];
			
			
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:4.5 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: 1.0], 
									  @"straightTangentLength", 
									  nil];
			animation4.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 0.0], 
									   @"straightTangentLength", 
									   nil];
			
			animation5 = [[ESSymmetryAnimation alloc] initWithDuration:3.8 animationCurve:NSAnimationEaseInOut];
			animation5.valueObject = self.theDocument;
			animation5.animationBlockingMode = NSAnimationNonblocking;
			animation5.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: 0.0], 
									  @"straightTangentLength", 
									  nil];
			animation5.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 0.2], 
									   @"straightTangentLength", 
									   nil];
			
			
			[animation startAnimation];
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation reachesProgress:1.0];
			[animation4 startWhenAnimation:animation3 reachesProgress:1.0];
			[animation5 startWhenAnimation:animation4 reachesProgress:1.0];

			self.lastAnimations = [NSArray arrayWithObjects:animation, animation2, animation3, animation4, animation5, nil];

			break;
		}
						
		case 6: // Mid point Handle: Rotate and resize a bit
		{
			animation = [[ESSymmetryAnimation alloc] initWithDuration:5.0 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.delegate = self;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection], 
									 @"diagonalTangentDirection", nil];
			animation.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: self.theDocument.diagonalTangentDirection - 4.0 * pi], 
									  @"diagonalTangentDirection",  nil];
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat:self.theDocument.diagonalTangentLength], 
									  @"diagonalTangentLength", nil];
			animation2.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 0.0], 
									   @"diagonalTangentLength",  nil];
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:3.5 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: 0.0], 
									  @"diagonalTangentLength", 
									  nil];
			animation3.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 1.0], 
									   @"diagonalTangentLength", 
									   nil];
			
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:3.8 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: 1.0], 
									  @"diagonalTangentLength", 
									  nil];
			animation4.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 0.3], 
									   @"diagonalTangentLength", 
									   nil];
			
			
			[animation startAnimation];
			[animation2 startAnimation];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation4 startWhenAnimation:animation3 reachesProgress:1.0];
			
			self.lastAnimations = [NSArray arrayWithObjects:animation, animation2, animation3, animation4, nil];

			break;
		}

		case 7: // Thickness
		{ 
			animation = [[ESSymmetryAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithFloat:self.theDocument.thickness], 
									 @"thickness", nil];
			animation.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: 0.0], 
									  @"thickness",  nil];
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:1.0 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat:0.0], 
									  @"thickness", nil];
			animation2.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 1.0], 
									   @"thickness",  nil];
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:2.0 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: 1.0], 
									  @"thickness", 
									  nil];
			animation3.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: -1.0], 
									   @"thickness", 
									   nil];
			
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:1.2 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.delegate = self;
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: -1.0], 
									  @"thickness", 
									  nil];
			animation4.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 0.25], 
									   @"thickness", 
									   nil];
			
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation4 startWhenAnimation:animation3 reachesProgress:1.0];
			[animation startAnimation];

			self.lastAnimations = [NSArray arrayWithObjects:animation, animation2, animation3, animation4, nil];

			break;
		}			
			
		case 8: // Taperedness 
		{ 
			animation = [[ESSymmetryAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithFloat:self.theDocument.thickenedCorner], 
									 @"thickenedCorner", nil];
			animation.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: 0.0], 
									  @"thickenedCorner",  nil];
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:1.0 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat:0.0], 
									  @"thickenedCorner", nil];
			animation2.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 1.0], 
									   @"thickenedCorner",  nil];
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:2.0 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: 1.0], 
									  @"thickenedCorner", 
									  nil];
			animation3.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: -1.0], 
									   @"thickenedCorner", 
									   nil];
			
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:1.2 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.delegate = self;
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: -1.0], 
									  @"thickenedCorner", 
									  nil];
			animation4.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: 0.2], 
									   @"thickenedCorner", 
									   nil];
			
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation4 startWhenAnimation:animation3 reachesProgress:1.0];
			[animation startAnimation];

			self.lastAnimations = [NSArray arrayWithObjects:animation, animation2, animation3, animation4,  nil];
			
			break;
		}			
			
		case 9: // Two Lines 
		{ 
			animation = [[ESSymmetryAnimation alloc] initWithDuration:1.2 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithBool:self.theDocument.twoLines], 
									 @"twoLines", nil];
			animation.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithBool: YES], 
									  @"twoLines",  nil];
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithBool:YES], 
									  @"twoLines", nil];
			animation2.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithBool: NO], 
									   @"twoLines",  nil];
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.delegate = self;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithBool: NO], 
									  @"twoLines", 
									  nil];
			animation3.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithBool: YES], 
									   @"twoLines", 
									   nil];
			
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation startAnimation];

			self.lastAnimations = [NSArray arrayWithObjects:animation, animation2, animation3, nil];

			break;
		}			
			
		case 10: // Two Mid Points
		{ 
			animation = [[ESSymmetryAnimation alloc] initWithDuration:4.5 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.delegate = self;
			animation.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithBool:YES], 
									 @"twoMidPoints", nil];
			animation.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithBool: YES], 
									  @"twoMidPoints",  nil];
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:2.0 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithBool: YES], 
									  @"twoMidPoints", nil];
			animation2.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithBool: NO], 
									   @"twoMidPoints",  nil];
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:2.5 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithBool: NO], 
									  @"twoMidPoints", 
									  nil];
			animation3.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithBool: YES], 
									   @"twoMidPoints", 
									   nil];
			
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:9.0 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.delegate = self; // timed to trigger after page 10 !
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat: self.theDocument.diagonalTangentDirection], 
									  @"diagonalTangentDirection", 
									  [NSNumber numberWithFloat: self.theDocument.diagonalTangentLength], 
									  @"diagonalTangentLength",
									  nil];
			animation4.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithFloat: self.theDocument.diagonalTangentDirection + 2.3 * pi], 
									   @"diagonalTangentDirection", 
									   [NSNumber numberWithFloat: 0.25], 
									   @"diagonalTangentLength",
									   nil];
			
			
			[animation startAnimation];
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation4 startAnimation];
			
			self.lastAnimations = [NSArray arrayWithObjects:animation, animation2, animation3, nil];

			break;
		}			
			
		case 12: // Final page. Dabble around a little, then return to user's old values
		{
			animation = [[ESSymmetryAnimation alloc] initWithDuration:4.0 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithFloat:self.theDocument.size], 
									 @"size",
									 [NSNumber numberWithFloat:self.theDocument.straightTangentDirection], 
									 @"straightTangentDirection",
									 [NSNumber numberWithFloat:self.theDocument.diagonalTangentLength], 
									 @"diagonalTangentLength",
									 [NSNumber numberWithFloat: self.theDocument.thickness],
									 @"thickness",
									 [NSNumber numberWithFloat: self.theDocument.midPointsDistance],
									 @"midPointsDistance",
									 nil];
			
			animation.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat:0.6], 
									  @"size",
									  [NSNumber numberWithFloat:self.theDocument.straightTangentDirection - 6* pi], 
									  @"straightTangentDirection",
									  [NSNumber numberWithFloat: 0.2], 
									  @"diagonalTangentLength",
									  [NSNumber numberWithFloat:0.2],
									  @"thickness",
									  [NSNumber numberWithFloat: 0.3],
									  @"midPointsDistance",
									  nil];
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:3.5 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat:self.theDocument.cornerCount], 
									  @"cornerCount",
									  [NSNumber numberWithFloat:self.theDocument.straightTangentLength], 
									  @"straightTangentLength",
									  [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection], 
									  @"diagonalTangentDirection",
									  [NSNumber numberWithFloat: self.theDocument.thickenedCorner],
									  @"thickenedCorner",
									  [NSNumber numberWithFloat: self.theDocument.cornerFraction],
									  @"cornerFraction",
									  nil];
			
			animation2.targetValues = [NSDictionary dictionaryWithObjectsAndKeys:
									   [self.preAnimationDocumentValues valueForKey:@"cornerCount"], 
									   @"cornerCount",
									   [NSNumber numberWithFloat: 0.3], 
									   @"straightTangentLength",
									   [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection + 3.5*pi], 
									   @"diagonalTangentDirection",
									   [NSNumber numberWithFloat:0.3],
									   @"thickenedCorner",
									   [NSNumber numberWithFloat: 0.71],
									   @"cornerFraction",
									   nil];
			

			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:3.5 animationCurve:NSAnimationEaseInOut];
			animation3.delegate = self;
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			NSMutableDictionary * dict = [self.theDocument.dictionary mutableCopy];
			[dict addEntriesFromDictionary:animation.targetValues];
			[dict addEntriesFromDictionary:animation2.targetValues];
			animation3.startValues = dict;
			animation3.targetValues = self.preAnimationDocumentValues;
			
			[animation startAnimation];
			[animation2 startWhenAnimation:animation reachesProgress:0.8];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];

			self.lastAnimations = [NSArray arrayWithObjects:animation, animation2, animation3, nil];
			
			break;
		}			
			
			
		default:
			break;
	}
	
}




#pragma mark ANIMATION DELEGATE

- (void)animationDidEnd:(NSAnimation *)animation {
	// NSLog(@"[ESSymmetry animationDidEnd:]");
	[self nextDemoStep];
}



#pragma mark LAYER DELEGATE

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
	// NSLog(@"-drawLayer: %@", layer.name);
	BOOL drew = NO;
	
	[NSGraphicsContext saveGraphicsState];
	NSGraphicsContext * graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO];
	[NSGraphicsContext setCurrentContext:graphicsContext];

	if ([layer.name isEqualToString: @"introLayer"] ) {
		[self drawLayerWithAttributedString:[self introString] inContext:ctx];
		drew = YES;
	} 
	else if ([layer.name hasPrefix:@"demo.page"]) {
		// need to draw for demo
		// NSLog(@"-drawLayer: %@ (%f, %f, %f, %f - %f, %f)", layer.name, layer.bounds.origin.x, layer.bounds.origin.y, layer.bounds.size.width, layer.bounds.size.height, layer.position.x, layer.position.y);
		NSUInteger layerNumber = [[[layer.name componentsSeparatedByString:@"-"] lastObject] intValue];
		[self drawLayerWithAttributedString:[self.stringsFromFile objectAtIndex:layerNumber + 1] inContext:ctx];
		drew = YES;
	}
	else if ([layer.name isEqualToString:@"highlighterLayer"]) {
		CGFloat rectSize = 12.0;
		NSBezierPath * bP = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-rectSize, -rectSize, 2.0 * rectSize, 2.0 * rectSize)];
		bP.lineWidth = 6.0;
		[[NSColor orangeColor] set];
		[bP stroke];
		drew = YES;
	}
	[NSGraphicsContext restoreGraphicsState];
	
	if(!drew) {
		[super drawLayer:layer inContext:ctx];
	}
	
}
		
		

#pragma ATTRIBUTED STRINGS


- (NSArray *) stringsFromFile {
	if (!stringsFromFile) {
		// load strings first
		NSString * stringFilePath = [[NSBundle mainBundle] pathForResource:@"AttributedStrings" ofType:@"rtf"];
		NSAttributedString * aS = [[NSAttributedString alloc] initWithPath:stringFilePath documentAttributes:NULL];
		NSString * text = aS.string;
		NSString * separator = [NSString stringWithUTF8String:"\012\342\231\253\012\000"];
		NSArray * strings = [text componentsSeparatedByString:separator];
		
		NSMutableArray * attributedStrings = [NSMutableArray arrayWithCapacity:[strings count]];
		NSInteger firstIndex = 0;
		for (NSString * s in strings) {
			NSRange range = NSMakeRange(firstIndex, [s length]);
			firstIndex = firstIndex + [s length] + 3;
			[attributedStrings addObject:[aS attributedSubstringFromRange:range]];
		}
		stringsFromFile = attributedStrings;
	}
	return stringsFromFile;
}



@end
