//
//  AppDelegate.m
//  Symmetry
//
//  Created by  Sven on 05.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "AppDelegate.h"
#import "MyDocument.h"
#import "MyDocument+Animation.h"
#import "ESSymmetryView.h"
#import "ESSymmetryView+Intro.h"

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	[[NSDocumentController sharedDocumentController] setAutosavingDelay:10.0];
	srandomdev();
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[(MyDocument*)[[NSDocumentController sharedDocumentController] currentDocument] intro];
}

- (NSDocument*) firstDocument {
	return (NSDocument*) [[NSDocumentController sharedDocumentController] currentDocument];
}




#pragma mark PROPERTIES
- (BOOL) useCoreAnimation {
	NSNumber * n = [[NSUserDefaults standardUserDefaults] valueForKey:@"useCoreAnimation"];
	if (n) {
		return [n boolValue];
	} 
	else {
		return YES;
	}
}

- (void) setUseCoreAnimation: (BOOL) newValue {
	[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:newValue] forKey:@"useCoreAnimation"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark ACTIONS & MENUS


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if ([menuItem tag] == 100) {
		// NSLog(@"AppDelegate -validateMenuItem: slider");
		// menu item with slider
		NSSlider * slider = [menuItem.view.subviews objectAtIndex:0];
		[slider setEnabled:NO];
		[slider setFloatValue:0.0];
		return NO;
	}	
	else if ([menuItem action] == @selector(demo:)) {
		// demo menu item, change text to reflect current state
		if (![self demoIsRunning]) {
			menuItem.title = NSLocalizedString(@"Start Demo", @"Show Demo");
			menuItem.keyEquivalent = @"";
		}
		else {
			menuItem.title = NSLocalizedString(@"Stop Demo", @"Stop Demo");
		}
	}
	return [NSApp validateMenuItem:menuItem];
}


- (BOOL) demoIsRunning {
	BOOL isRunning = NO;

	for (MyDocument * doc in [[NSDocumentController sharedDocumentController] documents]) {
		isRunning = isRunning || doc.runningDemo;
	}
	// NSLog(@"[AppDelegate demoIsRunning] -> %i", isRunning);

	return isRunning;
}


- (IBAction) demo:(id) sender {
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		((NSMenuItem *) sender).keyEquivalent = @".";
		((NSMenuItem *) sender).keyEquivalentModifierMask = NSCommandKeyMask;
	}
	
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



- (IBAction) bogusAction: (id) sender {
}


// for the various actions in the help menu
- (void) readme:(id) sender {
	NSWorkspace * WORKSPACE = [NSWorkspace sharedWorkspace];
	int tag = [sender tag];
	switch (tag) {
		case 1: // earthlingsoft
			[WORKSPACE openURL:[NSURL URLWithString:@"http://earthlingsoft.net/"]];
			break;
		case 2: // Website
			[WORKSPACE openURL:[NSURL URLWithString:@"http://earthlingsoft.net/Symmetries/"]];
			break;
		case 3: // Send Mail
			[WORKSPACE openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:earthlingsoft%%40earthlingsoft.net?subject=Symmetries%%20%@", [self myVersionString]]]];
			break;
		case 4: // Paypal
			[WORKSPACE openURL: [NSURL URLWithString:@"https://www.paypal.com/xclick/business=earthlingsoft%40earthlingsoft.net&item_name=Symmetries&no_shipping=1&cn=Comments&tax=0&currency_code=EUR"]];
			break;
		case 5: // Readme
			[WORKSPACE openFile:[[NSBundle mainBundle] pathForResource:@"readme" ofType:@"html"]];
			break;
	}
}


// return version string
- (NSString*) myVersionString {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}



@end
