/*
 *  MiredoConfig.m
 *  MiredoPreferencePane
 *
 *  Created by Robert Quattlebaum on 2/19/07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

#include "MiredoConfig.h"

NSDictionary* MiredoConfigLoad(NSString* filename) {
    NSDictionary* ret=[NSMutableDictionary dictionaryWithCapacity:20];
    NSString* miredo_config=[NSString
        stringWithContentsOfFile:filename
        encoding:NSUTF8StringEncoding
        error:NULL
    ];
    
    NSArray* lines=[miredo_config componentsSeparatedByString:@"\n"];
    
    NSEnumerator* enumerator=[lines objectEnumerator];
    NSString* line;
    
    while ((line = [enumerator nextObject])) {
        NSRange comment_range=[line
            rangeOfCharacterFromSet:[NSCharacterSet
                characterSetWithCharactersInString:@"#"
            ]
        ];
        if(comment_range.location!=NSNotFound) {
            // Remove comments
            line=[line substringToIndex:comment_range.location];
        }
        if(![line length]) {
            // Skip empty lines
            continue;
        }

        NSRange sep_range=[line
            rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]
        ];
        
        if(sep_range.location==NSNotFound) {
            // The key is seperated from the value by whitespace.
            // if there are no spaces, then this line is garbage.
            continue;
        }
        NSString* key=[line substringToIndex:sep_range.location];
        NSString* value=[[line
                substringFromIndex:sep_range.location
            ]
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]
        ];
        
        // Add the key and value to the dictionary
        [ret
            setValue:value
            forKey:key
        ];
    }
    
    return ret;
}

BOOL MiredoConfigSave(NSString* filename,NSDictionary* data,NSError** error) {
    NSMutableString* config_file=[NSMutableString stringWithCapacity:4096];
    NSEnumerator* enumerator=[data keyEnumerator];
    NSString* key;
    
    [config_file appendString:@"# Miredo Configuration File\n"];
    [config_file appendString:@"# Automatically generated from the miredo preference pane.\n\n"];
    
    while ((key = [enumerator nextObject])) {
        [config_file appendFormat:@"%@ %@\n",key,[data valueForKey:key]];
    }
    
    return [config_file
        writeToFile:filename
        atomically:YES
        encoding:NSUTF8StringEncoding
        error:error
    ];
    
    return YES;
}
