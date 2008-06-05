//
//  AppDelegate.m
//  RoundRect
//
//  Created by  Sven on 05.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
}


- (NSDocument*) firstDocument {
	return (NSDocument*) [[NSDocumentController sharedDocumentController] currentDocument];
}


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




- (IBAction) setCoreAnimation:(id) sender {
	self.useCoreAnimation = !self.useCoreAnimation;
	[sender setState: (self.useCoreAnimation) ? (NSOnState) : (NSOffState)];
}

@end
