//
//  MyDocument+Animation.h
//  Symmetries
//
//  Created by  Sven on 29.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyDocument.h"

@interface MyDocument (Animation) <NSAnimationDelegate>

@property (readonly) BOOL runningAnimation;


- (IBAction) animate:(id) sender;
- (IBAction) spaceOut:(id) sender;
- (IBAction) animateFullScreen:(id) sender;
- (IBAction) stopAnimation:(id) sender;

- (NSArray*) animationKeys;
- (NSDictionary *) valueRangeForKey: (NSString *) key currentValue: (CGFloat) currentValue;


@end
