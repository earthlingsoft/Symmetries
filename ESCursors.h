//
//  NSBezierPath+Cursors.h
//  Symmetries
//
//  Created by  Sven on 12.07.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ESCursors : NSObject {
}


+ (NSBezierPath *) curvedCursorBezierPathWithRightArrow:(BOOL) rightArrow upArrow:(BOOL) upArrow leftArrow:(BOOL) leftArrow downArrow: (BOOL) downArrow forAngle: (CGFloat) angle;
+ (NSCursor *) curvedCursorWithRightArrow:(BOOL) rightArrow upArrow:(BOOL) upArrow leftArrow:(BOOL) leftArrow downArrow: (BOOL) downArrow forAngle: (CGFloat) angle size: (CGFloat) size;
+ (NSCursor *) curvedCursorWithRightArrow:(BOOL) rightArrow upArrow:(BOOL) upArrow leftArrow:(BOOL) leftArrow downArrow: (BOOL) downArrow forAngle: (CGFloat) angle size: (CGFloat) size underlay:(NSImage*) underlay;


+ (NSBezierPath *) crossCursorBezierPathForAngle: (CGFloat) angle;
+ (NSCursor *) crossCursorForAngle: (CGFloat) angle withSize: (CGFloat) size;

+ (NSBezierPath *) threeProngedCursorBezierPathForAngle: (CGFloat) angle;
+ (NSCursor *) threeProngedCursorForAngle: (CGFloat) angle withSize: (CGFloat) size;

+ (NSBezierPath *) angleCursorBezierPathForAngle: (CGFloat) angle;
+ (NSCursor *) angleCursorForAngle: (CGFloat) angle withSize: (CGFloat) size;

+ (NSBezierPath *) straightCursorBezierPathForAngle: (CGFloat) angle;
+ (NSCursor *) straightCursorForAngle: (CGFloat) angle withSize: (CGFloat) size;

+ (NSBezierPath *) halfStraightCursorBezierPathForAngle: (CGFloat) angle;
+ (NSCursor *) halfStraightCursorForAngle: (CGFloat) angle withSize: (CGFloat) size;

+ (NSCursor *) cursorForBezierPath: (NSBezierPath *) bP withRotation: (CGFloat) angle size: (CGFloat) size andUnderlay:(NSImage *) underlay;
+ (NSCursor *) cursorForBezierPath: (NSBezierPath *) path withRotation: (CGFloat) angle andSize: (CGFloat) size;
@end
