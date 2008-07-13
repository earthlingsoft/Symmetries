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
#import <SSCrypto/SSCrypto.h>

#define SYMMETRIESREGISTRATIONNAMEKEY @"name"
#define SYMMETRIESREGISTRATIONMAILKEY @"e-mail"
#define SYMMETRIESREGISTRATIONSERIALKEY @"registration code"
#define SYMMETRIESREGISTRATIONDEFAULTSKEY @"registration"
#define SYMMETRIESPUBLICKEY @"-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBANV1q4F0HhfEWCuKp29Z/JuruPj/8AH6\nMNUhBNfXu/kh+fQCj64W7CkRfdZXIOn/Q/dmmRueFwKu7QcNB+lKJacCAwEAAQ==\n-----END PUBLIC KEY-----" 

@implementation AppDelegate

#pragma mark DELEGATE METHODS
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	[[NSDocumentController sharedDocumentController] setAutosavingDelay:10.0];
	srandomdev();
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

	[(MyDocument*)[[NSDocumentController sharedDocumentController] currentDocument] intro];
}



#pragma mark URL handling

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent{
    NSString *theURLString = [[event descriptorForKeyword:keyDirectObject] stringValue];
    NSURL *theURL = nil;
    
    if (theURLString) {
        if ([theURLString hasPrefix:@"<"] && [theURLString hasSuffix:@">"])
            theURLString = [theURLString substringWithRange:NSMakeRange(0, [theURLString length] - 2)];
        if ([theURLString hasPrefix:@"URL:"])
            theURLString = [theURLString substringFromIndex:4];
        theURL = [NSURL URLWithString:theURLString];
        if (theURL == nil)
            theURL = [NSURL URLWithString:theURLString];
    }
    
    if ([[theURL scheme] isEqualToString:@"symmetries-registration"]) {
        [self processRegistration:theURLString];
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
		NSSlider * slider = [menuItem.view.subviews objectAtIndex:0];
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
	NSLog(@"[AppDelegate demoIsRunning] -> %i", isRunning);

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


- (IBAction) orderFrontStandardAboutPanel:(id)sender {
	NSString * HTMLPath = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"html"];
	NSString * HTML = [NSString stringWithContentsOfFile:HTMLPath encoding:NSUTF8StringEncoding error:nil];
	NSString * registrationInfo = @"";
	if (self.isRegistered) {
		NSString * registeredName = @"";
		NSDictionary * regDict = [[NSUserDefaults standardUserDefaults] valueForKey:SYMMETRIESREGISTRATIONDEFAULTSKEY];
		if (regDict) {
			registeredName = [regDict objectForKey: SYMMETRIESREGISTRATIONNAMEKEY];
			if (!registeredName) {
				registeredName = @"";
			}
		}
		
		registrationInfo = [NSString stringWithFormat:@"<h3>%@</h3>\n<p>%@<br></p>\n",
							NSLocalizedString(@"Registered to", @"Heading for registration info in About box"),
							registeredName];
	}

	HTML = [HTML stringByReplacingOccurrencesOfString:@"@@@@@" withString:registrationInfo];
	NSAttributedString * HTMLString = [[NSAttributedString alloc] initWithHTML:[HTML dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:nil];
	
	NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:HTMLString, @"Credits", nil];
	[NSApp orderFrontStandardAboutPanelWithOptions:options];
}





#pragma mark REGISTRATION 

- (void) processRegistration: (NSString*) s {
	NSString * decodedURL = (NSString*) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (CFStringRef) s, CFSTR(""), kCFStringEncodingUTF8);
	NSScanner * scanner = [NSScanner scannerWithString:decodedURL];
	// URL is of form symmetries-registration://NAME/EMAIL/SERIAL
	// ignore protocol
	scanner.scanLocation = [SYMMETRIESREGISTRATIONPROTOCOLNAME length] + 3;
	// get name and mail, omitting the /
	NSString * name;
	[scanner scanUpToString:@"/" intoString:&name];
	scanner.scanLocation = scanner.scanLocation + 1;
	NSString * mail;
	[scanner scanUpToString:@"/" intoString:&mail];
	scanner.scanLocation = scanner.scanLocation + 1;
	NSString * serial;
	// make the somewhat silly assumption that our serial code always ends in ==
	[scanner scanUpToString:@"==" intoString:&serial];
	serial = [serial stringByAppendingString:@"=="];
	
	BOOL FAIL = !(name && mail && serial);

	
	if (!FAIL) {
		NSData *publicKeyData = [SYMMETRIESPUBLICKEY dataUsingEncoding:NSASCIIStringEncoding];
		
		NSString *details = [NSString stringWithFormat:@"%@::%@", name, mail];
		NSData *number = [[serial dataUsingEncoding:NSUTF8StringEncoding] decodeBase64WithNewLines:NO];
		
		SSCrypto *crypto = [[SSCrypto alloc] initWithPublicKey:publicKeyData];
		[crypto setCipherText:number];
		
		[crypto verify];
		BOOL signatureVerified = [[crypto clearTextAsString] isEqualToString:details];
		[crypto release];
		
		if(signatureVerified) {
			// registration succeeded
			NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:
				name, SYMMETRIESREGISTRATIONNAMEKEY,
				mail, SYMMETRIESREGISTRATIONMAILKEY,
				serial, SYMMETRIESREGISTRATIONSERIALKEY,
								   nil];
			
			[[NSUserDefaults standardUserDefaults] setValue:dict forKey:SYMMETRIESREGISTRATIONDEFAULTSKEY];
			[[NSUserDefaults standardUserDefaults] synchronize];
			
			NSAlert * alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Symmetries is registered.", @"Successful Registration Dialogue Title") 
					defaultButton:NSLocalizedString(@"OK", @"OK")
					alternateButton:nil
					otherButton:nil 
					informativeTextWithFormat:NSLocalizedString(@"Thank you for your support.\n\nThe full range of export features is now available.", @"Successful Registration Dialogue Explanation")
							   ];
			[alert runModal];
		}
		else {
			// registration failed
			FAIL = YES;
		}
	}

	if (FAIL) {		
		NSAlert * alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Invalid registration code.", @"Failed Registration Dialogue Title") 
											  defaultButton:NSLocalizedString(@"Bummer", @"Bummer")
											alternateButton:nil
												otherButton:nil 
								  informativeTextWithFormat:NSLocalizedString(@"The registration code Symmetries received was invalid.", @"Failed Registration Dialogue Explanation")
							   ];
			[alert runModal];
	}
	
}


- (BOOL) isRegistered {
	BOOL registered = NO;
	
	if (registrationWasVerified) {
		registered = YES;
	}
	else {
		// verify registration
		NSDictionary * regDict = [[NSUserDefaults standardUserDefaults] valueForKey:SYMMETRIESREGISTRATIONDEFAULTSKEY];
		if (regDict) {
			NSData * publicKeyData = [SYMMETRIESPUBLICKEY dataUsingEncoding:NSASCIIStringEncoding];
			NSString * name = [regDict objectForKey: SYMMETRIESREGISTRATIONNAMEKEY];
			NSString * mail = [regDict objectForKey: SYMMETRIESREGISTRATIONMAILKEY];
			NSString * serial = [regDict objectForKey: SYMMETRIESREGISTRATIONSERIALKEY];
			if (publicKeyData && name && mail && serial) {
				NSString * details = [NSString stringWithFormat:@"%@::%@", name, mail];
				NSData * number = [[serial dataUsingEncoding:NSUTF8StringEncoding] decodeBase64WithNewLines:NO];
				SSCrypto *crypto = [[SSCrypto alloc] initWithPublicKey:publicKeyData];
				[crypto setCipherText: number];
				[crypto verify];
				
				if ([[crypto clearTextAsString] isEqualToString:details]) {
					// We're good
					registered = YES;
					registrationWasVerified = YES;
				}
				else {
					// the registration was wrong -> delete from defaults
					[[NSUserDefaults standardUserDefaults] removeObjectForKey:SYMMETRIESREGISTRATIONDEFAULTSKEY];
					NSLog(@"Removed invalid registration information from preferences");
				}

				[crypto release];
			}
		}
	}
	
	return registered;
}




- (void)applicationWillBecomeActive:(NSNotification *)aNotification {
	// check whether there is a serial number in the clipboard
	if (!self.isRegistered) {
		NSPasteboard * pB = [NSPasteboard generalPasteboard];
		NSString * pboardString = [pB stringForType:NSStringPboardType];
		if ([pboardString length] > [SYMMETRIESREGISTRATIONPROTOCOLNAME length]) {
			NSRange protocolRange = [pboardString rangeOfString:SYMMETRIESREGISTRATIONPROTOCOLNAME];
			if (protocolRange.location != NSNotFound) {
				// found our protocol name
				NSString * trimmedString = [pboardString substringFromIndex:protocolRange.location];			
				[self processRegistration:trimmedString];
			}
		}
	}	
}




@end
