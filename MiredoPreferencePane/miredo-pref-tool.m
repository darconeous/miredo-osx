/*
    Copyright: (c) Copyright 2005 Apple Computer, Inc. All rights reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Computer, Inc.
    ("Apple") in consideration of your agreement to the following terms, and your
    use, installation, modification or redistribution of this Apple software
    constitutes acceptance of these terms.  If you do not agree with these terms,
    please do not use, install, modify or redistribute this Apple software.

    In consideration of your agreement to abide by the following terms, and subject
    to these terms, Apple grants you a personal, non-exclusive license, under Apple's
    copyrights in this original Apple software (the "Apple Software"), to use,
    reproduce, modify and redistribute the Apple Software, with or without
    modifications, in source and/or binary forms; provided that if you redistribute
    the Apple Software in its entirety and without modifications, you must retain
    this notice and the following text and disclaimers in all such redistributions of
    the Apple Software.  Neither the name, trademarks, service marks or logos of
    Apple Computer, Inc. may be used to endorse or promote products derived from the
    Apple Software without specific prior written permission from Apple.  Except as
    expressly stated in this notice, no other rights or licenses, express or implied,
    are granted by Apple herein, including but not limited to any patent rights that
    may be infringed by your derivative works or by other works in which the Apple
    Software may be incorporated.

    The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
    WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
    WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
    PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
    COMBINATION WITH YOUR PRODUCTS.

    IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
    GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
    ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
    OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
    (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
    ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/
#import <stdio.h>
#import <stdint.h>
#import <stdlib.h>
#import <unistd.h>
#import <fcntl.h>
#import <errno.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <sys/mman.h>
#import <mach-o/dyld.h>
#import <AssertMacros.h>
#import <Security/Security.h>
#import <CoreServices/CoreServices.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <Foundation/Foundation.h>
#import "PrivilegedOperations.h"
#import "MiredoConfig.h"

static AuthorizationRef	gAuthRef = 0;

static int
readTaggedBlock(int fd, u_int32_t *pTag, u_int32_t *pLen, char **ppBuff)
// Read tag, block len and block data from stream and return. Dealloc *ppBuff via free().
{
	size_t		num;
	u_int32_t	tag, len;
	int			result = 0;

	num = read(fd, &tag, sizeof tag);
	require_action(num == sizeof tag, GetTagFailed, result = -1;);
	num = read(fd, &len, sizeof len);
	require_action(num == sizeof len, GetLenFailed, result = -1;);

	*ppBuff = (char*) malloc( len);
	require_action(*ppBuff != NULL, AllocFailed, result = -1;);

	num = read(fd, *ppBuff, len);
	if (num == len) {
		*pTag = tag;
		*pLen = len;
	} else {
		free(*ppBuff);
		result = -1;
	}

AllocFailed:
GetLenFailed:
GetTagFailed:
	return result;
}

static int
SetAuthInfo( int fd)
{
	int				result = 0;
	u_int32_t		tag, len;
	char			*p;

	result = readTaggedBlock( fd, &tag, &len, &p);
	require( result == 0, ReadParamsFailed);

	if (gAuthRef != 0) {
		(void) AuthorizationFree(gAuthRef, kAuthorizationFlagDestroyRights);
		gAuthRef = 0;
	}

	result = AuthorizationCreateFromExternalForm((AuthorizationExternalForm*) p, &gAuthRef);

	free( p);
ReadParamsFailed:
	return result;
}

static int
WriteConfiguration( int fd) {
	CFDictionaryRef      configDictionary;
	CFDataRef       configData;
	int				result = 0;
	u_int32_t		tag, len;
	char			*p;

	result = readTaggedBlock( fd, &tag, &len, &p);
	require( result == 0, ReadParamsFailed);

	configData = CFDataCreate(NULL, (const UInt8 *)p, len);
	configDictionary = (CFDictionaryRef)[NSUnarchiver unarchiveObjectWithData:(NSData *)configData];

    if(!MiredoConfigSave(@"/etc/miredo.conf",(NSDictionary*)configDictionary,NULL)) {
		result=-1;
	}

ReadParamsFailed:
	return result;
}

static int
EnableMiredo(BOOL enabled) {
	CFPropertyListRef propertyList;
	CFURLRef fileURL;
	CFDataRef         resourceData;
	Boolean           status;
	SInt32            errorCode=0;


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

	CFRelease( resourceData );

	CFDictionarySetValue(propertyList, CFSTR("Disabled"), enabled?kCFBooleanFalse:kCFBooleanTrue);

	resourceData = CFPropertyListCreateXMLData( kCFAllocatorDefault, propertyList );

	// Write the XML data to the file.
	status = CFURLWriteDataAndPropertiesToResource (
			   fileURL,                  // URL to use
			   resourceData,                  // data to write
			   NULL,   
			   &errorCode);            
	require( status==YES, WritePropertyListFailed);

ReadPropertyListFailed:
WritePropertyListFailed:
	CFRelease(resourceData);
	CFRelease(fileURL);
	CFRelease(propertyList);
	return errorCode;
}

int	main( int argc, char **argv)
/* argv[0] is the exec path; argv[1] is a fd for input data; argv[2]... are operation codes.
   The tool supports the following operations:
	V		-- exit with status PRIV_OP_TOOL_VERS
	A		-- read AuthInfo from input pipe
	EM		-- Start (enable) Miredo
	DM		-- Stop (disable) Miredo
	RM		-- Restart Miredo
	WC		-- Write Configuration
*/
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int	commFD = -1, iArg, result = 0;

	if ( 0 != setuid( 0))
	{
		fprintf(stderr,"Not SUID Root!\n");
		return -1;
	}

	if ( argc == 3 && 0 == strcmp( argv[2], "V"))
	{
		fprintf(stderr,"Returning version...\n");
		return PRIV_OP_TOOL_VERS;
	}

	if ( argc >= 1)
	{
		commFD = strtol( argv[1], NULL, 0);
		lseek( commFD, 0, SEEK_SET);
	}
	for ( iArg = 2; iArg < argc && result == 0; iArg++)
	{
		if ( 0 == strcmp( "A", argv[ iArg]))	// get auth info
		{
			fprintf(stderr,"Authenticating...\n");
			result = SetAuthInfo( commFD);
			if(result!=0) {
				fprintf(stderr,"Authentication failed!\n");
			}
		}
		else if ( 0 == strcmp( "EM", argv[ iArg]))	// Enable miredo
		{
			fprintf(stderr,"Starting Miredo...\n");
			result|=EnableMiredo(YES);
			result|= system("/bin/launchctl load /Library/LaunchDaemons/miredo.plist");
		}
        else if ( 0 == strcmp( "DM", argv[ iArg]))	// Disable miredo
		{
			fprintf(stderr,"Stopping Miredo...\n");
			result |= system("/bin/launchctl unload /Library/LaunchDaemons/miredo.plist");
			result |= system("/usr/bin/killall -9 miredo");
			result |= EnableMiredo(NO);
		}
		else if ( 0 == strcmp( "RM", argv[ iArg]))	// Restart miredo
		{
			fprintf(stderr,"Restarting Miredo...\n");
			result = system("/usr/bin/killall -9 miredo");
		}
		else if ( 0 == strcmp( "WC", argv[ iArg]))	// Write Configuration
		{
			fprintf(stderr,"Writing Configuration...\n");
			result = WriteConfiguration(commFD);
		}
	}
	[pool release];
	fprintf(stderr,"Tool finished!\n");
	return result;
}
