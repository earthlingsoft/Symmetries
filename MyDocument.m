//
//  MyDocument.m
//  Symmetry
//
//  Created by  Sven on 22.05.08.
//  Copyright earthlingsoft 2008 . All rights reserved.
//

#import "MyDocument.h"
#import "MyDocument+Animation.h"
#import "NSBezierPath+ESSymmetry.h"
#import "ESSymmetryView+Intro.h"
#import "ESSymmetryTotalAnimation.h"
#import "AppDelegate.h"

@implementation MyDocument

@synthesize twoMidPoints, twoLines, backgroundColor, strokeColor, fillColor, strokeThickness, showHandles, myView, strokeThicknessRecentChange, previousStrokeThickness, totalAnimation;
@dynamic cornerCount, size, cornerFraction, straightTangentLength, straightTangentDirection, diagonalTangentLength, diagonalTangentDirection, midPointsDistance, thickness, rotation;

# pragma mark HOUSEKEEPING

- (id)init
{
    return [self initWithDictionary: [self initialValues]];
	unsigned int time = round((double)[NSDate timeIntervalSinceReferenceDate]);
	srandom(time);
}


- (id) initWithDictionary: (NSDictionary*) dict {
	self = [super init];
	if (self) {
		NSDictionary * defaults = [self initialValues];
		// fill up with values from dictionary 
		[self setValuesFromDictionary: defaults];
		[self setValuesFromDictionary: dict];
		
		// and start observing all possible values them
		for (NSString * key in defaults) {
			[self addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
		}
    }
    return self;
}


- (NSDictionary*) initialValues {
	return [NSDictionary dictionaryWithObjectsAndKeys: 
			[NSNumber numberWithFloat: 0.6], @"size",
			[NSNumber numberWithInt:4], @"cornerCount",
			[NSNumber numberWithFloat: 0.71], @"cornerFraction",
			[NSNumber numberWithFloat: 0.5], @"midPointsDistance",
			[NSNumber numberWithFloat: 0.8], @"straightTangentLength",
			[NSNumber numberWithFloat: 0.0], @"straightTangentDirection",
			[NSNumber numberWithFloat: 0.07], @"diagonalTangentLength",
			[NSNumber numberWithFloat: 1.0], @"diagonalTangentDirection",
			[NSNumber numberWithFloat: 0.2], @"thickness",
			[NSNumber numberWithFloat: 0.01], @"thickenedCorner",
			[NSNumber numberWithBool:YES ], @"twoMidPoints",
			[NSNumber numberWithBool:YES ], @"twoLines",
			[NSNumber numberWithFloat: 0.141], @"strokeThickness",
			[NSColor whiteColor], @"backgroundColor",
			[NSColor blackColor], @"strokeColor",
			[NSColor lightGrayColor], @"fillColor",
			[NSNumber numberWithUnsignedInt: 1 ], @"showHandles",
			nil];
}


- (void) close {
	// NSLog(@"[MyDocument close]");
	[self stopAnimation:self];
	[(ESSymmetryView*) self.myView endDemo:self];
	[super close];
}


- (NSDictionary*) dictionary {
	NSDictionary * initialValues = [self initialValues];
	NSMutableDictionary * valueDictionary = [NSMutableDictionary dictionaryWithCapacity:[initialValues count]];
	for (NSString * key in initialValues) {
		[valueDictionary setObject: [self valueForKey:key] forKey: key];
	}		
	return valueDictionary;
}


- (NSDictionary*) plistDictionary {
	NSDictionary * initialValues = [self initialValues];
	NSMutableDictionary * valueDictionary = [NSMutableDictionary dictionaryWithCapacity:[initialValues count]];
	for (NSString * key in initialValues) {
		NSObject * object = [self valueForKey:key];
		if ([object isKindOfClass:[NSColor class]]) {
			object = [NSArchiver archivedDataWithRootObject:object];
		}
		[valueDictionary setObject:object  forKey: key];
	}		
	return valueDictionary;
}


- (void) setValuesFromDictionary: (NSDictionary*) dict {
	NSDictionary * defaultValues = [self initialValues];
	for (NSString * key in dict) {
		if ([defaultValues objectForKey:key]) {
			[self setValue:[dict objectForKey:key] forKey:key];
		}
	}
}


- (void) setValuesForUndoFromDictionary: (NSDictionary *) dict {
	[self.undoManager registerUndoWithTarget:self selector:@selector(setValuesForUndoFromDictionary:) object:[self dictionary]];
	[self setValuesFromDictionary:dict];
}


/*
	Allegedly this should be obvious from the Info.plist, but that didn't work…
*/
+ (NSArray*) writableTypes {
	return [NSArray arrayWithObjects: FILETYPEUTI, kUTTypePDF, nil];
}


- (void) intro {
	[(ESSymmetryView*) myView intro];
}



#pragma mark DOCUMENT DELEGATE METHODS

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}


- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}


- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	// NSLog(@"[MyDocument writeToURL: ofType: %@...]", typeName);
	BOOL writeOK = NO;

	if ([typeName isEqualToString:FILETYPEUTI]) {
		// our own file type
		NSDictionary * dict = [self plistDictionary];
		if (dict) {
			writeOK = [dict writeToURL:absoluteURL atomically:YES];
		}
	}
	else if ([typeName isEqualToString:(NSString *) 
			  kUTTypePDF]) {
		// export a PDF file
		NSData * pdfData = [NSBezierPath PDFDataForDictionary:[self dictionary]];
		if (pdfData) {
			writeOK = [pdfData writeToURL:absoluteURL atomically:YES];	
		}
	}
	
	if (!writeOK) {
		// nicked from sample code, not even sure what it does
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}

	return writeOK;
}



- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError
{
	if ([typeName isEqualToString:FILETYPEUTI]) {
		NSMutableDictionary *myDict= [NSMutableDictionary dictionaryWithDictionary: [super fileAttributesToWriteToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:outError]];
									  
		[myDict setObject:[NSNumber numberWithLong:'esRR'] forKey:NSFileHFSCreatorCode];
		[myDict setObject:[NSNumber numberWithLong:'esRR'] forKey:NSFileHFSTypeCode];
	
	return myDict;
	}
	
	return nil;
}



- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	NSDictionary * dict = [NSDictionary dictionaryWithContentsOfURL:absoluteURL];
	if (dict) {
		NSDictionary * initialValues = [self initialValues];
		NSObject * object;
		for (NSString * key in initialValues) {
			if (object = [dict objectForKey:key]) {
				if ([object isKindOfClass: [NSData class]]) { // unarchive NSColor objects
					object = [NSUnarchiver unarchiveObjectWithData: (NSData*) object];
				}				
				[self setValue: object forKey: key];
			}
			else {
				[self setValue: [initialValues objectForKey:key] forKey:key];
			}
		}				
	}
    
    if ( !dict ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return (dict != nil);
}





#pragma mark KVO

/*
	trigger redraw when one of our values is changed
*/
 - (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	// NSLog(@"[MyDocument observeValueForKeyPath: %@ ...]", keyPath);
	 if ([object isEqual:self]) {
		 [self.myView setNeedsDisplay:YES];
		 NSNumber * oldNumber = [change objectForKey:NSKeyValueChangeOldKey];
		 NSNumber * newNumber = [change objectForKey:NSKeyValueChangeNewKey];
		 if ([keyPath isEqualToString:@"cornerCount"]) {
			 if (![newNumber isEqualToNumber:oldNumber]) {
				 [self.myView updateCursor];
			 }
		 }
		 else if ([keyPath isEqualToString:@"size"]) {
			 if (![newNumber isEqualToNumber:oldNumber]) {
				 if ([newNumber floatValue] == ESSYM_SIZE_MIN || [newNumber floatValue] == ESSYM_SIZE_MAX || [oldNumber floatValue] == ESSYM_SIZE_MIN || [oldNumber floatValue] == ESSYM_SIZE_MAX ) {
					 [self.myView updateCursor];
				 }
			 }
		 }
		 else if ([keyPath isEqualToString:@"cornerFraction"]) {
			 if (![newNumber isEqualToNumber:oldNumber]) {
				 if ([newNumber floatValue] == ESSYM_CORNERFRACTION_MIN || [newNumber floatValue] == ESSYM_CORNERFRACTION_MAX || [oldNumber floatValue] == ESSYM_CORNERFRACTION_MIN || [oldNumber floatValue] == ESSYM_CORNERFRACTION_MAX ) {
					 [self.myView updateCursor];
				 }
			 }
		 }
		 else if ([keyPath isEqualToString:@"midPointsDistance"]) {
			 if (![newNumber isEqualToNumber:oldNumber]) {
				 NSLog(@"%@", newNumber);
				 if ([newNumber floatValue] == ESSYM_MIDPOINTSDISTANCE_MIN || [newNumber floatValue] == ESSYM_MIDPOINTSDISTANCE_MAX || [oldNumber floatValue] == ESSYM_MIDPOINTSDISTANCE_MIN || [oldNumber floatValue] == ESSYM_MIDPOINTSDISTANCE_MAX ) {
					 [self.myView updateCursor];
				 }
			 }
		 }
		 else if ([keyPath isEqualToString:@"thickness"]) {
			 if (![newNumber isEqualToNumber:oldNumber]) {
				 if ([newNumber floatValue] == ESSYM_THICKNESS_MIN || [newNumber floatValue] == ESSYM_THICKNESS_MAX || [oldNumber floatValue] == ESSYM_THICKNESS_MIN || [oldNumber floatValue] == ESSYM_THICKNESS_MAX ) {
					 [self.myView updateCursor];
				 }
			 }
		 }
		 else if ([keyPath isEqualToString:@"thickenedCorner"]) {
			 if (![newNumber isEqualToNumber:oldNumber]) {
				 if ([newNumber floatValue] == ESSYM_THICKENEDCORNER_MIN || [newNumber floatValue] == ESSYM_THICKENEDCORNER_MAX || [oldNumber floatValue] == ESSYM_THICKENEDCORNER_MIN || [oldNumber floatValue] == ESSYM_THICKENEDCORNER_MAX ) {
					 [self.myView updateCursor];
				 }
			 }
		 }
		 else if ([keyPath isEqualToString:@"strokeThickness"]) {
			 self.previousStrokeThickness = [[change objectForKey:NSKeyValueChangeOldKey] floatValue];
		 }
		 else if ([keyPath isEqualToString:@"backgroundColor"]) {
			 self.myView.layer.backgroundColor = (CGColorRef) self.backgroundColor;
		 }
	 }
 }



#pragma mark ACCESSORS

- (BOOL) registeredMode {
	AppDelegate * aD = [NSApp delegate];
	return aD.isRegistered || (self.cornerCount == SYMMETRIESUNREGISTEREDCORNERCOUNT);
}


- (BOOL) runningDemo {
	return (((ESSymmetryView*)self.myView).currentDemoStep >= 0);
}


- (BOOL) runningAnimation {
	return [self.totalAnimation isAnimating];
}


/*
	Our main document values.
	Try to normalise / sanitise them a bit before setting.
	Also tell animations about the changes, so they can pick up the changes.
*/


- (CGFloat) size {
	return size;
}

- (void) setSize: (CGFloat) s {
	size = MAX(MIN(s, ESSYM_SIZE_MAX), ESSYM_SIZE_MIN);
}


- (NSUInteger) cornerCount {
	return cornerCount;
}

- (void) setCornerCount: (NSUInteger) n {
	cornerCount = MAX(MIN(n, ESSYM_CORNERCOUNT_MAX), ESSYM_CORNERCOUNT_MIN);
}


- (CGFloat) cornerFraction {
	return cornerFraction;
}

- (void) setCornerFraction: (CGFloat) cF {
	cornerFraction = MAX(MIN(cF, ESSYM_CORNERFRACTION_MAX), ESSYM_CORNERFRACTION_MIN);
}


- (CGFloat) straightTangentLength {
	return straightTangentLength;
}

- (void) setStraightTangentLength: (CGFloat) sTL {
	straightTangentLength = MAX(MIN(sTL, ESSYM_STRAIGHTTANGENTLENGTH_MAX), ESSYM_STRAIGHTTANGENTLENGTH_MIN);
}


- (CGFloat) straightTangentDirection {
	return straightTangentDirection;
}

- (void) setStraightTangentDirection: (CGFloat) sTD {
	straightTangentDirection = [self normalisePolarAngle: sTD];
}


- (CGFloat) diagonalTangentLength {
	return diagonalTangentLength;
}

- (void) setDiagonalTangentLength: (CGFloat) dTL {
	diagonalTangentLength = MAX(MIN(dTL, ESSYM_DIAGONALTANGENTLENGTH_MAX), ESSYM_DIAGONALTANGENTLENGTH_MIN);
}


- (CGFloat) diagonalTangentDirection {
	return diagonalTangentDirection;
}

- (void) setDiagonalTangentDirection: (CGFloat) dTD {
	diagonalTangentDirection = [self normalisePolarAngle: dTD];
}


- (CGFloat) midPointsDistance {
	return midPointsDistance;
}

- (void) setMidPointsDistance: (CGFloat) mPD {
	midPointsDistance = MAX(MIN(mPD, ESSYM_MIDPOINTSDISTANCE_MAX), ESSYM_MIDPOINTSDISTANCE_MIN);
}


- (CGFloat) thickness {
	return thickness;
}

- (void) setThickness: (CGFloat) t {
	thickness = MAX(MIN(t, ESSYM_THICKNESS_MAX), ESSYM_THICKNESS_MIN);
}


- (CGFloat) thickenedCorner {
	return thickenedCorner;
}

- (void) setThickenedCorner: (CGFloat) tC {
	thickenedCorner = MAX(MIN(tC, ESSYM_THICKENEDCORNER_MAX), ESSYM_THICKENEDCORNER_MIN);
}


- (CGFloat) rotation {
	return rotation;
}

- (void) setRotation: (CGFloat) phi {
	rotation = [self normalisePolarAngle: phi];
}





/*
	Make sure that 0 <= phi <= 2pi
	This will be horrible for large phi
*/ 
- (CGFloat) normalisePolarAngle: (CGFloat) phi {
	CGFloat f = phi;
	while (f < 0 ) { f = f + 2.0 * pi; }
	while (f > 2.0 * pi ) { f = f - 2.0 * pi; }
	return f;
}


#pragma mark PRINTING

- (void)printDocumentUsingPrintPanel:(BOOL)uiFlag {
	NSPrintInfo * pI = [self printInfo];
	[pI setHorizontallyCentered:YES];
	[pI setVerticallyCentered:YES];
	[pI setHorizontalPagination:NSFitPagination];
	[pI setVerticalPagination:NSFitPagination];
	
	NSPrintOperation *op = [NSPrintOperation printOperationWithView:myView printInfo:[self printInfo]];
	[op setShowPanels:uiFlag];
	[op runOperationModalForWindow:[self windowForSheet] delegate:nil didRunSelector:NULL contextInfo:NULL];
}

- (void)printDocument:(id)sender {
	[self printDocumentUsingPrintPanel:YES];
}

- (void)runPageLayout:(id)sender {
	NSPrintInfo *tempPrintInfo = [[self printInfo] copy];
	NSPageLayout *pageLayout = [NSPageLayout pageLayout];
	[pageLayout beginSheetWithPrintInfo:tempPrintInfo modalForWindow:[self windowForSheet] delegate:self didEndSelector:@selector(didEndPageLayout:returnCode:contextInfo:) contextInfo:(void *)tempPrintInfo];
}

- (void)didEndPageLayout:(NSPageLayout *)pageLayout returnCode:(int)result contextInfo:(void *)contextInfo {
	NSPrintInfo *tempPrintInfo = (NSPrintInfo *)contextInfo;
	if (result == NSOKButton) [self setPrintInfo:tempPrintInfo];
	[tempPrintInfo release];
}




#pragma mark PASTEBOARDS

- (void) copy: (id) sender {
	NSPasteboard * pB = [NSPasteboard generalPasteboard];

	if (self.registeredMode) {
		// PDF pasteboard for registered users
		NSData * pdfData = [NSBezierPath PDFDataForDictionary:[self dictionary]];
		[pB declareTypes:[NSArray arrayWithObjects: NSPDFPboardType, nil] owner:self];
		[pB setData:pdfData forType:NSPDFPboardType];
	}
	else {
		// otherwise just a small bitmap
		[pB declareTypes:[NSArray arrayWithObjects:NSTIFFPboardType, nil] owner: self];
		[pB setData:[self demoTIFFData] forType:NSTIFFPboardType];
	}
}


/*
 returns small bitmap representation of the path for demo copying
*/
- (NSData *) demoTIFFData {
	NSImage * image = [[NSImage alloc] initWithData: [NSBezierPath PDFDataForDictionary:[self dictionary]]];
	image.size = NSMakeSize(384.0, 384.0);
	return image.TIFFRepresentation;
}




#pragma mark MENU BAR

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if (menuItem.action == @selector(exportAsPDF:)) {
		if (self.registeredMode) {
			return YES;
		}
		else {
			return NO;
		}
	}
	else if ([menuItem action] == @selector(setHandles:)) {
		if (self.runningDemo) {
			// cannot change handle setting while demo is running
			menuItem.toolTip = NSLocalizedString(@"This setting cannot be changed while the Demo is running.", @"This setting cannot be changed while the Demo is running");
			return NO;
		}
		else {
			menuItem.toolTip = @"";
			if ([menuItem tag] == self.showHandles) {
				[menuItem setState:NSOnState];
			}
			else {
				[menuItem setState:NSOffState];
			}
			return YES; // menu item is always active
		}
	}
	else if ([menuItem action] == @selector(twoMiddlePoints:)) {
		[menuItem setState:self.twoMidPoints];
		if (self.runningDemo) {
			menuItem.toolTip = NSLocalizedString(@"This setting cannot be changed while the Demo is running.", @"This setting cannot be changed while the Demo is running");
			return NO;
		}
		menuItem.toolTip = @"";
	}
	else if ([menuItem action] == @selector(twoLines:)) {
		[menuItem setState:self.twoLines];
		if (self.runningDemo) {
			menuItem.toolTip = NSLocalizedString(@"This setting cannot be changed while the Demo is running.", @"This setting cannot be changed while the Demo is running");
			return NO;
		}
		menuItem.toolTip = @"";
	}
	else if (menuItem.tag == 100) {
		// menu item with slider
		// NSLog(@"MyDocument -validateMenuItem: slider");
		NSSlider * slider = [menuItem.view.subviews objectAtIndex:0];
		if (self.runningDemo) {
			[slider setEnabled:NO];
			menuItem.toolTip = NSLocalizedString(@"This setting cannot be changed while the Demo is running.", @"This setting cannot be changed while the Demo is running");
		}
		else {
			[slider setEnabled:YES];
			menuItem.toolTip = @"";
		}
		[slider setFloatValue:self.strokeThickness]; // binding this is more complicated than code
		menuItem.menu.delegate = self; // need this to know when the menu has closed
	}
	else if (menuItem.action == @selector(animate:) || menuItem.action == @selector(spaceOut:) ) {
		if (!self.runningAnimation) {
			if (menuItem.action == @selector(animate:)) {
				menuItem.title = NSLocalizedString(@"Animate Path", @"Animate Path");
			}
			else {
				menuItem.title = NSLocalizedString(@"Space Out", @"Space Out");
			}
		}
		else {
			if (!myView.spaceOut || menuItem.action == @selector(animate:) ) {
				menuItem.title = NSLocalizedString(@"Stop Animation", @"Stop Animation");
			}
			else {
				menuItem.title = NSLocalizedString(@"Whoa – stop spacing out!", @"Whoah – stop spacing out!");
			}
		}
		
		if (self.runningDemo) {
			// no animation while running demo
			menuItem.toolTip = NSLocalizedString(@"Animations cannot be started while the Demo is running. Please wait until the Demo has ended or use the Stop Demo command to do so.", @"Animations cannot be started while the Demo is running. Please wait until the Demo has ended or use the Stop Demo command to do so.");
			return NO;
		}
		else {
			menuItem.toolTip = @"";
		}
	}

	return [super validateMenuItem:menuItem];
}


- (IBAction) setHandles:(id) sender {
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		if (self.showHandles == 0) {
			self.showHandles = 1;
		}
		else {
			self.showHandles = 0;
		}
	}
}

- (IBAction) twoMiddlePoints: (id) sender {
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		[self.undoManager registerUndoWithTarget:self selector:@selector(setValuesForUndoFromDictionary:) object:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:self.twoMidPoints] forKey:@"twoMidPoints"]];
		self.twoMidPoints = !self.twoMidPoints;
	}		
}


- (IBAction) twoLines: (id) sender {
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		[self.undoManager registerUndoWithTarget:self selector:@selector(setValuesForUndoFromDictionary:) object:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:self.twoLines] forKey:@"twoLines"]];
		self.twoLines = !self.twoLines;
	}		
}


- (IBAction) exportAsPDF: (id) sender {
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		NSSavePanel * savePanel = [NSSavePanel savePanel];
		savePanel.prompt = NSLocalizedString(@"Export", @"Export as PDF");
		savePanel.requiredFileType = @"pdf";
		[savePanel beginSheetForDirectory:nil file:nil modalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(exportSavePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}		
}


/*
 return function for export sheet
 */
- (void)exportSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {
	if (returnCode == NSOKButton) {
		NSError * myError = nil;
		[self writeToURL:sheet.URL ofType:(NSString*) kUTTypePDF error:&myError];
		
		if (myError) {
			NSBeep();
			NSLog(@"exportSavePanelDidEnd PDF writing failed (%@)", [myError description]);
		}
	}
}



- (IBAction) sliderMoved: (id) sender {
	NSDictionary * strokeThicknessDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:self.previousStrokeThickness]	forKey:@"strokeThickness"];
	if (!self.strokeThicknessRecentChange) {
		// start new undo group if haven't got one already
		[self.undoManager beginUndoGrouping];
		// NSLog(@"newUndoGroup, level: %i", self.undoManager.groupingLevel);
		self.strokeThicknessRecentChange = [NSDate date];
	}
	[self.undoManager registerUndoWithTarget:self selector:@selector(setValuesForUndoFromDictionary:) object:strokeThicknessDict];
}


/*
 close undo group for strokeThickness change when menu closes
 */
- (void) menuDidClose:(NSMenu *)menu {
	// NSLog(@"MyDocument -menuDidClose:");
	if(self.strokeThicknessRecentChange) {
		[self.undoManager endUndoGrouping];
		self.strokeThicknessRecentChange = nil;
	}
}


- (IBAction) bogusAction: (id) sender {
}

@end
