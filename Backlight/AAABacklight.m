//
//  AAABacklight.m
//  AAABacklight
//
//  Created by Aliksandr Andrashuk on 09.04.14.
//    Copyright (c) 2014 Aliksandr Andrashuk. All rights reserved.
//

#import "AAABacklight.h"
#import "AAABacklightView.h"

typedef NS_ENUM(NSInteger, AAABacklightMode) {
    AAABacklightModeNone,
    AAABacklightModeUnderneath,
    AAABacklightModeOverlay
};

static NSString *const kAAAEnableLineBacklightUnderneathMode = @"kAAAEnbaleLineBacklightUnderneathMode";
// Keep the value for compatibility.
static NSString *const kAAAEnableLineBacklightOverlayMode    = @"kAAAEnableLineBacklightKey";
static NSString *const kAAAAlwaysEnableLineBacklight         = @"kAAAAlwaysEnableLineBacklightKey";
static NSString *const kAAALineBacklightColor                = @"kAAALineBacklightColorKey";
static NSString *const kAAALineBacklightStrokeEnabled        = @"kAAALineBacklightStrokeEnabledKey";
static NSString *const kAAALineBacklightRadiusEnabled        = @"kAAALineBacklightRadiusEnabledKey";

static AAABacklight *sharedPlugin;

@interface AAABacklight()
@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong) AAABacklightView *currentBacklightView;
@property (nonatomic, assign) AAABacklightMode currentMode;
@property (nonatomic, assign) NSRange currentLineRange;
@property (nonatomic, strong) NSColor *backlightColor;
@property (nonatomic, strong) NSTextView *textView;
// Hold the menu items because Underneath mode and Overlay mode are excluded options.
// Under Unserneath mode, the stroke and round corner is not effective.
@property (nonatomic, strong) NSMenuItem *underneathModeMenuItem;
@property (nonatomic, strong) NSMenuItem *overlayModeMenuItem;
@property (nonatomic, strong) NSMenuItem *enableStrokeMenuItem;
@property (nonatomic, strong) NSMenuItem *enableRadiusMenuItem;
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
    backlightMenu.autoenablesItems = NO;
    [[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];

    self.underneathModeMenuItem = [[NSMenuItem alloc] initWithTitle:@"Line backlight (Underneath Mode)"
                                                             action:@selector(toggleEnableLineBacklightUnderneathMode:)
                                                      keyEquivalent:@""];
    self.underneathModeMenuItem.target = self;
    // Show the "check" mark only when NOT being in "Overlay Mode" and the associated key is enabled.
    self.underneathModeMenuItem.state = self.underneathModeMenuItem.enabled && [self settingForKey:kAAAEnableLineBacklightUnderneathMode];
    [backlightMenu addItem:self.underneathModeMenuItem];

    self.overlayModeMenuItem = [[NSMenuItem alloc] initWithTitle:@"Line backlight (Overlay Mode)"
                                                          action:@selector(toggleEnableLineBacklightOverlayMode:)
                                                   keyEquivalent:@""];
    self.overlayModeMenuItem.target = self;
    // Show the "check" mark only when NOT being in "Underneath Mode" and the associated key is enabled.
    self.overlayModeMenuItem.state = self.overlayModeMenuItem.enabled && [self settingForKey:kAAAEnableLineBacklightOverlayMode];
    [backlightMenu addItem:self.overlayModeMenuItem];

    [backlightMenu addItem:({
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Always backlight"
                                                          action:@selector(toggleAlwaysEnableBacklight:)
                                                   keyEquivalent:@""];
        menuItem.target = self;
        menuItem.state = [self settingForKey:kAAAAlwaysEnableLineBacklight];
        menuItem;
    })];

    [backlightMenu addItem:[NSMenuItem separatorItem]];

    self.enableStrokeMenuItem = [[NSMenuItem alloc] initWithTitle:@"Enable stroke"
                                                           action:@selector(toggleStrokeBacklight:)
                                                    keyEquivalent:@""];
    self.enableStrokeMenuItem.target = self;
    self.enableStrokeMenuItem.enabled = [self settingForKey:kAAAEnableLineBacklightOverlayMode];
    // Show the "check" mark only when being in "Overlay Mode" and the associated key is enabled.
    self.enableStrokeMenuItem.state = self.enableStrokeMenuItem.enabled && [self settingForKey:kAAALineBacklightStrokeEnabled];
    [backlightMenu addItem:self.enableStrokeMenuItem];

    self.enableRadiusMenuItem = [[NSMenuItem alloc] initWithTitle:@"Enable round corners"
                                                           action:@selector(toggleRadiusBacklight:)
                                                    keyEquivalent:@""];
    self.enableRadiusMenuItem.target = self;
    self.enableRadiusMenuItem.enabled = [self settingForKey:kAAAEnableLineBacklightOverlayMode];
    // Show the "check" mark only when being in "Overlay Mode" and the associated key is enabled.
    self.enableRadiusMenuItem.state = self.enableStrokeMenuItem.enabled && [self settingForKey:kAAALineBacklightRadiusEnabled];
    [backlightMenu addItem:self.enableRadiusMenuItem];

    [backlightMenu addItem:[NSMenuItem separatorItem]];

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

- (void)toggleEnableLineBacklightUnderneathMode:(NSMenuItem *)sender
{
    [self toggleSettingForKey: kAAAEnableLineBacklightUnderneathMode];

    sender.state = [self stateForSettingForKey: kAAAEnableLineBacklightUnderneathMode];
    if (sender.state == NSOnState) {
        if ([self stateForSettingForKey:kAAAEnableLineBacklightOverlayMode]) {
            [self toggleSettingForKey:kAAAEnableLineBacklightOverlayMode];
            self.overlayModeMenuItem.state = NSOffState;
        }
    }
    self.enableStrokeMenuItem.enabled = (sender.state == NSOffState && self.overlayModeMenuItem.state == NSOnState);
    self.enableRadiusMenuItem.enabled = (sender.state == NSOffState && self.overlayModeMenuItem.state == NSOnState);

    [self adjustBacklight];
}

- (void)toggleEnableLineBacklightOverlayMode:(NSMenuItem *)sender
{
    [self toggleSettingForKey:kAAAEnableLineBacklightOverlayMode];

    sender.state = [self stateForSettingForKey: kAAAEnableLineBacklightOverlayMode];
    if (sender.state == NSOnState) {
        if ([self stateForSettingForKey:kAAAEnableLineBacklightUnderneathMode]) {
            [self toggleSettingForKey:kAAAEnableLineBacklightUnderneathMode];
            self.underneathModeMenuItem.state = NSOffState;
        }
    }
    self.enableStrokeMenuItem.enabled = (sender.state == NSOnState);
    self.enableRadiusMenuItem.enabled = (sender.state == NSOnState);

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
    self.backlightColor = panel.color;
    if (self.textView) {
        if ([self.textView.layoutManager temporaryAttribute:NSBackgroundColorAttributeName
                                           atCharacterIndex:self.currentLineRange.location
                                             effectiveRange:NULL]) {
            [self.textView.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName
                                                forCharacterRange:self.currentLineRange];
            [self.textView.layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName
                                                         value:self.backlightColor
                                             forCharacterRange:self.currentLineRange];
        }
    }

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

    [self adjustBacklight];
}

- (void)moveBacklightInTextView:(NSTextView *)textView
{
    if (!textView || [[NSApp keyWindow] firstResponder] != textView) return;

    NSRange selectedRange = [textView selectedRange];
    [self.currentBacklightView removeFromSuperview];
    if ([textView.layoutManager temporaryAttribute:NSBackgroundColorAttributeName
                                  atCharacterIndex:self.currentLineRange.location
                                    effectiveRange:NULL]) {
        [textView.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName
                                       forCharacterRange:self.currentLineRange];
    }

    if (selectedRange.length != 0 && ![self settingForKey:kAAAAlwaysEnableLineBacklight]) return;

    switch (self.currentMode) {
        case AAABacklightModeOverlay:
        {
            NSRange glyphRange = [textView.layoutManager glyphRangeForCharacterRange:selectedRange
                                                                actualCharacterRange:NULL];
            NSRect glyphRect = [textView.layoutManager boundingRectForGlyphRange:glyphRange
                                                                 inTextContainer:textView.textContainer];

            NSRect backlightRect = glyphRect;
            backlightRect.origin.x = 0;
            backlightRect.size.width = textView.bounds.size.width;
            self.currentBacklightView.frame = backlightRect;

            if (!self.currentBacklightView.superview) {
                [textView addSubview:self.currentBacklightView];
            }
        }
            break;
        case AAABacklightModeUnderneath:
        {
            self.currentLineRange = [textView.string lineRangeForRange:selectedRange];
            [textView.layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName
                                                    value:self.backlightColor
                                        forCharacterRange:self.currentLineRange];
        }
            break;
        case AAABacklightModeNone:
            break;
    }
}

- (void)createBacklight
{
	NSData *colorData = [[NSUserDefaults standardUserDefaults] dataForKey:kAAALineBacklightColor];
    if (!colorData) {
        // Make sure the backlightColor property got valid value.
        self.backlightColor = [[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.2];
        return;
    }

    self.backlightColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:colorData];
    if (!self.backlightColor) {
        // fail-safe
        self.backlightColor = [NSColor alternateSelectedControlColor];
    }
    self.currentLineRange = NSMakeRange(0, 0);
    self.currentBacklightView.backlightColor = self.backlightColor;
}

- (void)adjustBacklight
{
    if ([self settingForKey:kAAAEnableLineBacklightOverlayMode]) {
        self.currentMode = AAABacklightModeOverlay;
    } else if ([self settingForKey:kAAAEnableLineBacklightUnderneathMode]) {
        self.currentMode = AAABacklightModeUnderneath;
    } else {
        self.currentMode = AAABacklightModeNone;
    }
    BOOL enabled = (self.currentMode != AAABacklightModeNone);

    if (enabled) {
        [self moveBacklightInTextView:self.textView];
    } else {
        [self.currentBacklightView removeFromSuperview];
        if (self.textView) {
            if ([self.textView.layoutManager temporaryAttribute:NSBackgroundColorAttributeName
                                               atCharacterIndex:self.currentLineRange.location
                                                 effectiveRange:NULL]) {
                [self.textView.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName
                                                    forCharacterRange:self.currentLineRange];
            }
        }
    }
}

@end
