//
//  AAABacklight.m
//  AAABacklight
//
//  Created by Aliksandr Andrashuk on 09.04.14.
//    Copyright (c) 2014 Aliksandr Andrashuk. All rights reserved.
//

#import "AAABacklight.h"
#import "AAABacklightView.h"

static NSString *const kAAAEnableLineBacklight        = @"kAAAEnableLineBacklightKey";
static NSString *const kAAAAlwaysEnableLineBacklight  = @"kAAAAlwaysEnableLineBacklightKey";
static NSString *const kAAALineBacklightColor         = @"kAAALineBacklightColorKey";
static NSString *const kAAALineBacklightStrokeEnabled = @"kAAALineBacklightStrokeEnabledKey";
static NSString *const kAAALineBacklightRadiusEnabled = @"kAAALineBacklightRadiusEnabledKey";

static AAABacklight *sharedPlugin;

@interface AAABacklight()
@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong) AAABacklightView *currentBacklightView;
@property (nonatomic, strong) NSTextView *textView;
@end

@implementation AAABacklight

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

    if (!editMenuItem) return self;

    NSMenu *backlightMenu = [[NSMenu alloc] initWithTitle:@"Backlight"];
    [[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];

    [backlightMenu addItem:({
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Line backlight"
                                                          action:@selector(toggleEnableLineBacklight:)
                                                   keyEquivalent:@""];
        menuItem.target = self;
        menuItem.state = [self settingForKey:kAAAEnableLineBacklight];
        menuItem;
    })];

    [backlightMenu addItem:({
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Always backlight"
                                                          action:@selector(toggleAlwaysEnableBacklight:)
                                                   keyEquivalent:@""];
        menuItem.target = self;
        menuItem.state = [self settingForKey:kAAAAlwaysEnableLineBacklight];
        menuItem;
    })];

    [backlightMenu addItem:({
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Enable stroke"
                                                          action:@selector(toggleStrokeBacklight:)
                                                   keyEquivalent:@""];
        menuItem.target = self;
        menuItem.state = [self settingForKey:kAAALineBacklightStrokeEnabled];
        menuItem;
    })];

    [backlightMenu addItem:({
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Enable round corners"
                                                          action:@selector(toggleRadiusBacklight:)
                                                   keyEquivalent:@""];
        menuItem.target = self;
        menuItem.state = [self settingForKey:kAAALineBacklightRadiusEnabled];
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

    [self createBacklight];
    [self adjustBacklight];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backlightNotification:)
                                                 name:NSTextViewDidChangeSelectionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backlightNotification:)
                                                 name:NSWindowDidResizeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backlightNotification:)
                                                 name:NSWindowDidBecomeKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backlightNotification:)
                                                 name:NSWindowDidResizeNotification object:nil];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Getters

- (AAABacklightView *)currentBacklightView
{
    if (_currentBacklightView) return _currentBacklightView;

    _currentBacklightView = [[AAABacklightView alloc] initWithFrame:NSZeroRect];
    _currentBacklightView.autoresizingMask = NSViewWidthSizable;
    _currentBacklightView.strokeEnabled = [self settingForKey:kAAALineBacklightStrokeEnabled];
    _currentBacklightView.radiusEnabled = [self settingForKey:kAAALineBacklightRadiusEnabled];

    return _currentBacklightView;
}

- (BOOL)settingForKey:(NSString *)key
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

- (NSCellStateValue)stateForSettingForKey:(NSString *)key
{
    return ([self settingForKey:key]) ? NSOnState : NSOffState;
}

#pragma mark - Setters

- (void)toggleSettingForKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] setBool:![self settingForKey:key] forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Actions

- (void)toggleEnableLineBacklight:(NSMenuItem *)sender
{
    [self toggleSettingForKey:kAAAEnableLineBacklight];
    sender.state = [self stateForSettingForKey:kAAAEnableLineBacklight];
    [self adjustBacklight];
}

- (void)toggleAlwaysEnableBacklight:(NSMenuItem *)sender
{
    [self toggleSettingForKey:kAAAAlwaysEnableLineBacklight];
    sender.state = [self stateForSettingForKey:kAAAAlwaysEnableLineBacklight];
}

- (void)toggleStrokeBacklight:(NSMenuItem *)sender
{
    [self toggleSettingForKey:kAAALineBacklightStrokeEnabled];
    sender.state = [self stateForSettingForKey:kAAALineBacklightStrokeEnabled];
    self.currentBacklightView.strokeEnabled = [self settingForKey:kAAALineBacklightStrokeEnabled];
    [self.currentBacklightView setNeedsDisplay:YES];
}

- (void)toggleRadiusBacklight:(NSMenuItem *)sender
{
    [self toggleSettingForKey:kAAALineBacklightRadiusEnabled];
    sender.state = [self stateForSettingForKey:kAAALineBacklightRadiusEnabled];
    self.currentBacklightView.radiusEnabled = [self settingForKey:kAAALineBacklightRadiusEnabled];
    [self.currentBacklightView setNeedsDisplay:YES];
}

#pragma mark - Actions

- (void)showColorPanel
{
	NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    panel.color = self.currentBacklightView.backlightColor;
    panel.target = self;
    panel.action = @selector(adjustColor:);
	[panel orderFront:nil];

    // Observe the closing of the color panel so we can remove ourself from the target.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(colorPanelWillClose:)
                                                 name:NSWindowWillCloseNotification object:nil];
}

- (void)adjustColor:(id)sender
{
	NSColorPanel *panel = (NSColorPanel *)sender;

    if (!panel.color && [[NSApp keyWindow] firstResponder] != self.textView) return;

    self.currentBacklightView.backlightColor = panel.color;

    NSData *colorData = [NSArchiver archivedDataWithRootObject:panel.color];
    [[NSUserDefaults standardUserDefaults] setObject:colorData forKey:kAAALineBacklightColor];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Notifications

- (void)backlightNotification:(NSNotification *)notification
{
    id firstResponder = [[NSApp keyWindow] firstResponder];
    if (![firstResponder isKindOfClass:NSClassFromString(@"DVTSourceTextView")]) return;

    [self updateBacklightViewWithTextView:firstResponder];
}

- (void)colorPanelWillClose:(NSNotification *)notification
{
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    if (panel == notification.object) {
        panel.target = nil;
        panel.action = nil;

        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSWindowWillCloseNotification
                                                      object:nil];
    }
}

#pragma mark - Private methods

- (void)updateBacklightViewWithTextView:(NSTextView *)textView
{
    self.textView = textView;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kAAAEnableLineBacklight]) {
        [self moveBacklightInTextView:textView];
    } else {
        [self.currentBacklightView removeFromSuperview];
    }
}

- (void)moveBacklightInTextView:(NSTextView *)textView
{
    if (!textView || [[NSApp keyWindow] firstResponder] != textView) return;

    NSRange selectedRange = [textView selectedRange];
    [self.currentBacklightView removeFromSuperview];

    if (selectedRange.length != 0 && ![self settingForKey:kAAAAlwaysEnableLineBacklight]) return;

    NSRange glyphRange = [textView.layoutManager glyphRangeForCharacterRange:selectedRange actualCharacterRange:NULL];
    NSRect glyphRect = [textView.layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textView.textContainer];

    NSRect backlightRect = glyphRect;
    backlightRect.origin.x = 0;
    backlightRect.size.width = textView.bounds.size.width;
    self.currentBacklightView.frame = backlightRect;

    if (!self.currentBacklightView.superview) {
        [textView addSubview:self.currentBacklightView];
    }
}

- (void)createBacklight
{
	NSData *colorData = [[NSUserDefaults standardUserDefaults] dataForKey:kAAALineBacklightColor];
    if (!colorData) return;

    NSColor *color = (NSColor *)[NSUnarchiver unarchiveObjectWithData:colorData];
    self.currentBacklightView.backlightColor = color;
}

- (void)adjustBacklight
{
    BOOL enabled = [self settingForKey:kAAAEnableLineBacklight];

    if (enabled) {
        [self moveBacklightInTextView:self.textView];
    } else {
        [self.currentBacklightView removeFromSuperview];
    }
}

@end
