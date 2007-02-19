/* MiredoPrefController */

#import <Cocoa/Cocoa.h>

@interface MiredoPrefController : NSResponder
{
    IBOutlet NSTextField *bindAddress;
    IBOutlet NSTextField *bindPort;
    IBOutlet NSTextField *currentAddress;
    IBOutlet NSPopUpButton *relayType;
    IBOutlet NSTextField *serverAddress;
}
- (IBAction)apply:(id)sender;
- (IBAction)revert:(id)sender;
@end
