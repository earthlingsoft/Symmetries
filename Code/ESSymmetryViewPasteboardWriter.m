//
//  ESSymmetryViewPasteboardWriter.m
//  Symmetries
//
//  Created by Sven on 14.02.17.
//
//

#import "ESSymmetryViewPasteboardWriter.h"
#import "NSBezierPath+ESSymmetry.h"

// File Promise for current applications.
#define PROMISE_PASTEBOARD_TYPE (NSString *)kPasteboardTypeFileURLPromise
// File Promise in a format accepted by the (X.5?) Finder or GKON 6
#define OLD_PROMISE_PASTEBOARD_TYPE @"com.apple.pasteboard.promised-file-content-type"
#define PDF_PASTEBOARD_TYPE NSPasteboardTypePDF
#define TIFF_PASTEBOARD_TYPE NSPasteboardTypeTIFF

@implementation ESSymmetryViewPasteboardWriter

- (NSArray<NSString *> *) writableTypesForPasteboard:(NSPasteboard *)pasteboard {
	return @[
			 ESSYMMETRYPBOARDTYPE, // internal
			 PROMISE_PASTEBOARD_TYPE, // e.g. for the Finder
			 OLD_PROMISE_PASTEBOARD_TYPE,
			 PDF_PASTEBOARD_TYPE,
			 TIFF_PASTEBOARD_TYPE
			 ];
}



- (NSPasteboardWritingOptions) writingOptionsForType:(NSString *)type
										  pasteboard:(NSPasteboard *)pasteboard {
	
	if ([type isEqualToString:PROMISE_PASTEBOARD_TYPE]
		|| [type isEqualToString:OLD_PROMISE_PASTEBOARD_TYPE]) {
		return NSPasteboardWritingPromised;
	}
	return 0;
}



- (id) pasteboardPropertyListForType:(NSString *)type {
	
	if ([type isEqualToString:ESSYMMETRYPBOARDTYPE]) {
		return [NSArchiver archivedDataWithRootObject:self.documentDictionary];
	}
	else if ([type isEqualToString:PROMISE_PASTEBOARD_TYPE]) {
		NSError * error;
		return [NSPropertyListSerialization dataWithPropertyList:@[@"pdf"]
														format:NSPropertyListXMLFormat_v1_0
														 options:0
														   error:&error];
	}
	else if ([type isEqualToString:OLD_PROMISE_PASTEBOARD_TYPE]) {
		return [(NSString *)kUTTypePDF dataUsingEncoding:NSUTF8StringEncoding];
	}
	else if ([type isEqualToString:PDF_PASTEBOARD_TYPE]) {
		return [NSBezierPath PDFDataForDictionary:self.documentDictionary];
	}
	else if ([type isEqualToString:TIFF_PASTEBOARD_TYPE]) {
		return [NSBezierPath TIFFDataForDictionary:self.documentDictionary
											  size:self.bitmapSize];
	}
	
	return nil;
}

@end
