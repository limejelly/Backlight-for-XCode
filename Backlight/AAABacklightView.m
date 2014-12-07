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

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];

    NSColor *color = (self.backlightColor) ?: [NSColor alternateSelectedControlColor];
    if (!self.backlightColor) {
        [[color colorWithAlphaComponent:0.2f] set];
    } else {
        [color set];
    }

    if (self.radiusEnabled) {
        rect.size.width -= AAABacklightViewPadding * 2.0f;
        rect.origin.x   += AAABacklightViewPadding;

        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect
                                                             xRadius:AAABacklightViewRadius
                                                             yRadius:AAABacklightViewRadius];

        [path fill];

        if (self.strokeEnabled) {
            path.lineWidth = 0.5f;
            [[color colorWithAlphaComponent:0.8f] set];
            [path stroke];
        }
    } else {
        NSRectFillUsingOperation(rect, NSCompositeSourceOver);
    }
}

- (void)setBacklightColor:(NSColor *)backlightColor {
	_backlightColor = backlightColor;
	[self setNeedsDisplay:YES];
}

- (void)setRadiusEnabled:(BOOL)enabled
{
    _radiusEnabled = enabled;
    [self setNeedsDisplay:YES];
}

@end
