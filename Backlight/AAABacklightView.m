//
//  AAABacklightView.m
//  Backlight
//
//  Created by Aliksandr Andrashuk on 09.04.14.
//  Copyright (c) 2014 Aliksandr Andrashuk. All rights reserved.
//

#import "AAABacklightView.h"

@implementation AAABacklightView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    CGFloat padding = 2.5f;
    CGFloat radius = 4.0f;

    NSRect rect = dirtyRect;
    rect.size.width -= (padding * 2);
    rect.origin.x += padding;

    NSColor *color = (self.backlightColor) ?: [NSColor alternateSelectedControlColor];
    [[color colorWithAlphaComponent:0.2] setFill];

    [NSBezierPath setDefaultLineWidth:1.0];
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect
                                                         xRadius:radius yRadius:radius];

    [[color colorWithAlphaComponent:0.2] set];
    [path fill];
}

- (void)setBacklightColor:(NSColor *)backlightColor {
	_backlightColor = backlightColor;
	[self setNeedsDisplay:YES];
}

@end
