//
//  ESSymmetryView+Intro.m
//  Symmetries
//
//  Created by  Sven on 27.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "ESSymmetryView+Intro.h"
#import "ESSymmetryAnimation.h"
#import "AppDelegate.h"

@interface NSView (AnimationDelegate)
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
@end


@implementation ESSymmetryView (Intro)

#pragma mark INTRO

- (void) intro {
	// NSLog(@"[ESSymmetryView intro]");

	self.introLayer.opacity = 1.0;
	[self.introLayer setNeedsDisplay];
	
	CAKeyframeAnimation * myAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
	myAnimation.keyTimes = @[@0.0f, @0.8f, @1.0f];
	myAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear],
								   [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
	myAnimation.values = @[@1.0f, @1.0f, @0.0f];
	myAnimation.delegate = self;
	myAnimation.duration = 4.0 + 6.0 / [[NSUserDefaults standardUserDefaults] floatForKey:ESSYM_LAUNCHCOUNT_KEY];
	myAnimation.removedOnCompletion = NO;
	myAnimation.fillMode = kCAFillModeForwards;
	[self.introLayer addAnimation:myAnimation forKey:@"textFadeOut"];	
}



- (NSAttributedString*) introString {
	NSAttributedString * aS;

	if ([[NSUserDefaults standardUserDefaults] integerForKey:ESSYM_LAUNCHCOUNT_KEY] > 8) {
		aS = (self.stringsFromFile)[1];
	}
	else {
		aS = (self.stringsFromFile)[0];
	}
	
	return aS;
}




#pragma mark DRAWING

- (void) drawLayerWithAttributedString:(NSAttributedString *)aS inContext:(CGContextRef)ctx {
	
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
	// NSLog(@"[ESSymmetryView+Intro startDemo:]");
	
	// If demo is already running, stop it -- this shouldn't happen
	if (self.currentDemoStep >= 0) {
		// NSLog(@"[ESSymmetryView+Intro startDemo:] demo already running! stopping it.");
		[self endDemo:nil];
		return;
	}
	
	// make sure menu item is changed
	AppDelegate * aD = [NSApplication sharedApplication].delegate;
	[aD demoStarted];
	
	// store previous values
	self.preAnimationDocumentValues = self.theDocument.dictionary;
	
	// make sure Welcome Layer is hidden
	[self.introLayer removeAllAnimations];
	[CATransaction begin];
	[CATransaction setValue:@0.1f forKey:kCATransactionAnimationDuration];
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
	// NSLog(@"[ESSymmetryView+Intro endDemo:]");
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
	
	// restore demo menu item
	AppDelegate * ad = [NSApplication sharedApplication].delegate;
	[ad demoStopped];
}


- (void) nextDemoStep {
	[self gotoDemoStep: self.currentDemoStep + 1];
}


- (void) gotoDemoStep: (NSUInteger) nr {
	// NSLog(@"[ESSymmetryView+Intro gotoDemoStep:%i]", nr);
	NSArray * sublayers = self.demoLayer.sublayers;
	NSUInteger demoSteps = sublayers.count;
	
	for (NSUInteger i = 0; i < demoSteps; i++) {
		// go through all pages
		if ( i > MIN(nr -1, self.currentDemoStep - 1) || i < MAX(nr + 1, self.currentDemoStep + 1) ) {
			// page needs to be moved
			CALayer * page = sublayers[i];
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
			animation.startValues = @{
									  @"size": [NSNumber numberWithFloat:self.theDocument.size],
									  @"straightTangentDirection": [NSNumber numberWithFloat:self.theDocument.straightTangentDirection],
									  @"diagonalTangentLength": [NSNumber numberWithFloat:self.theDocument.diagonalTangentLength],
									  @"thickness": [NSNumber numberWithFloat: self.theDocument.thickness],
									  @"midPointsDistance": [NSNumber numberWithFloat: self.theDocument.midPointsDistance]
									  };
			
			animation.targetValues = @{
									   @"size": @0.6f,
									   @"straightTangentDirection": [NSNumber numberWithFloat:self.theDocument.straightTangentDirection + 2.7*M_PI],
									   @"diagonalTangentLength": @0.5f,
									   @"thickness": @0.2f,
									   @"midPointsDistance": @0.3f
									   };

			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:3.5 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = @{
									   @"cornerCount": [NSNumber numberWithFloat:self.theDocument.cornerCount],
									   @"straightTangentLength": [NSNumber numberWithFloat:self.theDocument.straightTangentLength],
									   @"diagonalTangentDirection": [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection],
									   @"thickenedCorner": [NSNumber numberWithFloat: self.theDocument.thickenedCorner],
									   @"cornerFraction": [NSNumber numberWithFloat: self.theDocument.cornerFraction]
									   };
			
			animation2.targetValues = @{
										@"cornerCount": @5,
									    @"straightTangentLength": @0.3f,
									    @"diagonalTangentDirection": [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection - 2.5*M_PI],
									    @"thickenedCorner": @0.3f,
									    @"cornerFraction": @0.71f
										};
			
			[animation startAnimation];
			[animation2 startWhenAnimation:animation reachesProgress:0.8];
			animation2.delegate = self;
			
			self.lastAnimations = @[animation, animation2];
			
			break;
		}
		
		case 1: // Start Point: corner count
		{ 
			animation  = [[ESSymmetryAnimation alloc] initWithDuration:2.5 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = @{@"cornerCount": @(self.theDocument.cornerCount)};
			animation.targetValues = @{@"cornerCount": @(self.theDocument.cornerCount)};
			
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:2.0 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = @{@"cornerCount": @(self.theDocument.cornerCount)};
			animation2.targetValues = @{@"cornerCount": @2};
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:5.0 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = @{@"cornerCount": @2};
			animation3.targetValues = @{@"cornerCount": @37};
			
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:3.5 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = @{@"cornerCount": @37};
			animation4.targetValues = @{@"cornerCount": @5};

			
			[animation startAnimation];
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation4 startWhenAnimation:animation3 reachesProgress:1.0];
			animation4.delegate = self;

			self.lastAnimations = @[animation, animation2, animation3, animation4];
			break;
		}
			
		case 2: { // Start Point: size direction
			animation = [[ESSymmetryAnimation alloc] initWithDuration:2.0 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = @{@"size": [NSNumber numberWithFloat:self.theDocument.size]};
			animation.targetValues = @{@"size": @1.0f};
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:5.0 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = @{@"size": @1.0f};
			animation2.targetValues = @{@"size": @0.01f};
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:3.5 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = @{@"size": @0.01f}; 
			animation3.targetValues = @{@"size": @0.7f};
			
			
			[animation startAnimation];
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			animation3.delegate = self;
			
			self.lastAnimations = @[animation, animation2, animation3];
			break;		
		}
			
		case 3:	// Mid point: cornerFraction axis
		{  
			animation = [[ESSymmetryAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = @{@"cornerFraction": [NSNumber numberWithFloat:self.theDocument.cornerFraction]};
			animation.targetValues = @{@"cornerFraction": [NSNumber numberWithFloat: self.theDocument.cornerFraction]};
			
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:1.0 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = @{@"cornerFraction": [NSNumber numberWithFloat:self.theDocument.cornerFraction]};
			animation.targetValues = @{@"cornerFraction": @1.0f};
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:2.5 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = @{@"cornerFraction": @1.0f};
			animation3.targetValues = @{@"cornerFraction": @-1.0f};
						
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:2.5 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = @{@"cornerFraction": @-1.0f};
			animation4.targetValues = @{@"cornerFraction": @0.71f};
			
			
			[animation startAnimation];
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation4 startWhenAnimation:animation3 reachesProgress:1.0];
			animation4.delegate = self;
			
			self.lastAnimations = @[animation, animation2, animation3, animation4];
			
			break;
		}
						
		case 4: // Mid point: midPointsDistance axis
		{ 
			animation = [[ESSymmetryAnimation alloc] initWithDuration:0.5 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = @{@"midPointsDistance": [NSNumber numberWithFloat:self.theDocument.midPointsDistance]};
			animation.targetValues = @{@"midPointsDistance": @1.0f};
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:1.2 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = @{@"midPointsDistance": @1.0f};
			animation2.targetValues = @{@"midPointsDistance": @0.0f};
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:0.5 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = @{@"midPointsDistance": @0.0f};
			animation3.targetValues = @{@"midPointsDistance": @0.0f};
		
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:1.2 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = @{@"midPointsDistance": @0.0f};
			animation4.targetValues = @{@"midPointsDistance": @-1.0f};
			
			animation5 = [[ESSymmetryAnimation alloc] initWithDuration:1.7 animationCurve:NSAnimationEaseInOut];
			animation5.valueObject = self.theDocument;
			animation5.animationBlockingMode = NSAnimationNonblocking;
			animation5.startValues = @{@"midPointsDistance": @-1.0f};
			animation5.targetValues = @{@"midPointsDistance": @0.3f};
			
			[animation startAnimation];
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation4 startWhenAnimation:animation3 reachesProgress:1.0];
			[animation5 startWhenAnimation:animation4 reachesProgress:1.0];
			animation5.delegate = self;
			
			self.lastAnimations = @[animation, animation2, animation3, animation4, animation5];

			break;
		}			
						
		case 5: // End point Handle: Rotate and resize a bit
		{ 
			animation = [[ESSymmetryAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = @{@"straightTangentDirection": [NSNumber numberWithFloat:self.theDocument.straightTangentDirection]};
			animation.targetValues = @{@"straightTangentDirection": [NSNumber numberWithFloat: self.theDocument.straightTangentDirection]};

			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:5.0 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = @{@"straightTangentDirection": [NSNumber numberWithFloat:self.theDocument.straightTangentDirection], 
									  @"straightTangentLength": [NSNumber numberWithFloat:self.theDocument.straightTangentLength]};
			animation2.targetValues = @{@"straightTangentDirection": [NSNumber numberWithFloat: self.theDocument.straightTangentDirection + 2.5 * M_PI],  
									   @"straightTangentLength": @0.85f};
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:1.2 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = @{@"straightTangentLength": @0.85f};
			animation3.targetValues = @{@"straightTangentLength": @1.0f};
			
			[animation startAnimation];
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			animation3.delegate = self;

			self.lastAnimations = @[animation, animation2, animation3];

			break;
		}
						
		case 6: // Mid point Handle: Rotate and resize a bit
		{
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = @{@"diagonalTangentLength": [NSNumber numberWithFloat:self.theDocument.diagonalTangentLength], 
									  @"straightTangentDirection": [NSNumber numberWithFloat:self.theDocument.straightTangentDirection + 2.5 * M_PI],
									 @"diagonalTangentDirection": [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection]};
			animation2.targetValues = @{@"diagonalTangentLength": @0.0f,  
									   @"straightTangentDirection": [NSNumber numberWithFloat:self.theDocument.straightTangentDirection + 1.0],
									 @"diagonalTangentDirection": [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection - M_PI]};
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:3.5 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = @{@"diagonalTangentLength": @0.0f, 
									  @"straightTangentLength": @1.0f, 
									  @"straightTangentDirection": [NSNumber numberWithFloat:self.theDocument.straightTangentDirection + 1.0],
									  @"diagonalTangentDirection": [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection - M_PI]};
			animation3.targetValues = @{@"diagonalTangentLength": @1.0f, 
									   @"straightTangentLength": @0.0f, 
									  @"straightTangentDirection": [NSNumber numberWithFloat:self.theDocument.straightTangentDirection],
									   @"diagonalTangentDirection": [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection - 4.0 * M_PI]};
			
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:3.8 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = @{@"diagonalTangentLength": @1.0f, 
									 @"straightTangentLength": @0.0f, 
									  @"diagonalTangentDirection": [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection - 4.0 * M_PI]};
			animation4.targetValues = @{@"diagonalTangentLength": @0.3f, 
									  @"straightTangentLength": @0.2f, 
									   @"diagonalTangentDirection": [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection - 3.0 * M_PI]};
			
			
			[animation2 startAnimation];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation4 startWhenAnimation:animation3 reachesProgress:1.0];
			animation4.delegate = self;
			
			self.lastAnimations = @[animation2, animation3, animation4];

			break;
		}

		case 7: // Thickness
		{ 
			animation = [[ESSymmetryAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = @{@"thickness": [NSNumber numberWithFloat:self.theDocument.thickness]};
			animation.targetValues = @{@"thickness": @0.0f};
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:1.0 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = @{@"thickness": @0.0f};
			animation2.targetValues = @{@"thickness": @1.0f};
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:2.0 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = @{@"thickness": @1.0f};
			animation3.targetValues = @{@"thickness": @-1.0f};
			
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:1.2 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = @{@"thickness": @-1.0f};
			animation4.targetValues = @{@"thickness": @0.25f};
			
			[animation startAnimation];
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation4 startWhenAnimation:animation3 reachesProgress:1.0];
			animation4.delegate = self;

			self.lastAnimations = @[animation, animation2, animation3, animation4];

			break;
		}			
			
		case 8: // Taperedness 
		{ 
			animation = [[ESSymmetryAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = @{@"thickenedCorner": [NSNumber numberWithFloat:self.theDocument.thickenedCorner]};
			animation.targetValues = @{@"thickenedCorner": @0.0f};
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:1.0 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = @{@"thickenedCorner": @0.0f};
			animation2.targetValues = @{@"thickenedCorner": @1.0f};
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:2.0 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = @{@"thickenedCorner": @1.0f};
			animation3.targetValues = @{@"thickenedCorner": @-1.0f};
			
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:1.2 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = @{@"thickenedCorner": @-1.0f};
			animation4.targetValues = @{@"thickenedCorner": @0.2f};
			
			[animation startAnimation];
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation4 startWhenAnimation:animation3 reachesProgress:1.0];
			animation4.delegate = self;

			self.lastAnimations = @[animation, animation2, animation3, animation4];
			
			break;
		}			
			
		case 9: // Two Lines 
		{ 
			animation = [[ESSymmetryAnimation alloc] initWithDuration:1.2 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = @{@"twoLines": @(self.theDocument.twoLines)};
			animation.targetValues = @{@"twoLines": @YES};
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = @{@"twoLines": @YES};
			animation2.targetValues = @{@"twoLines": @NO};
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:1.5 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = @{@"twoLines": @NO};
			animation3.targetValues = @{@"twoLines": @YES};
			
			[animation startAnimation];
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			animation3.delegate = self;

			self.lastAnimations = @[animation, animation2, animation3];

			break;
		}			
			
		case 10: // Two Mid Points
		{ 
			animation = [[ESSymmetryAnimation alloc] initWithDuration:4.5 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = @{@"twoMidPoints": @YES};
			animation.targetValues = @{@"twoMidPoints": @YES};
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:2.0 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = @{@"twoMidPoints": @YES};
			animation2.targetValues = @{@"twoMidPoints": @NO};
			
			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:2.5 animationCurve:NSAnimationEaseInOut];
			animation3.valueObject = self.theDocument;
			animation3.animationBlockingMode = NSAnimationNonblocking;
			animation3.startValues = @{@"twoMidPoints": @NO};
			animation3.targetValues = @{@"twoMidPoints": @YES};
			
			animation4 = [[ESSymmetryAnimation alloc] initWithDuration:9.0 animationCurve:NSAnimationEaseInOut];
			animation4.valueObject = self.theDocument;
			animation4.animationBlockingMode = NSAnimationNonblocking;
			animation4.startValues = @{@"diagonalTangentDirection": [NSNumber numberWithFloat: self.theDocument.diagonalTangentDirection], 
									  @"diagonalTangentLength": [NSNumber numberWithFloat: self.theDocument.diagonalTangentLength]};
			animation4.targetValues = @{@"diagonalTangentDirection": [NSNumber numberWithFloat: self.theDocument.diagonalTangentDirection + 2.3 * M_PI], 
									   @"diagonalTangentLength": @0.25f};
			
			
			[animation startAnimation];
			animation.delegate = self; // triggers page 11 after 4.5s
			[animation2 startWhenAnimation:animation reachesProgress:1.0];
			[animation3 startWhenAnimation:animation2 reachesProgress:1.0];
			[animation4 startAnimation];
			animation4.delegate = self; // triggers page 12 !
			
			self.lastAnimations = @[animation, animation2, animation3, animation4];

			break;
		}			
			
		case 12: // Final page. Dabble around a little, then return to user's old values
		{
			animation = [[ESSymmetryAnimation alloc] initWithDuration:4.0 animationCurve:NSAnimationEaseInOut];
			animation.valueObject = self.theDocument;
			animation.animationBlockingMode = NSAnimationNonblocking;
			animation.startValues = @{
									  @"size": [NSNumber numberWithFloat:self.theDocument.size],
									  @"straightTangentDirection": [NSNumber numberWithFloat:self.theDocument.straightTangentDirection],
									  @"diagonalTangentLength": [NSNumber numberWithFloat:self.theDocument.diagonalTangentLength],
									  @"thickness": [NSNumber numberWithFloat: self.theDocument.thickness],
									  @"midPointsDistance": [NSNumber numberWithFloat: self.theDocument.midPointsDistance]
									  };
			
			animation.targetValues = @{
									   @"size": @0.6f,
									   @"straightTangentDirection": [NSNumber numberWithFloat:self.theDocument.straightTangentDirection - 6 * M_PI],
									   @"diagonalTangentLength": @0.2f,
									   @"thickness": @0.2f,
									   @"midPointsDistance": @0.3f
									   };
			
			animation2 = [[ESSymmetryAnimation alloc] initWithDuration:3.5 animationCurve:NSAnimationEaseInOut];
			animation2.valueObject = self.theDocument;
			animation2.animationBlockingMode = NSAnimationNonblocking;
			animation2.startValues = @{
									   @"cornerCount": [NSNumber numberWithFloat:self.theDocument.cornerCount],
									   @"straightTangentLength": [NSNumber numberWithFloat:self.theDocument.straightTangentLength],
									   @"diagonalTangentDirection": [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection],
									   @"thickenedCorner": [NSNumber numberWithFloat: self.theDocument.thickenedCorner],
									   @"cornerFraction": [NSNumber numberWithFloat: self.theDocument.cornerFraction]
									   };
			
			animation2.targetValues = @{
										@"cornerCount": [self.preAnimationDocumentValues valueForKey:@"cornerCount"],
									    @"straightTangentLength": @0.3f,
									    @"diagonalTangentDirection": [NSNumber numberWithFloat:self.theDocument.diagonalTangentDirection + 3.5 * M_PI],
									    @"thickenedCorner": @0.3f,
									    @"cornerFraction": @0.71f
										};
			

			animation3 = [[ESSymmetryAnimation alloc] initWithDuration:3.5 animationCurve:NSAnimationEaseInOut];
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
			animation3.delegate = self;

			self.lastAnimations = @[animation, animation2, animation3];
			
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
	BOOL hasDrawn = NO;
	
	[NSGraphicsContext saveGraphicsState];
	NSGraphicsContext * graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO];
	[NSGraphicsContext setCurrentContext:graphicsContext];

	if ([layer.name isEqualToString: @"introLayer"] ) {
		[self drawLayerWithAttributedString:self.introString inContext:ctx];
		hasDrawn = YES;
	} 
	else if ([layer.name hasPrefix:@"demo.page"]) {
		// need to draw for demo
		// NSLog(@"-drawLayer: %@ (%f, %f, %f, %f - %f, %f)", layer.name, layer.bounds.origin.x, layer.bounds.origin.y, layer.bounds.size.width, layer.bounds.size.height, layer.position.x, layer.position.y);
		NSUInteger layerNumber = [layer.name componentsSeparatedByString:@"-"].lastObject.intValue;
		[self drawLayerWithAttributedString:(self.stringsFromFile)[layerNumber + 2] inContext:ctx];
		hasDrawn = YES;
	}

	[NSGraphicsContext restoreGraphicsState];
	
	if(!hasDrawn) {
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
		NSString * separator = @"\012\342\231\253\012\000";
		NSArray * strings = [text componentsSeparatedByString:separator];
		
		NSMutableArray * attributedStrings = [NSMutableArray arrayWithCapacity:strings.count];
		NSInteger firstIndex = 0;
		for (NSString * s in strings) {
			NSRange range = NSMakeRange(firstIndex, s.length);
			firstIndex = firstIndex + s.length + 3;
			[attributedStrings addObject:[aS attributedSubstringFromRange:range]];
		}
		stringsFromFile = attributedStrings;
	}
	return stringsFromFile;
}



@end
