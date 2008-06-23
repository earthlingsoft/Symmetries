//
//  AppDelegate.m
//  Symmetry
//
//  Created by  Sven on 05.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	[[NSDocumentController sharedDocumentController] setAutosavingDelay:10.0];
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

- (IBAction) setCoreAnimation:(id) sender {
	self.useCoreAnimation = !self.useCoreAnimation;
	[sender setState: (self.useCoreAnimation) ? (NSOnState) : (NSOffState)];
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if ([menuItem tag] == 100) {
		NSLog(@"AppDelegate -validateMenuItem: slider");
		// menu item with slider
		NSSlider * slider = [menuItem.view.subviews objectAtIndex:0];
		[slider setEnabled:NO];
		[slider setFloatValue:0.0];
		return NO;
	}	
	return [NSApp validateMenuItem:menuItem];
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
			[WORKSPACE openURL: [NSURL URLWithString:@"https://www.paypal.com/xclick/business=earthlingsoft%40earthlingsoft.net&item_name=Mailboxer&no_shipping=1&cn=Comments&tax=0&currency_code=EUR"]];
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
