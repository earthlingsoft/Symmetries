//
//  MyDocument.m
//  Symmetry
//
//  Created by  Sven on 22.05.08.
//  Copyright earthlingsoft 2008 . All rights reserved.
//

#import "MyDocument.h"
#import "NSBezierPath+ESSymmetry.h"

@implementation MyDocument

@synthesize size, twoMidPoints, twoLines, cornerFraction, straightTangentLength, straightTangentDirection, diagonalTangentLength, diagonalTangentDirection, midPointsDistance, thickness, thickenedCorner, backgroundColor, strokeColor, fillColor, strokeThickness, cornerCount, showHandles, myView, strokeThicknessRecentChange, previousStrokeThickness;


# pragma mark HOUSEKEEPING

- (id)init
{
    return [self initWithDictionary: [self initialValues]];
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
			[NSNumber numberWithBool:YES ], @"twoMidPoints",
			[NSNumber numberWithBool:YES ], @"twoLines",
			[NSNumber numberWithInt:4], @"cornerCount",
			[NSNumber numberWithFloat: 0.71], @"cornerFraction",
			[NSNumber numberWithFloat: 0.8], @"straightTangentLength",
			[NSNumber numberWithFloat: 0.0], @"straightTangentDirection",
			[NSNumber numberWithFloat: 0.07], @"diagonalTangentLength",
			[NSNumber numberWithFloat: 1.0], @"diagonalTangentDirection",
			[NSNumber numberWithFloat: 0.5], @"midPointsDistance",
			[NSNumber numberWithFloat: 0.2], @"thickness",
			[NSNumber numberWithFloat: 0.01], @"thickenedCorner",
			[NSColor whiteColor], @"backgroundColor",
			[NSColor blackColor], @"strokeColor",
			[NSColor lightGrayColor], @"fillColor",
			[NSNumber numberWithFloat: 0.141], @"strokeThickness",
			[NSNumber numberWithUnsignedInt: 1 ], @"showHandles",
			nil];
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
	NSDictionary * dict = [self plistDictionary];
	BOOL writeOK;
	if (dict) {
		writeOK = [dict writeToURL:absoluteURL atomically:YES];
	}
	
	if ( !dict ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}

	return (dict && writeOK);
}


- (NSDictionary *)fileAttributesToWriteToFile:(NSString *)fullDocumentPath ofType:(NSString *)documentTypeName saveOperation:(NSSaveOperationType)saveOperationType
{
	NSMutableDictionary *myDict= [NSMutableDictionary dictionaryWithDictionary:[super fileAttributesToWriteToFile:fullDocumentPath ofType:documentTypeName saveOperation:saveOperationType]];
	
	[myDict setObject:[NSNumber numberWithLong:'esRR'] forKey:NSFileHFSCreatorCode];
	[myDict setObject:[NSNumber numberWithLong:'esRR'] forKey:NSFileHFSTypeCode];
	
	return myDict;
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
	 if ([object isEqual:self]) {
		 [self.myView setNeedsDisplay:YES];
		 if ([keyPath isEqualToString:@"strokeThickness"]) {
			 self.previousStrokeThickness = [[change objectForKey:NSKeyValueChangeOldKey] floatValue];
		 }
	 }
 }



#pragma mark PASTEBOARDS

- (void) copy: (id) sender {
	NSData * pdfData = [NSBezierPath PDFDataForDictionary:[self dictionary]];
	NSPasteboard * pb = [NSPasteboard generalPasteboard];
	[pb declareTypes:[NSArray arrayWithObjects: NSPDFPboardType, nil] owner:self];
	[pb setData:pdfData forType:NSPDFPboardType];
}




#pragma mark PRINTING

- (void)printDocumentUsingPrintPanel:(BOOL)uiFlag {
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




#pragma mark MENU BAR
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if ([menuItem action] == @selector(setHandles:)) {
		if ([menuItem tag] == self.showHandles) {
			[menuItem setState:NSOnState];
		}
		else {
			[menuItem setState:NSOffState];
		}
		return YES; // menu item is always active
	}
	else if ([menuItem action] == @selector(twoMiddlePoints:)) {
		[menuItem setState:self.twoMidPoints];
	}
	else if ([menuItem action] == @selector(twoLines:)) {
		[menuItem setState:self.twoLines];
	}
	else if ([menuItem tag] == 100) {
		// menu item with slider
		// NSLog(@"MyDocument -validateMenuItem: slider");
		NSSlider * slider = [menuItem.view.subviews objectAtIndex:0];
		[slider setEnabled:YES];
		[slider setFloatValue:self.strokeThickness];
		menuItem.menu.delegate = self; // need this to know when the menu has closed
	}
	return [super validateMenuItem:menuItem];
}


- (IBAction) setHandles:(id) sender {
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		if (self.showHandles != [sender tag]) {
			self.showHandles = [sender tag];
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
		NSURL  * destinationURL =  sheet.URL;
		NSData * pdfData = [NSBezierPath PDFDataForDictionary:[self dictionary]];
		[pdfData writeToURL:destinationURL atomically:YES];
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
- (void)menuDidClose:(NSMenu *)menu {
	// NSLog(@"MyDocument -menuDidClose:");
	if(self.strokeThicknessRecentChange) {
		[self.undoManager endUndoGrouping];
		self.strokeThicknessRecentChange = nil;
	}
}

- (IBAction) bogusAction: (id) sender {
}


@end
