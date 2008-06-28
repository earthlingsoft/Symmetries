//
//  MyDocument.h
//  Symmetry
//
//  Created by  Sven on 22.05.08.
//  Copyright earthlingsoft 2008 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "ESSymmetryAnimation.h"


@interface MyDocument : NSDocument
{
 	CGFloat size;
	NSUInteger cornerCount;
	BOOL twoMidPoints;
	BOOL twoLines;
 	CGFloat cornerFraction;
 	CGFloat straightTangentLength;
	CGFloat straightTangentDirection;
 	CGFloat diagonalTangentLength;
	CGFloat diagonalTangentDirection;
	CGFloat midPointsDistance;
	CGFloat thickness;
	CGFloat thickenedCorner; 
	
	NSColor * backgroundColor; 
	NSColor * strokeColor;
	NSColor * fillColor;
	CGFloat strokeThickness;
	CGFloat previousStrokeThickness;
	
	NSDate * strokeThicknessRecentChange;
	NSUInteger showHandles;
	
	IBOutlet NSView *  myView;
} 

@property 	CGFloat size;
@property 	NSUInteger cornerCount;
@property	BOOL twoMidPoints;
@property	BOOL twoLines;
@property 	CGFloat cornerFraction;
@property 	CGFloat straightTangentLength;
@property 	CGFloat straightTangentDirection;
@property 	CGFloat diagonalTangentLength;
@property 	CGFloat diagonalTangentDirection;
@property 	CGFloat midPointsDistance;
@property	CGFloat thickness;
@property	CGFloat thickenedCorner;
@property (retain)	NSColor * backgroundColor; 
@property (retain)	NSColor * strokeColor;
@property (retain)	NSColor * fillColor;
@property	CGFloat strokeThickness;
@property	CGFloat previousStrokeThickness;
@property (retain) NSDate * strokeThicknessRecentChange;
@property	NSUInteger showHandles;
@property (retain) NSView * myView;
@property (readonly) BOOL runningDemo;

- (id) init;
- (id) initWithDictionary: (NSDictionary*) dict;
- (NSDictionary*) initialValues;
- (NSDictionary*) dictionary;
- (void) setValuesFromDictionary: (NSDictionary*) dict;

- (void) intro;

- (void)printDocumentUsingPrintPanel:(BOOL)uiFlag;
- (void)printDocument:(id)sender;
- (void)runPageLayout:(id)sender;
- (void)didEndPageLayout:(NSPageLayout *)pageLayout returnCode:(int)result contextInfo:(void *)contextInfo;

- (CGFloat) normalisePolarAngle: (CGFloat) phi;

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem;
- (IBAction) setHandles:(id) sender;
- (IBAction) twoMiddlePoints:(id) sender;
- (IBAction) twoLines:(id) sender;
- (IBAction) sliderMoved: (id) sender;
- (IBAction) bogusAction: (id) sender;

- (IBAction) animate:(id) sender;
- (IBAction) animateFullScreen:(id) sender;
- (IBAction) stopAnimation:(id) sender;

- (NSArray*) animationKeys;
- (CGFloat) randomFloatBetween: (CGFloat) min and:(CGFloat) max;
- (ESSymmetryAnimation *) randomAnimationForKey:(NSString *) key withStartValue:(CGFloat) startValue targetValueBetween:(CGFloat) min and: (CGFloat) max;
- (ESSymmetryAnimation *) randomAnimationForKey:(NSString *) key withStartValue:(CGFloat) startValue;


@end
