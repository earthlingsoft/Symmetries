//
//  AppDelegate.h
//  RoundRect
//
//  Created by  Sven on 05.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppDelegate : NSObject {

}

@property (readonly) NSDocument * firstDocument;
@property (readwrite) BOOL useCoreAnimation;

- (IBAction) setCoreAnimation: (id) sender;
@end
