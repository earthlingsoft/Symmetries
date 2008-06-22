//
//  NSBezierPath+RoundRect.m
//  RoundRect
//
//  Created by  Sven on 19.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "NSBezierPath+ESSymmetry.h"


@implementation NSBezierPath (ESSymmetry)


+ (NSBezierPath*) bezierPathWithDictionary: (NSDictionary*) dict size: (CGFloat) s {
	// outer and inner path
	NSBezierPath * path = [NSBezierPath bezierPathWithDictionary:dict size:s cornerDelta: 0.0];	

	if ([[dict objectForKey:@"twoLines"] boolValue]) {
		CGFloat thickness = [[dict objectForKey:@"thickness"] floatValue];
		CGFloat cornerDelta = [[dict objectForKey:@"thickenedCorner"] floatValue];
		NSBezierPath * path2 = [NSBezierPath bezierPathWithDictionary:dict size:s * (1-thickness) 
														  cornerDelta:cornerDelta ];
		// compound path
		[path appendBezierPath:[path2 bezierPathByReversingPath]];
	}
	
	return path;
}




+ (NSBezierPath*) bezierPathWithDictionary: (NSDictionary*) dict size: (CGFloat) s cornerDelta: (CGFloat) cornerDelta{
	// gather the values we need
	NSUInteger corners = [[dict objectForKey:@"cornerCount"] unsignedIntValue];
	CGFloat cF =  ([[dict objectForKey:@"cornerFraction"] floatValue] - cornerDelta) * sqrt(2.0);
	CGFloat sTL = [[dict objectForKey:@"straightTangentLength"] floatValue];
	CGFloat sTD = [[dict objectForKey:@"straightTangentDirection"] floatValue];
	CGFloat dTL = [[dict objectForKey:@"diagonalTangentLength"] floatValue];
	CGFloat dTD = [[dict objectForKey:@"diagonalTangentDirection"] floatValue];
	CGFloat midPointsDistance = [[dict valueForKey:@"midPointsDistance"] floatValue];
	BOOL twoMidPoints = [[dict valueForKey:@"twoMidPoints"] boolValue];
	CGFloat phi = 2.0 * pi / corners;
		
	// anchor points
	NSPoint startPoint = NSMakePoint(s, 0.0);
	NSPoint midPoint = NSMakePoint(cos(0.5 * phi) * cF * s,  sin(0.5 * phi) * cF * s);
	NSPoint endPoint = NSMakePoint(cos(phi) * s,   sin(phi) * s);
	
	// handle directions
	NSPoint startHandleDirection = NSMakePoint(0,   s * sTL);
	NSPoint endHandleDirection = NSMakePoint( sin(phi) * s * sTL , 
											 -cos(phi) * s * sTL ); 	
	NSAffineTransform * rotateStartHandle = [NSAffineTransform transform];
	[rotateStartHandle rotateByRadians: -sTD];
	NSPoint startHandleDirectionOut = [rotateStartHandle transformPoint:startHandleDirection];
	[rotateStartHandle invert];
	NSPoint endHandleDirectionIn = [rotateStartHandle transformPoint:endHandleDirection];
	
	NSPoint startHandle = NSMakePoint(startPoint.x + startHandleDirectionOut.x, 
									  startPoint.y + startHandleDirectionOut.y);
	NSPoint endHandle = NSMakePoint(endPoint.x + endHandleDirectionIn.x, 
									endPoint.y + endHandleDirectionIn.y);
	
	/*	middle tangents
		We have two options for this:
	 1) Two symmetric midpoints with equal length tangents
	 2) A single central midpoint
	*/
	NSPoint midTangent = NSMakePoint((endPoint.x - startPoint.x), 
									 (endPoint.y - startPoint.y) );
	NSPoint midTangentDirection = NSMakePoint((endPoint.x - startPoint.x) * dTL, 
											  (endPoint.y - startPoint.y) * dTL );
	NSAffineTransform * rotateMidHandle = [NSAffineTransform transform];
	[rotateMidHandle rotateByRadians: -dTD];
	NSPoint mid1Point, mid1HandleIn, mid1HandleOut, mid2Point, mid2HandleIn, mid2HandleOut;
	if (twoMidPoints) {
		
		mid1Point = NSMakePoint(midPoint.x - midTangent.x * midPointsDistance,
										midPoint.y - midTangent.y * midPointsDistance);
		mid2Point = NSMakePoint(midPoint.x + midTangent.x * midPointsDistance,
										midPoint.y + midTangent.y * midPointsDistance);
		
		NSPoint mid1HandleDirection = [rotateMidHandle transformPoint:midTangentDirection];
		mid1HandleIn = NSMakePoint(mid1Point.x + mid1HandleDirection.x, 
								  mid1Point.y + mid1HandleDirection.y);
		mid1HandleOut = NSMakePoint(mid1Point.x - mid1HandleDirection.x, 
									mid1Point.y - mid1HandleDirection.y);
		
		[rotateMidHandle invert];
		NSPoint mid2HandleDirection = [rotateMidHandle transformPoint:midTangentDirection];
		mid2HandleIn = NSMakePoint(mid2Point.x + mid2HandleDirection.x, 
								   mid2Point.y + mid2HandleDirection.y);
		mid2HandleOut = NSMakePoint(mid2Point.x - mid2HandleDirection.x, 
									mid2Point.y - mid2HandleDirection.y);
	}
	else {
		// just have a single midpoint
		NSPoint midTangentDirectionOut = [rotateMidHandle transformPoint:midTangentDirection];
		[rotateMidHandle invert];
		NSPoint midTangentDirectionIn = [rotateMidHandle transformPoint:midTangentDirection];
		mid1HandleOut = NSMakePoint(-midTangentDirectionIn.x + midPoint.x, 
			 					    -midTangentDirectionIn.y + midPoint.y); 
		mid1HandleIn = NSMakePoint(midTangentDirectionOut.x + midPoint.x,
								   midTangentDirectionOut.y + midPoint.y); 
		
	}
	
	// create resulting bezier path 
	NSAffineTransform * rotate = [NSAffineTransform transform];	
	[rotate rotateByRadians: -phi];
	
	NSBezierPath * thePath = [NSBezierPath bezierPath];
	[thePath moveToPoint:startPoint];
	
	for (int i=0; i<corners; i++) {
		if (twoMidPoints) {
			[thePath curveToPoint:mid1Point controlPoint1:startHandle controlPoint2:mid1HandleIn];
			[thePath curveToPoint:mid2Point controlPoint1:mid1HandleOut controlPoint2:mid2HandleIn];
			[thePath curveToPoint:endPoint controlPoint1:mid2HandleOut controlPoint2:endHandle];
		}
		else {
			[thePath curveToPoint:midPoint controlPoint1:startHandle controlPoint2:mid1HandleIn];
			[thePath curveToPoint:endPoint controlPoint1:mid1HandleOut controlPoint2:endHandle];
		}
		[thePath transformUsingAffineTransform:rotate];
	}
	
	[thePath closePath];
	
	return thePath;
}

@end
