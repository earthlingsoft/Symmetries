//
//  ESSymmetryAnimation.m
//  Symmetries
//
//  Created by  Sven on 25.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "ESSymmetryAnimation.h"


@implementation ESSymmetryAnimation

@synthesize valueObject, startValues, targetValues;



- (void)setCurrentProgress:(NSAnimationProgress) progress {
	// NSLog(@"[ESSymmetryAnimation setCurrentProgress: %f]", progress);
	
	[super setCurrentProgress:progress];

	for (NSString * key in startValues) {
		NSObject * startObject = [self.startValues objectForKey: key];
		NSObject * targetObject =  [self.targetValues objectForKey: key];
		if (startObject && targetObject) {
			if (![startObject isEqualTo:targetObject]) {	
				CGFloat startValue =  [(NSNumber*)startObject floatValue];
				CGFloat targetValue = [(NSNumber*)targetObject floatValue];
				CGFloat currentValue = startValue + (targetValue - startValue) * self.currentProgress;
				[self.valueObject setValue:[NSNumber numberWithFloat:currentValue] forKey: key];
			}
		}
	}	
}



@end
