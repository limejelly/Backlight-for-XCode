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
static NSString *const kAAAAlwaysEnableLineBacklightKey = @"kAAAAlwaysEnableLineBacklightKey";
static NSString *const kAAALineBacklightColorKey = @"kAAALineBacklightColorKey";

static AAABacklight *sharedPlugin;

@interface AAABacklight()
@property (nonatomic, strong) NSBundle *bundle;
@property (readonly) BOOL isBacklightEnabled;
@property (readonly) BOOL isAlwaysEnabled;
@end

@implementation AAABacklight {
    AAABacklightView *_currentBacklightView;
    NSMenuItem *_enabledControlMenuItem;
    NSMenuItem *_alwaysEnabledControlMenuItem;
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
    self = [super init];
    if (!self) return nil;

    self.bundle = plugin;

    NSMenuItem *editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];

    if (editMenuItem) {
        NSMenu *backlightMenu = [[NSMenu alloc] initWithTitle:@"Backlight"];
        [[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];

        [backlightMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Line backlight"
                                                              action:@selector(toggleEnableLineBacklight)
                                                       keyEquivalent:@""];
            menuItem.target = self;
            _enabledControlMenuItem = menuItem;
            menuItem;
        })];

        [backlightMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Always backlight"
                                                              action:@selector(toggleAlwaysEnableBacklight)
                                                       keyEquivalent:@""];
            menuItem.target = self;
            _alwaysEnabledControlMenuItem = menuItem;
            menuItem;
        })];

        [backlightMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Edit line backlight color"
                                                              action:@selector(showColorPanel)
                                                       keyEquivalent:@""];
            menuItem.target = self;
            menuItem;
        })];

        NSString *versionString = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSMenuItem *backlightMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Backlight (%@)", versionString]
                                                                action:nil
                                                         keyEquivalent:@""];
        backlightMenuItem.submenu = backlightMenu;

        [[editMenuItem submenu] addItem:backlightMenuItem];
    }

    [self createBacklight];
    [self adjustBacklight];

    _alwaysEnabledControlMenuItem.state = (self.isAlwaysEnabled) ? NSOnState : NSOffState;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidUpdate:) name:NSWindowDidUpdateNotification object:nil];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Getters

- (BOOL)isBacklightEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAAAEnableLineBacklightKey];
}

- (BOOL)isAlwaysEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAAAAlwaysEnableLineBacklightKey];
}

- (void)toggleEnableLineBacklight
{
    [[NSUserDefaults standardUserDefaults] setBool:!self.isBacklightEnabled forKey:kAAAEnableLineBacklightKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self adjustBacklight];
}

- (void)toggleAlwaysEnableBacklight
{
    [[NSUserDefaults standardUserDefaults] setBool:!self.isAlwaysEnabled forKey:kAAAAlwaysEnableLineBacklightKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    _alwaysEnabledControlMenuItem.state = (self.isAlwaysEnabled) ? NSOnState : NSOffState;
}

#pragma mark - Actions

- (void)showColorPanel
{
	NSColorPanel *panel = [NSColorPanel sharedColorPanel];
	[panel setTarget:self];
	[panel setAction:@selector(adjustColor:)];
	[panel orderFront:nil];
}

- (void)adjustColor:(id)sender
{
	NSColorPanel *panel = (NSColorPanel *)sender;

	if (panel.color && [[NSApp keyWindow] firstResponder] == _textView) {
		_currentBacklightView.backlightColor = panel.color;

		NSData *colorData = [NSArchiver archivedDataWithRootObject:panel.color];
		[[NSUserDefaults standardUserDefaults] setObject:colorData forKey:kAAALineBacklightColorKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

#pragma mark - Notifications

- (void)windowDidUpdate:(NSNotification *)notification
{
    id firstResponder = [[NSApp keyWindow] firstResponder];

    if ([firstResponder isKindOfClass:NSClassFromString(@"DVTSourceTextView")]) {
        _textView = firstResponder;

        if ([[NSUserDefaults standardUserDefaults] boolForKey:kAAAEnableLineBacklightKey]) {
            [self moveBacklightInTextView:firstResponder];
        } else {
            [_currentBacklightView removeFromSuperview];
        }
    }
}

#pragma mark - Private methods

- (void)moveBacklightInTextView:(NSTextView *)textView
{
    if (!textView || [[NSApp keyWindow] firstResponder] != textView) {
        return;
    }

    NSRange selectedRange = [textView selectedRange];

    [_currentBacklightView removeFromSuperview];

    if (selectedRange.length != 0 && !self.isAlwaysEnabled) return;

    NSRect rectInScreen = [textView firstRectForCharacterRange:selectedRange actualRange:NULL];
    NSRect rectInWindow = [textView.window convertRectFromScreen:rectInScreen];
    NSRect rectInView   = [textView convertRect:rectInWindow fromView:nil];

    NSRect backlightRect = rectInView;
    backlightRect.origin.x = 0;
    backlightRect.size.width = textView.bounds.size.width;
    _currentBacklightView.frame = backlightRect;

    if (!_currentBacklightView.superview) {
        [textView addSubview:_currentBacklightView];
    }
}

- (void)createBacklight
{
    _currentBacklightView = [[AAABacklightView alloc] initWithFrame:NSZeroRect];
    _currentBacklightView.autoresizingMask = NSViewWidthSizable;

	NSData *colorData = [[NSUserDefaults standardUserDefaults] dataForKey:kAAALineBacklightColorKey];

	if (colorData != nil) {
		NSColor *color = (NSColor *)[NSUnarchiver unarchiveObjectWithData:colorData];
		_currentBacklightView.backlightColor = color;
	}
}

- (void)adjustBacklight
{
    if (self.isBacklightEnabled) {
        [_enabledControlMenuItem setState:NSOnState];
        [self moveBacklightInTextView:_textView];
    } else {
        [_currentBacklightView removeFromSuperview];
        [_enabledControlMenuItem setState:NSOffState];
    }
}

@end
