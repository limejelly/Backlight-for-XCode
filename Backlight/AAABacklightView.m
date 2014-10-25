//
//  AAABacklightView.m
//  Backlight
//
//  Created by Aliksandr Andrashuk on 09.04.14.
//  Copyright (c) 2014 Aliksandr Andrashuk. All rights reserved.
//

#import "AAABacklightView.h"

static CGFloat AAABacklightViewPadding = 2.5f;
static CGFloat AAABacklightViewRadius = 4.0f;

@implementation AAABacklightView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    NSRect rect = dirtyRect;
    rect.size.width -= AAABacklightViewPadding * 2;
    rect.origin.x   += AAABacklightViewPadding;

    NSColor *color = (self.backlightColor) ?: [NSColor alternateSelectedControlColor];
    [[color colorWithAlphaComponent:0.2] setFill];

    [NSBezierPath setDefaultLineWidth:1.0];
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect
                                                         xRadius:AAABacklightViewRadius
                                                         yRadius:AAABacklightViewRadius];

    [[color colorWithAlphaComponent:0.2] set];
    [path fill];
}

- (void)setBacklightColor:(NSColor *)backlightColor {
	_backlightColor = backlightColor;
	[self setNeedsDisplay:YES];
}

@end
