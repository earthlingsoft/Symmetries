//
//  ESSymmetryView+Intro.h
//  Symmetries
//
//  Created by  Sven on 27.06.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ESSymmetryView.h"

@interface ESSymmetryView (Intro) <CALayerDelegate, CAAnimationDelegate>

@property (readonly) NSArray * stringsFromFile;
@property (readonly) NSAttributedString * introString;


- (void) intro;

- (void) drawLayerWithAttributedString: (NSAttributedString *) aS inContext:(CGContextRef) ctx;
- (NSArray *) stringsFromFile;
- (NSAttributedString*) introString;


- (void) startDemo:(id) sender;
- (void) endDemo:(id) sender;
- (void) nextDemoStep;
- (void) gotoDemoStep:(NSUInteger) nr;

- (void) animationDidEnd:(NSAnimation *) animation;

- (void) drawLayer:(CALayer *) layer inContext:(CGContextRef) ctx;


@end
