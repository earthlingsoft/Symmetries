//
//  ESSymmetryViewPasteboardWriter.h
//  Symmetries
//
//  Created by  Sven on 14.02.17.
//
//

#import <Cocoa/Cocoa.h>

#define ESSYMMETRYPBOARDTYPE @"ESSSymmetryPboardType"



@interface ESSymmetryViewPasteboardWriter : NSObject <NSPasteboardWriting> {
	
}

@property (retain) NSDictionary * documentDictionary;
@property CGFloat bitmapSize;

@end
