//
//  MyDocument+Animation.m
//  Symmetries
//
//  Created by  Sven on 29.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "MyDocument+Animation.h"
#import "ESSymmetryTotalAnimation.h"
#import "ESSymmetryView.h"

@implementation MyDocument (Animation)

@dynamic runningAnimation;



#pragma mark ANIMATION


- (IBAction) animate: (id) sender {
	// NSLog(@"[MyDocument animate:]");
	if (!self.runningAnimation) {
		// start animation if it's not running
		self.totalAnimation = [[ESSymmetryTotalAnimation alloc] initWithDuration: MAXFLOAT animationCurve: NSAnimationLinear];
		self.totalAnimation.valueObject = self;
		self.totalAnimation.delegate = self;
		self.totalAnimation.animationBlockingMode = NSAnimationNonblocking;
	
		for (NSString * key in [self animationKeys]) {
			[self.totalAnimation addProperty:key];
		}
	
		[self.totalAnimation startAnimation];	
	}
	else {
		[self stopAnimation:sender];
	}
}


- (IBAction) spaceOut: (id) sender {
	self.myView.spaceOut = YES;
	[self animate:sender];
}


- (IBAction) stopAnimation: (id) sender {
	// NSLog(@"[MyDocument stopAnimation:]");
	[self.totalAnimation stopAnimation];
	self.totalAnimation = nil;
	if (self.myView.spaceOut) {
		self.myView.spaceOut = NO;
		[self.myView setNeedsDisplay:YES];
	}
}


- (NSDictionary*) fullScreenModeDictionary {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:NO], NSFullScreenModeAllScreens,
			nil];		
}


- (IBAction) animateFullScreen: (id) sender {
	[self animate:sender];
	// [self.myView enterFullScreenMode:[NSScreen mainScreen] withOptions:[self fullScreenModeDictionary]];
}




#pragma mark HELPER METHODS


- (NSArray*) animationKeys {
	return [NSArray arrayWithObjects: @"size", @"cornerCount", @"cornerFraction", @"straightTangentLength", @"straightTangentDirection", @"diagonalTangentLength", @"diagonalTangentDirection", @"midPointsDistance", @"thickness", @"thickenedCorner", @"rotation", nil];
	// twoLines, strokeThickness left out
}


/* 
	Delegate method for ESSymmetryTotalAnimation
*/
- (NSDictionary *) valueRangeForKey: (NSString *) key currentValue: (CGFloat) currentValue {
	CGFloat min = 0.0;
	CGFloat max = 1.0;
	
	/* Use standard 0-1 range for
	 straightTangentLength, diagonalTangentLength
	*/
	
	if ([key isEqualToString:@"size"]) {
		min = 0.3;
		max = 1.0;
	}	
	else if ([key isEqualToString:@"cornerCount"]) {
		min = self.cornerCount - 0.02;
		max = self.cornerCount + 1.02 ;
		// NSLog(@"newCornerTarget: %f - %f", min, max); 
	}
	else if ([key isEqualToString:@"cornerFraction"]) {
		min = 0.0;
		max = 1.41;
	}
	else if (	[key isEqualToString:@"straightTangentDirection"]
			 || [key isEqualToString:@"diagonalTangentDirection"] ) {
		min = currentValue - 3.0 * M_PI;
		max = currentValue + 3.0 * M_PI;
	}
	else if ([key isEqualToString:@"rotation"]) {
		min = currentValue - 1.5 * M_PI;
		max = currentValue + 1.5 * M_PI;
	}	
	else if (	[key isEqualToString:@"midPointsDistance"]
			 || [key isEqualToString:@"thickness"]
			 || [key isEqualToString:@"thickenedCorner"]) {
		min = -1.0;
		max = 1.0;
	}
	else {
		return nil;
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithFloat: min], @"minValue",
			[NSNumber numberWithFloat: max], @"maxValue", nil];
}





/*
 NSAnimation delegate
*/
/*
 - (void)animationDidEnd:(ESSymmetryTotalAnimation *)animation {
 }
*/




@end
