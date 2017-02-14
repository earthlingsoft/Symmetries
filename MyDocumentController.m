//
//  MyDocumentController.m
//  ASCII Projektor 2b
//
//  Created by  Sven on 23.08.07.
//  Copyright 2007 earthlingsoft. All rights reserved.
//

#import "MyDocumentController.h"
#import "MyDocument.h"


/* Mostly nicked from TextEdit and slightly adapted */

@implementation MyDocumentController

- (NSDocument *)transientDocumentToReplace {
    NSArray<NSDocument *> *documents = self.documents;
	NSUInteger openDocuments = documents.count;
	if(openDocuments == 1) {
		NSDocument * theDoc = documents.firstObject;
		if (!theDoc.isDocumentEdited) {
			return theDoc;
		}
	}
	return nil;
}

- (void)replaceTransientDocument:(NSDocument *)transientDoc withDocument:(NSDocument *)doc display:(BOOL)displayDocument {
    NSArray *controllersToTransfer = [[transientDoc windowControllers] copy];
    NSEnumerator *controllerEnum = [controllersToTransfer objectEnumerator];
    NSWindowController *controller;
    
    while (controller = [controllerEnum nextObject]) {
		[doc addWindowController:controller];
		[transientDoc removeWindowController:controller];
    }
    [transientDoc close];

    if (displayDocument) {
		[doc makeWindowControllers];
		[doc showWindows];
    }
}



/*
 Then check to see whether there is a document that is already open, and whether it is transient. If so, transfer the document's window controllers and close the transient document.
*/
- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL display:(BOOL)displayDocument error:(NSError **)outError {
	
	NSDocument *doc = nil;
	NSString *documentType = [[NSDocumentController sharedDocumentController] typeForContentsOfURL:absoluteURL error:outError];

	if ([documentType isEqualToString: ESSYM_SYMMETRY_UTI]) {	
		// we are dealing with a document here => special handling
		NSDocument *transientDoc = [self transientDocumentToReplace];
		// NSLog([absoluteURL description]);
		if (transientDoc) {
			[transientDoc readFromURL:absoluteURL ofType:[[NSDocumentController sharedDocumentController] typeForContentsOfURL:absoluteURL error:outError] error:outError];
			doc = transientDoc;
			[doc setFileURL:absoluteURL];
		}
		if (!doc) { // do this if there is no document to replace OR if replacing failed
			doc = [super openDocumentWithContentsOfURL:absoluteURL display:(displayDocument && !transientDoc) error:outError];
		}
	}
	else {
		// not a document => standard handling
		doc = [super openDocumentWithContentsOfURL:absoluteURL display:displayDocument error:outError];
	}

    return doc;
}


@end
