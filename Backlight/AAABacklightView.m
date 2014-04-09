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
    
    [[[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.2] setFill];
    NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
}

@end
