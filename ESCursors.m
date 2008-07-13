//
//  NSBezierPath+Cursors.m
//  Symmetries
//
//  Created by  Sven on 12.07.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "ESCursors.h"

#define ARROWSIZE 0.40
#define LINETHICKNESS 0.20


@implementation ESCursors

+ (NSBezierPath *) crossCursorBezierPathForAngle: (CGFloat) angle {
	NSPoint pointArray[6];
	pointArray[0] = NSMakePoint(1.0 - ARROWSIZE, ARROWSIZE);
	pointArray[1] = NSMakePoint(1.0 - ARROWSIZE, LINETHICKNESS);
	pointArray[2] = NSMakePoint(LINETHICKNESS, LINETHICKNESS);
	pointArray[3] = NSMakePoint(LINETHICKNESS, 1.0 - ARROWSIZE);
	pointArray[4] = NSMakePoint(ARROWSIZE, 1.0 -ARROWSIZE);
	pointArray[5] = NSMakePoint(0.0, 1.0);
	
	NSBezierPath * bP = [NSBezierPath bezierPath];
	[bP moveToPoint:NSMakePoint(1.0, 0.0)];
	
	NSAffineTransform * aT = [NSAffineTransform transform];
	[aT rotateByDegrees:-90.0];

	for (NSUInteger i=0; i<4; i++) {
		[bP appendBezierPathWithPoints:pointArray count:6];
		[bP transformUsingAffineTransform:aT];
	}
	
	[bP closePath];
	
	return bP;
}



+ (NSCursor *) crossCursorForAngle: (CGFloat) angle withSize: (CGFloat) size {
	NSBezierPath * bP = [ESCursors crossCursorBezierPathForAngle: angle];
	
	return [ESCursors cursorForBezierPath:bP withRotation: angle andSize: size];	
}




+ (NSBezierPath *) straightCursorBezierPathForAngle: (CGFloat) angle {
	NSPoint pointArray[5];
	pointArray[0] = NSMakePoint(1.0 - ARROWSIZE, ARROWSIZE);
	pointArray[1] = NSMakePoint(1.0 - ARROWSIZE, LINETHICKNESS);
	pointArray[2] = NSMakePoint(-1.0 + ARROWSIZE, LINETHICKNESS);
	pointArray[3] = NSMakePoint(-1.0 + ARROWSIZE, 1.0 - ARROWSIZE);
	pointArray[4] = NSMakePoint(-1.0, 0.0);
	
	NSBezierPath * bP = [NSBezierPath bezierPath];
	[bP moveToPoint:NSMakePoint(1.0, 0.0)];
	
	NSAffineTransform * aT = [NSAffineTransform transform];
	[aT rotateByDegrees:180.0];
	
	[bP appendBezierPathWithPoints:pointArray count:5];
	[bP transformUsingAffineTransform:aT];
	[bP appendBezierPathWithPoints:pointArray count:5];
	[bP closePath];
	
	return bP;
}



+ (NSCursor *) straightCursorForAngle: (CGFloat) angle withSize: (CGFloat) size {
	NSBezierPath * bP = [ESCursors straightCursorBezierPathForAngle: angle];
	
	return [ESCursors cursorForBezierPath: bP withRotation: angle andSize: size];	
}



+ (NSCursor *) cursorForBezierPath: (NSBezierPath *) bP withRotation: (CGFloat) angle andSize: (CGFloat) size {
	CGFloat s = size * sqrt(2.0);		

	NSAffineTransform * aT = [NSAffineTransform transform];
	[aT rotateByRadians:angle];
	[aT scaleBy:size / 2.0];
	[bP transformUsingAffineTransform:aT];
	
	aT = [NSAffineTransform transform];
	[aT translateXBy: s/2.0 yBy: s/2.0];
	[bP transformUsingAffineTransform:aT];
	
	NSImage * image = [[NSImage alloc] initWithSize:NSMakeSize(s, s)];
	[image lockFocus];
	[[NSColor blackColor] set];
	[bP fill];
	[[NSColor whiteColor] set];
	bP.lineWidth = 1.0;
	[bP stroke];
	[image unlockFocus];
	
	NSCursor * theCursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(s/2.0, s/2.0)];
	
	return theCursor;
}


@end
