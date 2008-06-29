//
//  ESSymmetryTotalAnimation.m
//  Symmetries
//
//  Created by  Sven on 29.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "ESSymmetryTotalAnimation.h"


@implementation ESSymmetryTotalAnimation
@synthesize properties;
@synthesize valueObject;


#pragma mark OVERRIDE

- (void)setCurrentProgress:(NSAnimationProgress) progress {
	// NSLog(@"[ESSymmetryTotalAnimation setCurrentProgress: %f]", progress);
	[self updateProperties];
}


#pragma mark PROPERTIES

/*
 Each property has fields:
	* startTime 
	* endTime 
	* startValue
	* endValue
*/
- (void) updateProperties {
	// NSLog(@"[ESSymmetryTotalAnimation updateProperties]");
	NSDate * now = [NSDate date];
	NSTimeInterval nowTI = [now timeIntervalSinceReferenceDate];
	
	for (NSString * key in self.properties.allKeys) {
		NSMutableDictionary * property = [self.properties objectForKey:key];
		NSNumber * currentValueNumber = [self.valueObject valueForKey:key];
		CGFloat currentValue = [currentValueNumber floatValue];
		NSDate * endTimeDate = [property objectForKey:@"endTime"];
		
		// recreate animation if it has expired
		if (!endTimeDate || [endTimeDate timeIntervalSinceReferenceDate] < nowTI) {
			NSDictionary * minMax = [self.valueObject valueRangeForKey: key currentValue:currentValue];
			CGFloat min, max;
			NSNumber * value;
			(value = [minMax objectForKey:@"minValue"]) ? (min = [value floatValue]) : (min = 0.0);
			(value = [minMax objectForKey:@"maxValue"]) ? (max = [value floatValue]) : (max = 1.0);
			
			CGFloat newTarget = [self randomFloatBetween:min and:max];
			NSNumber * newTargetNumber = [NSNumber numberWithFloat: newTarget];
			NSDate * newEndTime = [now addTimeInterval:[self randomFloatBetween: 3.0 and: 15.0]]; //[endTimeDate addTimeInterval:[self randomFloatBetween: 3.0 and: 15.0]];

			[property setObject:now forKey:@"startTime"];
			[property setObject:newEndTime forKey:@"endTime"];
			[property setObject:currentValueNumber forKey:@"startValue"];
			[property setObject:newTargetNumber forKey:@"endValue"];
		//	NSLog(@" new target in %f\" for %@: %@", [newEndTime timeIntervalSinceReferenceDate] - nowTI, key, newTargetNumber);
		}
		
		NSTimeInterval startTime = [(NSDate*)[property objectForKey:@"startTime"] timeIntervalSinceReferenceDate];
		NSTimeInterval endTime = [(NSDate*)[property objectForKey:@"endTime"] timeIntervalSinceReferenceDate];		
		CGFloat startValue = [(NSNumber*)[property objectForKey:@"startValue"] floatValue];
		CGFloat endValue = [(NSNumber*)[property objectForKey:@"endValue"] floatValue];		
		
		// linear interpoloation
		CGFloat duration = endTime - startTime;
		CGFloat currentDelta = nowTI - startTime;
		CGFloat t =  currentDelta / duration;
		CGFloat newValue = (t* endValue + (1 - t) * startValue);
		NSNumber * newValueNumber = [NSNumber numberWithFloat: newValue];
		
		[self.valueObject setValue:newValueNumber forKey:key];
		// NSLog(@"%@ = %@", key, newValueNumber);
	}	
}


															
								   
/*
	Adds a new entry with the given key to the properties.
	Values are in the far past, so they are initialised in the next run.
	If the key already exists, its contents will be reset to the initial state.
*/
- (void) addProperty: (NSString*) key {
	NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:4];
	[dict setObject:[NSDate distantPast] forKey:@"startTime"];
	[dict setObject:[NSDate distantPast] forKey:@"endTime"];
	[dict setObject:[NSNumber numberWithFloat: 0.0] forKey:@"startValue"];
	[dict setObject:[NSNumber numberWithFloat: 1.0] forKey:@"endValue"];

	[self.properties setObject:dict forKey:key];
}


#pragma mark UTILITY

- (CGFloat) randomFloatBetween: (CGFloat) min and: (CGFloat) max {
	long r = random() ;
	CGFloat result = (float)r / RAND_MAX * (max-min) + min;
	// NSLog (@"%i (%f)-> %f", r, (float)r/RAND_MAX,result);
		
	return result;	
}


#pragma mark HOUSEKEEPING

- (id)initWithDuration:(NSTimeInterval)duration animationCurve:(NSAnimationCurve)animationCurve {
	self = [super initWithDuration:duration animationCurve:animationCurve];
	if (self) {
		self.properties = [NSMutableDictionary dictionaryWithCapacity:10];
	}
	return self;
}

- (void) finalize {
	[self.properties removeAllObjects];
	[super finalize];
}

@end
