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
static NSString *const kAAALineBacklightColorKey = @"kAAALineBacklightColorKey";

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

        NSMenuItem *editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];

        if (editMenuItem) {
            NSMenu *backlightMenu = [[NSMenu alloc] initWithTitle:@"Backlight"];
            [[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];

            [backlightMenu addItem:({
                NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Line backlight"
                                                                  action:@selector(toggleEnableLineBacklight)
                                                           keyEquivalent:@""];
                menuItem.target = self;
                menuItem.keyEquivalentModifierMask = NSControlKeyMask | NSShiftKeyMask;
                _controlMenuItem = menuItem;
                menuItem;
            })];

            [backlightMenu addItem:({
                NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Edit line backlight color"
                                                                  action:@selector(showColorPanel)
                                                           keyEquivalent:@""];
                menuItem.target = self;
                menuItem.keyEquivalentModifierMask = NSControlKeyMask | NSShiftKeyMask;
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

- (void)showColorPanel {
	
	NSColorPanel *panel = [NSColorPanel sharedColorPanel];
	[panel setTarget:self];
	[panel setAction:@selector(adjustColor:)];
	[panel orderFront:nil];
}

- (void)adjustColor:(id)sender {

	NSColorPanel *panel = (NSColorPanel *)sender;
	if (panel.color && [[NSApp keyWindow] firstResponder] == _textView) {
		
		_currentBacklightView.backlightColor = panel.color;
		
		NSData *colorData = [NSArchiver archivedDataWithRootObject:panel.color];
		[[NSUserDefaults standardUserDefaults] setObject:colorData forKey:kAAALineBacklightColorKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
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
    if (!textView || [[NSApp keyWindow] firstResponder] != textView) {
        return;
    }
    
    NSRange selectedRange = [textView selectedRange];
    
    [_currentBacklightView removeFromSuperview];
    
    if (selectedRange.length == 0) {
        NSRect rectInScreen = [textView firstRectForCharacterRange:selectedRange actualRange:NULL];
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
	
	NSData *colorData = [[NSUserDefaults standardUserDefaults] dataForKey:kAAALineBacklightColorKey];
	if (colorData != nil) {
	
		NSColor *color = (NSColor *)[NSUnarchiver unarchiveObjectWithData:colorData];
		_currentBacklightView.backlightColor = color;
	}
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
