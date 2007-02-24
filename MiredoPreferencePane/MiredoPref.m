//
//  MiredoPreferencePanePref.m
//  MiredoPreferencePane
//
//  Created by Robert Quattlebaum on 2/18/07.
//  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
//

#import "MiredoPref.h"
#import "MiredoConfig.h"
#include <Security/Security.h>
#include <AssertMacros.h>
#include <CoreFoundation/CoreFoundation.h>
#include <SystemConfiguration/SystemConfiguration.h>
#include "PrivilegedOperations.h"

#define DEFAULT_TEREDO_SERVER   @"teredo.remlab.net"


@implementation MiredoPref

- (void) mainViewDidLoad
{
    AuthorizationItem		_rights[] = {
//        { kAuthorizationRightExecute, strlen(killall_command_path), killall_command_path, 0 },
//		kToolRights,
        { "system.preferences" }
    };
    AuthorizationItemSet	rights = { sizeof(*_rights)/sizeof(_rights), _rights };

    [comboAuthButton setAuthorizationRights:&rights];
//    [comboAuthButton setFlags:kAuthorizationFlagInteractionAllowed|kAuthorizationFlagExtendRights];
    [comboAuthButton setDelegate:self];
    [comboAuthButton updateStatus:nil];
    [comboAuthButton setAutoupdate:YES];

	EnsureToolInstalled();

    settings=[[NSMutableDictionary dictionaryWithCapacity:20] retain];
    [self readSettings];
}

- (void) dealloc
{
    [settings release];
    [super dealloc];
}

- (IBAction)apply:(id)sender {
    [self saveSettings];
}

- (IBAction)revert:(id)sender {
    [self restoreSettings];
}

- (void)enableControls {
    [bindAddress setEnabled:YES];
    [bindPort setEnabled:YES];
    [relayType setEnabled:YES];
    [serverAddress setEnabled:YES];
    [teredoEnabled setEnabled:YES];

}

- (void)disableControls {
    [bindAddress setEnabled:NO];
    [bindPort setEnabled:NO];
    [relayType setEnabled:NO];
    [serverAddress setEnabled:NO];
    [teredoEnabled setEnabled:NO];
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view {
    (void)view; // keep the compiler from complaining
    [self enableControls];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view {
    (void)view; // keep the compiler from complaining
    [self disableControls];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    (void)notification;
    [self updateApplyButtonState];
}

- (void)updateApplyButtonState {
    if([settings isEqualToDictionary:[self currentSettings]]) {
        [revertButton setEnabled:NO];
        [applyButton setEnabled:NO];
    } else {
        [revertButton setEnabled:YES];
        [applyButton setEnabled:YES];
    }
}

- (void)readSettings {
    [self setSettings:MiredoConfigLoad(@"/etc/miredo.conf")];
    [self updateApplyButtonState];
}

- (void)restoreSettings {
    [self setSettings:settings];
    [self updateApplyButtonState];
}

- (void)saveSettings {
    OSStatus err;
	err=WriteMiredoConfiguration([[comboAuthButton authorization] authorizationRef],(CFDictionaryRef)[self currentSettings]);

    if(err!=noErr) {
        
        
        [   [NSAlert
                alertWithError:[NSError
                    errorWithDomain:NSOSStatusErrorDomain
                    code:err
                    userInfo:nil
                ]        
            ]
            beginSheetModalForWindow:[[self mainView] window]
            modalDelegate:self
            didEndSelector:nil
            contextInfo:NULL
        ];
    } else {
        [self restartMiredo];
	}

    [self setSettings:MiredoConfigLoad(@"/etc/miredo.conf")];
    [self updateApplyButtonState];
}

- (void)restartMiredo {
	OSStatus		err = noErr;
	err=MiredoRestart([[comboAuthButton authorization] authorizationRef]);

    if(err!=noErr) {
        
        
        [   [NSAlert
                alertWithError:[NSError
                    errorWithDomain:NSOSStatusErrorDomain
                    code:err
                    userInfo:nil
                ]        
            ]
            beginSheetModalForWindow:[[self mainView] window]
            modalDelegate:self
            didEndSelector:nil
            contextInfo:NULL
        ];
    }
}

- (NSDictionary*)currentSettings {
    NSMutableDictionary* ret=[NSMutableDictionary dictionaryWithCapacity:20];
    [ret addEntriesFromDictionary:settings];
    
    if([[bindAddress stringValue] length])
        [ret setValue:[bindAddress stringValue] forKey:@"BindAddress" ];
    else
        [ret removeObjectForKey:@"BindAddress"];
        
    if([[bindPort stringValue] length])
        [ret setValue:[bindPort stringValue] forKey:@"BindPort" ];
    else
        [ret removeObjectForKey:@"BindPort"];

    if([[serverAddress stringValue] length])
        [ret setValue:[serverAddress stringValue] forKey:@"ServerAddress" ];
    else
        [ret setValue:DEFAULT_TEREDO_SERVER forKey:@"ServerAddress" ];

    switch([[relayType selectedItem] tag]) {
        case 1: // Client
            [ret setValue:@"client" forKey:@"RelayType" ];
            break;
        case 2: // Relay
            [ret setValue:@"relay" forKey:@"RelayType" ];
            break;
        case 0: // Autoclient
        default:
            [ret setValue:@"autoclient" forKey:@"RelayType" ];
            break;
    }
    return ret;
}

- (void)setSettings:(NSDictionary*)new_settings {
    [new_settings retain];
    [settings release];
    settings=new_settings;

    if([settings valueForKey:@"BindAddress"])
        [bindAddress setStringValue:[settings valueForKey:@"BindAddress"]];
    else
        [bindAddress setStringValue:@""];

    if([settings valueForKey:@"BindPort"])
        [bindPort setStringValue:[settings valueForKey:@"BindPort"]];
    else
        [bindPort setStringValue:@""];

    if([settings valueForKey:@"ServerAddress"] && [[settings valueForKey:@"ServerAddress"] compare:DEFAULT_TEREDO_SERVER]!=NSOrderedSame)
        [serverAddress setStringValue:[settings valueForKey:@"ServerAddress"]];
    else
        [serverAddress setStringValue:@""];

    if([[settings valueForKey:@"RelayType"] compare:@"relay"]==NSOrderedSame) {
        [relayType  selectItemWithTag:2];
    } else if([[settings valueForKey:@"RelayType"] compare:@"client"]==NSOrderedSame) {
        [relayType  selectItemWithTag:1];
    } else {
        // Autoclient is default
        [relayType  selectItemWithTag:0];
    }
    
}

- (IBAction)teredoToggle:(id)sender {
	OSStatus		err = noErr;

	NSLog(@"teredoToggle");
	
	switch([teredoEnabled state]) {
		case NSOnState:
			err=MiredoStart([[comboAuthButton authorization] authorizationRef]);
			break;
		case NSOffState:
			err=MiredoStop([[comboAuthButton authorization] authorizationRef]);
			break;
		default:
			break;
	}

    if(err!=noErr) {
        
        
        [   [NSAlert
                alertWithError:[NSError
                    errorWithDomain:NSOSStatusErrorDomain
                    code:err
                    userInfo:nil
                ]        
            ]
            beginSheetModalForWindow:[[self mainView] window]
            modalDelegate:self
            didEndSelector:nil
            contextInfo:NULL
        ];
    }
}


@end
