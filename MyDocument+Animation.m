//
//  MyDocument+Animation.m
//  Symmetries
//
//  Created by  Sven on 29.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "MyDocument+Animation.h"
#import "ESSymmetryTotalAnimation.h"

@implementation MyDocument (Animation)

@dynamic runningAnimation;



#pragma mark ANIMATION


- (IBAction) animate: (id) sender {
	// NSLog(@"[MyDocument animate:]");
	self.totalAnimation = [[ESSymmetryTotalAnimation alloc] initWithDuration: MAXFLOAT animationCurve: NSAnimationLinear];
	self.totalAnimation.valueObject = self;
	self.totalAnimation.delegate = self;
	self.totalAnimation.animationBlockingMode = NSAnimationNonblocking;
	
	for (NSString * key in [self animationKeys]) {
		[self.totalAnimation addProperty:key];
	}
	
	[self.totalAnimation startAnimation];	
	
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		((NSMenuItem *) sender).keyEquivalent = @".";
		((NSMenuItem *) sender).keyEquivalentModifierMask = NSCommandKeyMask;
		((NSMenuItem *) sender).action = @selector(stopAnimation:);		
	}	
}


- (IBAction) stopAnimation: (id) sender {
	// NSLog(@"[MyDocument stopAnimation:]");
	[self.totalAnimation stopAnimation];
	self.totalAnimation = nil;
	
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		((NSMenuItem *) sender).keyEquivalent = @"g";
		((NSMenuItem *) sender).keyEquivalentModifierMask = NSCommandKeyMask;
		((NSMenuItem *) sender).action = @selector(animate:);		
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
	return [NSArray arrayWithObjects: @"size", @"cornerCount", @"cornerFraction", @"straightTangentLength", @"straightTangentDirection", @"diagonalTangentLength", @"diagonalTangentDirection", @"midPointsDistance", @"thickness", @"thickenedCorner", nil];
	// twoLines, strokeThickness left out
}


/* 
	Delegate method for ESSymmetryTotalAnimation
*/
- (NSDictionary *) valueRangeForKey: (NSString *) key currentValue: (CGFloat) currentValue {
	CGFloat min = 0.0;
	CGFloat max = 1.0;
	
	/* Use standard 0-1 range for
	 size, straightTangentLength, diagonalTangentLength
	*/
	
	if ([key isEqualToString:@"cornerCount"]) {
		min = MAX( self.cornerCount - MAX(cornerCount / 10, 1.2), 2.0);
		max = MIN( self.cornerCount + MAX(cornerCount / 10, 1.7), MAXCORNERNUMBER);
		// NSLog(@"newCornerTarget: %f - %f", min, max); 
	}
	else if ([key isEqualToString:@"cornerFraction"]) {
		min = 0.0;
		max = 1.41;
	}
	else if (	[key isEqualToString:@"straightTangentDirection"]
			 || [key isEqualToString:@"diagonalTangentDirection"]) {
		min = currentValue - 3.0 * pi;
		max = currentValue + 3.0 * pi;
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
 - (ESSymmetryAnimation *) randomAnimationForKey: (NSString *) key withStartValue: (CGFloat) startValue {
 ESSymmetryAnimation * animation = nil;
 
 if ([key isEqualToString:@"size"]) {
 animation = [self randomAnimationForKey:key withStartValue:startValue targetValueBetween:0.0 and:1.0];
 }
 else if ([key isEqualToString:@"cornerCount"]) {
 NSInteger minCorners = MAX(round( self.cornerCount - MAX(cornerCount / 10, 1.2)), 2.0);
 NSInteger maxCorners = MIN(round( self.cornerCount + MAX(cornerCount / 10, 1.2)), MAXCORNERNUMBER);
 animation = [self randomAnimationForKey:key withStartValue:startValue targetValueBetween:minCorners and:maxCorners];	
 }
 else if ([key isEqualToString:@"cornerFraction"]) {
 animation = [self randomAnimationForKey:key withStartValue:startValue targetValueBetween:0.0 and:1.41];
 }
 else if ([key isEqualToString:@"straightTangentLength"]) {
 animation = [self randomAnimationForKey:key withStartValue:startValue targetValueBetween:0.0 and:1.0];
 }
 else if ([key isEqualToString:@"straightTangentDirection"]) {
 animation = [self randomAnimationForKey:key withStartValue:startValue targetValueBetween:startValue - 3.0 * pi and:startValue + 3.0 * pi];
 }
 else if ([key isEqualToString:@"diagonalTangentLength"]) {
 animation = [self randomAnimationForKey:key withStartValue:startValue targetValueBetween:0.0 and:1.0];
 }
 else if ([key isEqualToString:@"diagonalTangentDirection"]) {
 animation = [self randomAnimationForKey:key withStartValue:startValue targetValueBetween:startValue - 3.0 * pi and:startValue + 3.0 * pi];
 }
 else if ([key isEqualToString:@"midPointsDistance"]) {
 animation = [self randomAnimationForKey:key withStartValue:startValue targetValueBetween:-1.0 and:1.0];
 }
 else if ([key isEqualToString:@"thickness"]) {
 animation = [self randomAnimationForKey:key withStartValue:startValue targetValueBetween:-1.0 and:1.0];
 }
 else if ([key isEqualToString:@"thickenedCorner"]) {
 animation = [self randomAnimationForKey:key withStartValue:startValue targetValueBetween:-1.0 and:1.0];
 }
 
 return animation;
 }
 */

/*
 NSAnimation delegate
 When an animation ends, set up a new animation for the same key, start it and replace the old one in the animations array.
 */
/*
 - (void)animationDidEnd:(ESSymmetryTotalAnimation *)animation {
 NSString * animationKey = [animation.startValues.allKeys objectAtIndex:0];
 //	ESSymmetryAnimation * newAnimation = [self randomAnimationForKey:animationKey withStartValue:[[animation.targetValues objectForKey:animationKey] floatValue]];
 [self.animationsArray removeObject:animation];
 [newAnimation startAnimation];
 [self.animationsArray addObject:newAnimation];
 
 NSLog(@"[MyDocument animationDidEnd:] - key: %@", animationKey);
 }
 */




@end
