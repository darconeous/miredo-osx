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
        { "system.preferences" }
    };
    AuthorizationItemSet	rights = { sizeof(*_rights)/sizeof(_rights), _rights };

    [comboAuthButton setAuthorizationRights:&rights];
    [comboAuthButton setDelegate:self];
    [comboAuthButton updateStatus:nil];
    [comboAuthButton setAutoupdate:YES];

	EnsureToolInstalled();

    settings=[[NSMutableDictionary dictionaryWithCapacity:20] retain];

	redLight=[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"red" ofType:@"tiff"]];
	yellowLight=[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"yellow" ofType:@"tiff"]];
	greenLight=[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"green" ofType:@"tiff"]];

	if([self isMiredoEnabled]) {
		[teredoEnabled setState:NSOnState];
	} else {
		[teredoEnabled setState:NSOffState];
	}

    [self readSettings];
	[self refresh];
	
}

- (BOOL)isMiredoRunning {
	return system("/sbin/ifconfig tun0")==0;
}

- (BOOL)isMiredoEnabled {
	CFPropertyListRef propertyList;
	CFURLRef fileURL;
	CFDataRef         resourceData;
	Boolean           status;
	SInt32            errorCode=0;

	BOOL ret=NO;

	fileURL = CFURLCreateWithFileSystemPath( kCFAllocatorDefault,    
			   CFSTR("/Library/LaunchDaemons/miredo.plist"),       // file path name
			   kCFURLPOSIXPathStyle,    // interpret as POSIX path        
			   false );                 // is it a directory?

	status = CFURLCreateDataAndPropertiesFromResource(
			   kCFAllocatorDefault,
			   fileURL,
			   &resourceData,            // place to put file data
			   NULL,      
			   NULL,
			   &errorCode);
	require( status==YES, ReadPropertyListFailed);
	
	propertyList = CFPropertyListCreateFromXMLData( kCFAllocatorDefault,
			   resourceData,
			   kCFPropertyListMutableContainersAndLeaves,
			   NULL);

	if(!CFDictionaryGetCountOfKey(propertyList,CFSTR("Disabled"))) {
		ret=YES;
	} else if(CFDictionaryGetValue(propertyList,CFSTR("Disabled"))==kCFBooleanFalse) {
		ret=YES;
	}
	
ReadPropertyListFailed:
	CFRelease(resourceData);
	CFRelease(fileURL);
	CFRelease(propertyList);
	return ret;
}

- (void) refresh {
	if([self isMiredoRunning]) {
		[statusLight setImage:greenLight];
	} else {
		[statusLight setImage:redLight];
	}
	[currentAddress setStringValue:@"(Unavailable)"];
}

- (void) dealloc
{
    [settings release];
	[redLight release];
	[yellowLight release];
	[greenLight release];
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

- (IBAction)modeChanged:(id)sender {
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
			if(![self isMiredoEnabled])
				err=MiredoStart([[comboAuthButton authorization] authorizationRef]);
			break;
		case NSOffState:
			if([self isMiredoEnabled])
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
	sleep(1);
	[self refresh];
}


@end
