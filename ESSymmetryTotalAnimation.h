//
//  ESSymmetryTotalAnimation.h
//  Symmetries
//
//  Created by  Sven on 29.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MyDocument;

@protocol ESSymmetryTotalAnimationDelegate	
/* For a given key and current value, 
	this returns a dictionary with two NSNumber entries @"startValue" and @"endValue" which determine the values that the animation will use.
	If nil is returned a @"startValue" of 0.0 and an @"endValue" of 1.0 will be used.
*/
- (NSDictionary *) valueRangeForKey: (NSString *) key currentValue: (CGFloat) currentValue;

@end


@interface ESSymmetryTotalAnimation : NSAnimation {
	NSMutableDictionary * properties;
	MyDocument * valueObject;
}

@property (retain) NSMutableDictionary * properties;
@property (retain) MyDocument * valueObject;


- (void) updateProperties;
- (void) addProperty: (NSString*) key;
- (CGFloat) randomFloatBetween: (CGFloat) min and: (CGFloat) max;
@end



