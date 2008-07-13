//
//  AppDelegate.h
//  Symmetry
//
//  Created by  Sven on 05.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define SYMMETRIESREGISTRATIONPROTOCOLNAME @"symmetries-registration"
#define SYMMETRIESUNREGISTEREDCORNERCOUNT 4

@interface AppDelegate : NSObject {
	IBOutlet NSMenuItem * startAnimationMenuItem;
	IBOutlet NSMenuItem * spaceOutMenuItem;	
	
	BOOL registrationWasVerified;
}

@property (readonly) NSDocument * firstDocument;
@property (readonly) BOOL demoIsRunning;
@property (readwrite) BOOL useCoreAnimation;
@property (readonly) BOOL isRegistered;

- (IBAction) demo:(id) sender;
- (void) readme:(id) sender;
- (NSString *) myVersionString;

- (void) processRegistration: (NSString *) s;

@end
