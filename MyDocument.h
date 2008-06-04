//
//  MyDocument.h
//  RoundRect
//
//  Created by  Sven on 22.05.08.
//  Copyright earthlingsoft 2008 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
//#import "RRView.h"

@interface MyDocument : NSDocument
{
	CGFloat h;
 	CGFloat size;
	NSUInteger cornerCount;
	BOOL twoMidPoints;
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
	BOOL beSquare;
	NSUInteger showHandles;
	
	IBOutlet NSView *  myView;
} 

//@property	CGFloat h;
@property 	CGFloat size;
@property 	NSUInteger cornerCount;
@property	BOOL twoMidPoints;
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
@property	BOOL beSquare;
@property	NSUInteger showHandles;
@property (retain) NSView * myView;

- (id) init;
- (id) initWithDictionary: (NSDictionary*) dict;
- (IBAction) valueChanged:(id) sender;
- (NSDictionary*) initialValues;
- (NSDictionary*) dictionary;

- (void)printDocumentUsingPrintPanel:(BOOL)uiFlag;
- (void)printDocument:(id)sender;
- (void)runPageLayout:(id)sender;
- (void)didEndPageLayout:(NSPageLayout *)pageLayout returnCode:(int)result contextInfo:(void *)contextInfo;

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
- (IBAction) setHandles:(id) sender;

@end
