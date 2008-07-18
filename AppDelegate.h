//
//  AppDelegate.h
//  Symmetries
//
//  Created by  Sven on 05.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define SYMMETRIESUNREGISTEREDCORNERCOUNT 4
#define ESSYM_LAUNCHCOUNT_KEY @"number of launches"

@interface AppDelegate : NSObject {
	IBOutlet NSMenuItem * startAnimationMenuItem;
	IBOutlet NSMenuItem * spaceOutMenuItem;	
	IBOutlet NSMenuItem * demoMenuItem;
}

@property (readonly) NSDocument * firstDocument;
@property (readonly) BOOL demoIsRunning;
@property (readwrite) BOOL useCoreAnimation;
@property (readonly) BOOL isRegistered;
@property (readonly) NSString * payPalURL;

- (IBAction) demo:(id) sender;
- (void) demoStarted;
- (void) demoStopped;

- (IBAction) bogusAction: (id) sender;

- (void) readme:(id) sender;
- (NSString *) myVersionString;

- (IBAction) orderFrontStandardAboutPanel:(id)sender;
@end


@interface AppDelegate (ESLicensingKeyProvider)
- (NSString *) publicKey;
@end

@interface AppDelegate (ESLicensingErrorButtons)
- (NSArray*) licenseFailureRecoveryButtons;
@end


