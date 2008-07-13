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

+ (NSBezierPath *) crossCursorBezierPathForAngle: (CGFloat) angle;
+ (NSCursor *) crossCursorForAngle: (CGFloat) angle withSize: (CGFloat) size;

+ (NSBezierPath *) straightCursorBezierPathForAngle: (CGFloat) angle;
+ (NSCursor *) straightCursorForAngle: (CGFloat) angle withSize: (CGFloat) size;

+ (NSCursor *) cursorForBezierPath: (NSBezierPath *) path withRotation: (CGFloat) angle andSize: (CGFloat) size;
@end
