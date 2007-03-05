/* MiredoPref */

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SecurityInterface/SFAuthorizationView.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface MiredoPref : NSPreferencePane
{
    IBOutlet SFAuthorizationView *comboAuthButton;
    IBOutlet NSTextField *bindAddress;
    IBOutlet NSTextField *bindPort;
    IBOutlet NSTextField *currentAddress;
    IBOutlet NSPopUpButton *relayType;
    IBOutlet NSTextField *serverAddress;
    IBOutlet NSButton *teredoEnabled;
    IBOutlet NSButton *applyButton;
    IBOutlet NSButton *revertButton;
	IBOutlet NSImageView* statusLight;

    NSDictionary* settings;
	
	NSImage* redLight;
	NSImage* greenLight;
	NSImage* yellowLight;
	NSImage* grayLight;
	SCDynamicStoreRef dynamic_store;
}
- (IBAction)modeChanged:(id)sender;
- (IBAction)apply:(id)sender;
- (IBAction)revert:(id)sender;
- (IBAction)teredoToggle:(id)sender;
- (void)enableControls;
- (void)disableControls;
- (void)updateApplyButtonState;
- (void)readSettings;
- (void)restoreSettings;
- (void)saveSettings;
- (void)restartMiredo;
- (BOOL)isMiredoRunning;
- (BOOL)isMiredoEnabled;
- (BOOL)hasNativeIPv6;
- (NSString*)getMiredoAddress;

- (NSDictionary*)currentSettings;
- (void)setSettings:(NSDictionary*)settings;

- (void) refresh;
- (void) mainViewDidLoad;
- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view;
- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view;
- (void)controlTextDidChange:(NSNotification *)notification;

@end
