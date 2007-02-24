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

    NSDictionary* settings;
}
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

- (NSDictionary*)currentSettings;
- (void)setSettings:(NSDictionary*)settings;

- (void) mainViewDidLoad;
- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view;
- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view;
- (void)controlTextDidChange:(NSNotification *)notification;

@end
