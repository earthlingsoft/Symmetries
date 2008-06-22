#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <Cocoa/Cocoa.h>
#include <QuickLook/QuickLook.h>
#include "NSBezierPath+ESSymmetry.h"


OSStatus DrawStuff(CFURLRef url, CGFloat size) {
	NSDictionary * theDict = [NSDictionary dictionaryWithContentsOfURL: (NSURL *)url];
	if (theDict) {
		NSBezierPath * thePath = [NSBezierPath bezierPathWithDictionary:theDict size:size/2.71];	
		NSAffineTransform * moveToMiddle = [NSAffineTransform transform];
		[moveToMiddle translateXBy: size/2.0 yBy: size/2.0];
		[thePath transformUsingAffineTransform:moveToMiddle]; 
		
		// Create the shadow below and to the right of the shape.
		NSShadow* theShadow = [[NSShadow alloc] init];
		[theShadow setShadowOffset:NSMakeSize(size/100.0, -size/100.0)];
		[theShadow setShadowBlurRadius:size/25.0];		
		[theShadow setShadowColor:[[NSColor whiteColor] colorWithAlphaComponent:0.3]]; 
		[theShadow set];		
		
		
		// draw
		if ([[theDict objectForKey:@"twoLines"] boolValue]) {
			[[NSColor lightGrayColor] set];
			[thePath fill];
		}
		[[NSColor blackColor] set];
		[thePath setLineWidth: [[theDict objectForKey:@"strokeThickness"] floatValue] * size / 2.0 / 10.0];
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

