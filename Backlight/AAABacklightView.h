//
//  AAABacklightView.h
//  Backlight
//
//  Created by Aliksandr Andrashuk on 09.04.14.
//  Copyright (c) 2014 Aliksandr Andrashuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AAABacklightView : NSView

@property (nonatomic, strong) NSColor *backlightColor;
@property (nonatomic) BOOL strokeEnabled;
@property (nonatomic) BOOL radiusEnabled;

@end
