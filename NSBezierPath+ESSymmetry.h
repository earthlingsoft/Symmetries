//
//  NSBezierPath+RoundRect.h
//  RoundRect
//
//  Created by  Sven on 19.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSBezierPath (ESSymmetry)

+ (NSBezierPath*) bezierPathWithDictionary: (NSDictionary*) dict size: (CGFloat) s;
+ (NSData*) PDFDataForDictionary: (NSDictionary *) dict;

+ (NSBezierPath*) bezierPathWithDictionary: (NSDictionary*) dict size: (CGFloat) s cornerDelta: (CGFloat) cornerDelta;

@end
