/*
 *  MiredoConfig.h
 *  MiredoPreferencePane
 *
 *  Created by Robert Quattlebaum on 2/19/07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

extern NSDictionary* MiredoConfigLoad(NSString* filename);
extern BOOL MiredoConfigSave(NSString* filename,NSDictionary* data,NSError** error);
