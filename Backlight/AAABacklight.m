//
//  AAABacklight.m
//  AAABacklight
//
//  Created by Aliksandr Andrashuk on 09.04.14.
//    Copyright (c) 2014 Aliksandr Andrashuk. All rights reserved.
//

#import "AAABacklight.h"
#import "AAABacklightView.h"

static NSString *const kAAAEnableLineBacklightKey = @"kAAAEnableLineBacklightKey";

static AAABacklight *sharedPlugin;

@interface AAABacklight()
@property (nonatomic, strong) NSBundle *bundle;
@property (readonly) BOOL isBacklightEnabled;
@end

@implementation AAABacklight {
    AAABacklightView *_currentBacklightView;
    NSMenuItem *_controlMenuItem;
    NSTextView *_textView;
}

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        self.bundle = plugin;
        
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
        
        if (menuItem) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
            NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Line backlight" action:@selector(toggleEnableLineBacklight) keyEquivalent:@""];
            [actionMenuItem setTarget:self];
            [[menuItem submenu] addItem:actionMenuItem];
            _controlMenuItem = actionMenuItem;
        }
        
        [self createBacklight];
        [self adjustBacklight];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChanged:) name:NSTextViewDidChangeSelectionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChanged:) name:NSTextDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isBacklightEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAAAEnableLineBacklightKey];
}

- (void)toggleEnableLineBacklight
{
    [[NSUserDefaults standardUserDefaults] setBool:!self.isBacklightEnabled forKey:kAAAEnableLineBacklightKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self adjustBacklight];
}

- (void)textViewDidChanged:(NSNotification *)notification {
    
    if ([notification.object isKindOfClass:NSClassFromString(@"DVTSourceTextView")]) {
        _textView = notification.object;
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kAAAEnableLineBacklightKey]) {
            [self moveBacklightInTextView:notification.object];
        }
    }
    else {
        [_currentBacklightView removeFromSuperview];
    }
}

- (void)moveBacklightInTextView:(NSTextView *)textView {
    if (!textView) {
        return;
    }
    
    NSRange selectedRange = [textView selectedRange];
    
    [_currentBacklightView removeFromSuperview];
    
    if (selectedRange.length == 0) {
        NSRect rectInScreen = [textView firstRectForCharacterRange:selectedRange];
        NSRect rectInWindow = [textView.window convertRectFromScreen:rectInScreen];
        NSRect rectInView = [textView convertRect:rectInWindow fromView:nil];
        
        NSRect backlightRect = rectInView;
        backlightRect.origin.x = 0;
        backlightRect.size.width = textView.bounds.size.width;
        _currentBacklightView.frame = backlightRect;
        
        if (!_currentBacklightView.superview) {
            [textView addSubview:_currentBacklightView];
        }
    }

}

- (void)createBacklight {
    _currentBacklightView = [[AAABacklightView alloc] initWithFrame:NSZeroRect];
    _currentBacklightView.autoresizingMask = NSViewWidthSizable;
}

- (void)adjustBacklight {
    if (self.isBacklightEnabled) {
        [_controlMenuItem setState:NSOnState];
        [self moveBacklightInTextView:_textView];
    }
    else {
        [_currentBacklightView removeFromSuperview];
        [_controlMenuItem setState:NSOffState];
    }
}

@end
