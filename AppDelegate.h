//
//  AppDelegate.h
//  Symmetry
//
//  Created by  Sven on 05.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppDelegate : NSObject {
	IBOutlet NSMenuItem * startAnimationMenuItem;
	IBOutlet NSMenuItem * spaceOutMenuItem;	
}

@property (readonly) NSDocument * firstDocument;
@property (readonly) BOOL demoIsRunning;
@property (readwrite) BOOL useCoreAnimation;

- (IBAction) demo:(id) sender;
- (void) readme:(id) sender;
- (NSString*) myVersionString;

@end
