//
//  MyDocument.h
//  Symmetry
//
//  Created by  Sven on 22.05.08.
//  Copyright earthlingsoft 2008 . All rights reserved.
//


#import <Cocoa/Cocoa.h>

#define FILETYPEUTI @"net.earthlingsoft.symmetry.document"

#define SIZE_MIN 0.0
#define SIZE_MAX 1.0
#define CORNERCOUNT_MIN 2
#define CORNERCOUNT_MAX 37
#define CORNERFRACTION_MIN -1.414
#define CORNERFRACTION_MAX 1.414
#define MIDPOINTSDISTANCE_MIN -1.0
#define MIDPOINTSDISTANCE_MAX 1.0
#define STRAIGHTTANGENTLENGTH_MIN 0.0
#define STRAIGHTTANGENTLENGTH_MAX 1.0
//#define STRAIGHTTANGENTDIRECTION_MIN 0.0
//#define STRAIGHTTANGENTDIRECTION_MAX 2 * pi
#define DIAGONALTANGENTLENGTH_MIN 0.0
#define DIAGONALTANGENTLENGTH_MAX 1.0
//#define DIAGONALTANGENTDIRECTION_MIN 0.0
//#define DIAGONALTANGENTDIRECTION_MAX 1.0
#define THICKNESS_MIN 0.0
#define THICKNESS_MAX 1.0
#define THICKENEDCORNER_MIN -1.0
#define THICKENEDCORNER_MAX 1.0

@class ESSymmetryTotalAnimation;

@interface MyDocument : NSDocument
{
 	CGFloat size;
	NSUInteger cornerCount;
 	CGFloat cornerFraction;
	CGFloat midPointsDistance;
 	CGFloat straightTangentLength;
	CGFloat straightTangentDirection;
 	CGFloat diagonalTangentLength;
	CGFloat diagonalTangentDirection;
	CGFloat thickness;
	CGFloat thickenedCorner; 
	BOOL twoMidPoints;
	BOOL twoLines;
	CGFloat rotation;
	
	NSColor * backgroundColor; 
	NSColor * strokeColor;
	NSColor * fillColor;
	CGFloat strokeThickness;
	CGFloat previousStrokeThickness;
	
	NSDate * strokeThicknessRecentChange;
	NSUInteger showHandles;
	
	IBOutlet NSView *  myView;
	
	ESSymmetryTotalAnimation * totalAnimation;
} 

@property 	CGFloat size;
@property 	NSUInteger cornerCount;
@property 	CGFloat cornerFraction;
@property 	CGFloat straightTangentLength;
@property 	CGFloat straightTangentDirection;
@property 	CGFloat diagonalTangentLength;
@property 	CGFloat diagonalTangentDirection;
@property 	CGFloat midPointsDistance;
@property	CGFloat thickness;
@property	CGFloat thickenedCorner;
@property	BOOL twoMidPoints;
@property	BOOL twoLines;
@property	CGFloat rotation;

@property (retain)	NSColor * backgroundColor; 
@property (retain)	NSColor * strokeColor;
@property (retain)	NSColor * fillColor;
@property	CGFloat strokeThickness;

@property	CGFloat previousStrokeThickness;
@property (retain) NSDate * strokeThicknessRecentChange;
@property	NSUInteger showHandles;
@property (retain) NSView * myView;

@property (retain) ESSymmetryTotalAnimation * totalAnimation;

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

@end
