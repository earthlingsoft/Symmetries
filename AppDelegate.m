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
#import "ESLicense.h"


#define SYMMETRIESPUBLICKEY @"-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAw257efIv+R8VMH+lwtDA\nSwiGIDutsCWS0WzmaJmtb/Uy4LHAAqe8z8Do7A2QUf3cfyfkvI2Ci45dq+YHx6Vf\n2+78rAmKUxgcEAOa/ZHF5AgofV+rMQS5oOrWgWXVeru8seqMOyeic7y50prAf04m\nrRvBAnPqKLpXxaI+00NggpZcHcryvTFxefKo29atD420o36aYLmjuUqoq3kF4ok6\n9tC1ecTMWcxtqS2Qw9on1SnNs8Y6S6qdH0Mm1rx1TgBlI7X5zbUtuuieU0ftZidB\nsfS6MG+Z6Aav+EALrRcGtlUweF/BsAIn98163gPr0nRIL++5yUpVR7bazurNIUs1\nVQIDAQAB\n-----END PUBLIC KEY-----" 

@implementation AppDelegate

#pragma mark DELEGATE METHODS
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	[[NSDocumentController sharedDocumentController] setAutosavingDelay:10.0];
	srandomdev();
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	const NSUInteger launchCount = [[NSUserDefaults standardUserDefaults] integerForKey:ESSYM_LAUNCHCOUNT_KEY];
	[[NSUserDefaults standardUserDefaults] setInteger: launchCount + 1 forKey:ESSYM_LAUNCHCOUNT_KEY];

	if (launchCount < 10) {
		// not a long time user
		MyDocument * doc = [[NSDocumentController sharedDocumentController] currentDocument];
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


- (NSDocument*) firstDocument {
	return (NSDocument*) [[NSDocumentController sharedDocumentController] currentDocument];
}





#pragma mark ACTIONS & MENUS


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if ([menuItem tag] == 100) {
		// NSLog(@"AppDelegate -validateMenuItem: slider");
		// menu item with slider
		const NSSlider * slider = [menuItem.view.subviews objectAtIndex:0];
		[slider setEnabled:NO];
		[slider setFloatValue:0.0];
		return NO;
	}	
	else if ([menuItem action] == @selector(demo:)) {
		// demo menu item, change text to reflect current state
		if (![self demoIsRunning]) {
			menuItem.title = NSLocalizedString(@"Start Demo", @"Show Demo");
			NSLog(@"[AppDelegate validateMenuItem:] new name is %@",  NSLocalizedString(@"Start Demo", @"Show Demo"));
		}
		else {
			menuItem.title = NSLocalizedString(@"Stop Demo", @"Stop Demo");
			NSLog(@"[AppDelegate validateMenuItem:] new name is %@",  NSLocalizedString(@"Stop Demo", @"Stop Demo"));
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
	if (self.demoIsRunning) {
		NSLog(@"[AppDelegate demo:] stopping Demo");
		// stop demo
		
		MyDocument * doc;
		for (doc in [[NSDocumentController sharedDocumentController] documents]) {
			if (doc.runningDemo) {
				[doc.myView endDemo:sender];
				break;
			}
		}
	}
	else {
		NSLog(@"[AppDelegate demo:] starting Demo");
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
	demoMenuItem.keyEquivalent = @".";
	demoMenuItem.keyEquivalentModifierMask = NSCommandKeyMask;
}



- (void) demoStopped {
	if (!self.demoIsRunning) {
		demoMenuItem.keyEquivalent = @"";
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
			[WORKSPACE openURL:[NSURL URLWithString:@"http://earthlingsoft.net/"]];
			break;
		case 2: // Website
			[WORKSPACE openURL:[NSURL URLWithString:@"http://earthlingsoft.net/Symmetries/"]];
			break;
		case 3: // Send Mail
			[WORKSPACE openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:earthlingsoft%%40earthlingsoft.net?subject=Symmetries%%20%@", [self myVersionString]]]];
			break;
		case 4: // Paypal
			[WORKSPACE openURL: [NSURL URLWithString:self.payPalURL]];
			break;
		case 5: // Readme
			[WORKSPACE openFile:[[NSBundle mainBundle] pathForResource:@"Help" ofType:@"html"]];
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
	NSString * registrationInfo = @"";
	NSString * startComment = @"";
	NSString * endComment = @"";
	
	if (self.isRegistered) {
		NSString * registeredName = [[ESLicenser licenser] userName];
		
		registrationInfo = [NSString stringWithFormat:@"<h3>%@</h3>\n<p>%@<br></p>\n",
							NSLocalizedString(@"Registered to", @"Heading for registration info in About box"),
							registeredName];
		startComment = @"<!-- ";	
		endComment = @" -->";
	}
	
	// adjust Credits text for current licensing status
	HTML = [NSString stringWithFormat:HTML, startComment, endComment, registrationInfo, self.payPalURL];
	
	NSAttributedString * HTMLString = [[NSAttributedString alloc] initWithHTML:[HTML dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:nil];
	
	NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:HTMLString, @"Credits", nil];
	[NSApp orderFrontStandardAboutPanelWithOptions:options];
}



- (NSString *) payPalURL {
	return NSLocalizedString(@"PayPalURL", @"the URL to go to when selecting to register in the about box or help menu");	
}


- (BOOL) isRegistered {
	return [[ESLicenser licenser] isLicensed];
}

@end



#pragma mark ESLICENSING PROTOCOLS


@implementation AppDelegate (ESLicensingKeyProvider)

- (NSString *) publicKey {
	return SYMMETRIESPUBLICKEY;
}

@end


@implementation AppDelegate (ESLicensingErrorButtons)
- (NSArray*) licenseFailureRecoveryButtons {
	return [NSArray arrayWithObject:NSLocalizedString(@"E-Mail earthlingsoft", @"E-Mail earthlingsoft button when failing to open registration file.")];
}
@end


@implementation AppDelegate (NSErrorRecoveryAttempting)
/* we won't have errors in sheets, so this method is sufficient */
- (BOOL) attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex {
	if ([error.domain isEqualToString:ESLICENSE_ERRORDOMAIN]) {
		NSString * subject = NSLocalizedString(@"Symmetries license problem", @"Subject of e-mail sent when there is a problem with the license");
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:earthlingsoft%%40earthlingsoft.net?subject=%@", [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
	}
	return YES;
}
@end

