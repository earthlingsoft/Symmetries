//
//  AppDelegate.m
//  Symmetries
//
//  Created by  Sven on 05.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "AppDelegate.h"
#import "MyDocument.h"
#import "MyDocument+Animation.h"
#import "ESSymmetryView.h"
#import "ESSymmetryView+Intro.h"
#import <IOKit/pwr_mgt/IOPMLib.h>

#define EARTHLINGSOFTWEBPAGE @"https://earthlingsoft.net/"
#define SYMMETRIESWEBPAGE @"https://earthlingsoft.net/Symmetries/"
#define GITHUBURL @"https://github.com/ssp/Symmetries"


@interface AppDelegate () {
    NSNumber * _demoPowerAssertionID; // contains a IOPMAssertionID
}
@end


@implementation AppDelegate


#pragma mark DELEGATE METHODS

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	[NSDocumentController sharedDocumentController].autosavingDelay = 10.0;
	srandomdev();
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	const NSUInteger launchCount = [[NSUserDefaults standardUserDefaults] integerForKey:ESSYM_LAUNCHCOUNT_KEY];
	[[NSUserDefaults standardUserDefaults] setInteger: launchCount + 1 forKey:ESSYM_LAUNCHCOUNT_KEY];

	if (launchCount < 10) {
		// not a long time user
		MyDocument * doc = [NSDocumentController sharedDocumentController].currentDocument;
		if (! doc.fileURL) {
			// the document is an untitled one (we didn't launch by opening an existing file)
			[doc intro];
		}
		
	}
	
}




#pragma mark PROPERTIES
- (BOOL) useCoreAnimation {
	NSNumber * n = [[NSUserDefaults standardUserDefaults] valueForKey:@"useCoreAnimation"];
	if (n) {
		return n.boolValue;
	} 
	else {
		return YES;
	}
}

- (void) setUseCoreAnimation: (BOOL) newValue {
	[[NSUserDefaults standardUserDefaults] setValue:@(newValue) forKey:@"useCoreAnimation"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


- (NSDocument*) firstDocument {
	return (NSDocument*) [NSDocumentController sharedDocumentController].currentDocument;
}





#pragma mark ACTIONS & MENUS


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if (menuItem.tag == 100) {
		// NSLog(@"AppDelegate -validateMenuItem: slider");
		// menu item with slider
		const NSSlider * slider = (menuItem.view.subviews)[0];
		[slider setEnabled:NO];
		slider.floatValue = 0.0;
		return NO;
	}	
	else if (menuItem.action == @selector(demo:)) {
		// demo menu item, change text to reflect current state
		if (!self.demoIsRunning) {
			menuItem.title = NSLocalizedString(@"Start Demo", @"Show Demo");
			// NSLog(@"[AppDelegate validateMenuItem:] new name is %@",  NSLocalizedString(@"Start Demo", @"Show Demo"));
		}
		else {
			menuItem.title = NSLocalizedString(@"Stop Demo", @"Stop Demo");
			// NSLog(@"[AppDelegate validateMenuItem:] new name is %@",  NSLocalizedString(@"Stop Demo", @"Stop Demo"));
		}
	}
	return [NSApp validateMenuItem:menuItem];
}



- (BOOL) demoIsRunning {
	BOOL isRunning = NO;

	for (MyDocument * doc in [NSDocumentController sharedDocumentController].documents) {
		isRunning = isRunning || doc.runningDemo;
	}
	// NSLog(@"[AppDelegate demoIsRunning] -> %i", isRunning);

	return isRunning;
}



- (IBAction) demo:(id) sender {
	if (self.demoIsRunning) {
		// NSLog(@"[AppDelegate demo:] stopping Demo");
		// stop demo
		
		MyDocument * doc;
		for (doc in [NSDocumentController sharedDocumentController].documents) {
			if (doc.runningDemo) {
				[doc.myView endDemo:sender];
				break;
			}
		}
	}
	else {
		// NSLog(@"[AppDelegate demo:] starting Demo");
		// start demo

		NSDocumentController * dC = [NSDocumentController sharedDocumentController];
		if (dC.documents.count == 0 ) {
			// create a document if there is none
			[dC openUntitledDocumentAndDisplay:YES error:NULL];
		}
			
		MyDocument * document = (MyDocument *) dC.currentDocument;
		
		if (document.runningAnimation) {
			// turn off animation if necessary
			[document stopAnimation:self];
		}
		
		[(ESSymmetryView*) document.myView startDemo:sender];
	}
}



- (void) demoStarted {
    [self preventDisplaySleepForReason:@"Running the Symmetries Demo"];
	demoMenuItem.keyEquivalent = @".";
	demoMenuItem.keyEquivalentModifierMask = NSCommandKeyMask;
}



- (void) demoStopped {
    [self removePowerAssertion:_demoPowerAssertionID];

	if (!self.demoIsRunning) {
		demoMenuItem.keyEquivalent = @"";
	}
}



- (void) preventDisplaySleepForReason:(NSString * _Nonnull)reason {
    if (_demoPowerAssertionID != nil) {
        [self removePowerAssertion:_demoPowerAssertionID];
    }

    IOPMAssertionID assertionID;
    IOReturn success = IOPMAssertionCreateWithName(
                                                   kIOPMAssertionTypeNoDisplaySleep, // AssertionType
                                                   kIOPMAssertionLevelOn, // AssertionLevel
                                                   (__bridge CFStringRef)(reason),
                                                   &assertionID);

    if (success == kIOReturnSuccess) {
        _demoPowerAssertionID = @(assertionID);
    }
}



- (void) removePowerAssertion:(NSNumber * _Nullable)assertionIDContainer {
    if (assertionIDContainer != nil) {
        IOPMAssertionID assertionID = assertionIDContainer.intValue;
        IOReturn success = IOPMAssertionRelease(assertionID);
        if (success == kIOReturnSuccess) {
            _demoPowerAssertionID = nil;
        } else {
            NSLog(@"Could not release Power Assertion %i", assertionID);
        }
    }
}



- (IBAction) bogusAction: (id) sender {
}



// for the various actions in the help menu
- (void) readme:(id) sender {
	const NSWorkspace * WORKSPACE = [NSWorkspace sharedWorkspace];
	const NSInteger tag = [sender tag];
	switch (tag) {
		case 1: // earthlingsoft
			[WORKSPACE openURL:[NSURL URLWithString:EARTHLINGSOFTWEBPAGE]];
			break;
		case 2: // Website
			[WORKSPACE openURL:[NSURL URLWithString:SYMMETRIESWEBPAGE]];
			break;
		case 3: // Send Mail
			[WORKSPACE openURL:[NSURL URLWithString:self.emailURL]];
			break;
		case 4: // Paypal
			[WORKSPACE openURL: [NSURL URLWithString:self.payPalURL]];
			break;
		case 5: // Readme
			[WORKSPACE openFile:[[NSBundle mainBundle] pathForResource:@"Help" ofType:@"html"]];
			break;
		case 6: // github
			[WORKSPACE openURL:[NSURL URLWithString:GITHUBURL]];
			break;
	}
}



// return version string
- (NSString*) myVersionString {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}



- (IBAction) orderFrontStandardAboutPanel:(id)sender {
	NSString * HTMLPath = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"html"];
	NSString * HTML = [NSString stringWithContentsOfFile:HTMLPath encoding:NSUTF8StringEncoding error:nil];
	
	// adjust Credits text for current licensing status
	HTML = [NSString stringWithFormat:HTML,
			SYMMETRIESWEBPAGE,
			self.emailURL,
			GITHUBURL,
			self.payPalURL];
	
	NSAttributedString * HTMLString = [[NSAttributedString alloc] initWithHTML:[HTML dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:nil];
	
	NSDictionary * options = @{@"Credits": HTMLString};
	[NSApp orderFrontStandardAboutPanelWithOptions:options];
}



- (NSString *) payPalURL {
	return NSLocalizedString(@"PayPalURL", @"the URL to go to when selecting to donate in the about box or help menu");	
}

- (NSString *) emailURL {
	return [NSString stringWithFormat:@"mailto:earthlingsoft%%40earthlingsoft.net?subject=Symmetries%%20%@", [self myVersionString]];
}

@end
