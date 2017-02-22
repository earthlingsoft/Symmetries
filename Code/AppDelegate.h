//
//  AppDelegate.h
//  Symmetries
//
//  Created by  Sven on 05.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ESSYM_LAUNCHCOUNT_KEY @"number of launches"

@interface AppDelegate : NSObject {
	IBOutlet NSMenuItem * startAnimationMenuItem;
	IBOutlet NSMenuItem * spaceOutMenuItem;	
	IBOutlet NSMenuItem * demoMenuItem;
}

@property (readonly) NSDocument * firstDocument;
@property (readonly) BOOL demoIsRunning;
@property (readwrite) BOOL useCoreAnimation;
@property (readonly) NSString * payPalURL;
@property (NS_NONATOMIC_IOSONLY, readonly) NSString * myVersionString;

- (IBAction) demo:(id) sender;
- (void) demoStarted;
- (void) demoStopped;

- (IBAction) bogusAction: (id) sender;

- (void) readme:(id) sender;

- (IBAction) orderFrontStandardAboutPanel:(id)sender;

@end
