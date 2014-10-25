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

    dirtyRect.size.width -= AAABacklightViewPadding * 2;
    dirtyRect.origin.x   += AAABacklightViewPadding;

    NSColor *color = (self.backlightColor) ?: [NSColor alternateSelectedControlColor];
    [[color colorWithAlphaComponent:0.2] set];

    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:dirtyRect
                                                         xRadius:AAABacklightViewRadius
                                                         yRadius:AAABacklightViewRadius];
    [path setLineWidth:1.0f];
    [path fill];
}

- (void)setBacklightColor:(NSColor *)backlightColor {
	_backlightColor = backlightColor;
	[self setNeedsDisplay:YES];
}

@end
