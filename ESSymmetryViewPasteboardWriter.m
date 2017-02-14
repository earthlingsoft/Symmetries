//
//  ESSymmetryViewPasteboardWriter.m
//  Symmetries
//
//  Created by  Sven on 14.02.17.
//
//

#import "ESSymmetryViewPasteboardWriter.h"
#import "NSBezierPath+ESSymmetry.h"

// File Promise in a format accepted by the (X.5?) Finder or GKON 6
#define OLD_PROMISE_TYPE @"com.apple.pasteboard.promised-file-content-type"

@implementation ESSymmetryViewPasteboardWriter

- (NSArray<NSString *> *) writableTypesForPasteboard:(NSPasteboard *)pasteboard {
	return @[
			 ESSYMMETRYPBOARDTYPE, // internal
			 NSFilesPromisePboardType, // e.g. for Preview
			 OLD_PROMISE_TYPE,
			 NSTIFFPboardType,
			 NSPDFPboardType];
}



- (NSPasteboardWritingOptions) writingOptionsForType:(NSString *)type
										  pasteboard:(NSPasteboard *)pasteboard {
	
	if ([type isEqualToString:NSFilesPromisePboardType]
		|| [type isEqualToString:OLD_PROMISE_TYPE]) {
		return NSPasteboardWritingPromised;
	}
	return 0;
}



- (id) pasteboardPropertyListForType:(NSString *)type {
	
	if ([type isEqualToString:ESSYMMETRYPBOARDTYPE]) {
		return [NSArchiver archivedDataWithRootObject:self.documentDictionary];
	}
	else if ([type isEqualToString:NSFilesPromisePboardType]) {
		NSError * error;
		return [NSPropertyListSerialization dataWithPropertyList:@[@"pdf"]
														format:NSPropertyListXMLFormat_v1_0
														 options:0
														   error:&error];
	}
	else if ([type isEqualToString:OLD_PROMISE_TYPE]) {
		return [(NSString *)kUTTypePDF dataUsingEncoding:NSUTF8StringEncoding];
	}
	else if ([type isEqualToString:NSTIFFPboardType]) {
		return [NSBezierPath TIFFDataForDictionary:self.documentDictionary
											  size:self.bitmapSize];
	}
	else if ([type isEqualToString:NSPDFPboardType]) {
		return [NSBezierPath PDFDataForDictionary:self.documentDictionary];
	}
	
	return nil;
}

@end
