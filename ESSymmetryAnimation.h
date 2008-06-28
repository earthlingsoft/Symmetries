//
//  ESSymmetryAnimation.h
//  Symmetries
//
//  Created by  Sven on 25.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ESSymmetryAnimation : NSAnimation {
	NSObject * valueObject;
	NSDictionary * startValues;
	NSDictionary * targetValues;
}

@property (retain)	NSObject * valueObject;
@property (retain)	NSDictionary * startValues; 
@property (retain)	NSDictionary * targetValues;


- (void)setCurrentProgress:(NSAnimationProgress)progress;


@end
