#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <Cocoa/Cocoa.h>
#include <QuickLook/QuickLook.h>
#include "NSBezierPath+ESSymmetry.h"


OSStatus DrawStuff(CFURLRef url, CGFloat size) {
	NSDictionary * theDict = [NSDictionary dictionaryWithContentsOfURL: (__bridge NSURL *)url];
	if (theDict) {
		NSBezierPath * thePath = [NSBezierPath bezierPathWithDictionary:theDict size:1.0];
		NSRect pathBounds = thePath.bounds;		
		CGFloat mainStrokeThickness = [theDict[@"strokeThickness"] floatValue] * size / 2. / 10.;
		CGFloat haloStrokeThickness = mainStrokeThickness + 3. ;
		CGFloat maxSize =  MAX(MAX(MAX(pathBounds.size.width, pathBounds.size.height), 2. * fabs(pathBounds.origin.x)), fabs(pathBounds.origin.y));

		NSAffineTransform * scaleToUnitSize = [NSAffineTransform transform];
		[scaleToUnitSize scaleBy: size / maxSize - haloStrokeThickness - 10. ];
		
		NSAffineTransform * translate = [NSAffineTransform transform];
		[translate translateXBy: .5 * size yBy: .5 * size];
		
		[scaleToUnitSize appendTransform:translate];
		[thePath transformUsingAffineTransform:scaleToUnitSize];
		
		// draw halo
		thePath.lineWidth = haloStrokeThickness;
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.6] set];
		[thePath stroke];
		
		// draw path
		if ([theDict[@"twoLines"] boolValue]) {
			[[NSColor lightGrayColor] set];
			[thePath fill];
		}
		[[NSColor blackColor] set];
		thePath.lineWidth = mainStrokeThickness;
		[thePath stroke];
		
		return noErr;
	}	
	else { 
		return 1111;
	}
}


/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
	CGFloat size = MIN(maxSize.width, maxSize.height);
	CGSize mySize = CGSizeMake(size, size);

	CGContextRef CGGraphicsContext = QLThumbnailRequestCreateContext(thumbnail, mySize, 0, NULL);
	NSGraphicsContext * graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:CGGraphicsContext flipped:NO];
	[NSGraphicsContext setCurrentContext:graphicsContext];
	
	OSStatus myError = DrawStuff(url, size);
	
	QLThumbnailRequestFlushContext(thumbnail, CGGraphicsContext); 
	CGContextRelease(CGGraphicsContext);
		
	return myError;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}




/* -----------------------------------------------------------------------------
 Generate a preview for file
 
 This function's job is to create preview for designated file
 ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	CGSize size = CGSizeMake(512.0, 512.0);
	CGContextRef CGGraphicsContext = QLPreviewRequestCreateContext(preview, size, 0, NULL);
	NSGraphicsContext * graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:CGGraphicsContext flipped:NO];
	[NSGraphicsContext setCurrentContext:graphicsContext];
	
	OSStatus myError = DrawStuff(url, size.width);
	
	QLPreviewRequestFlushContext(preview, CGGraphicsContext); 
	CGContextRelease(CGGraphicsContext);
	
	return myError;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}

