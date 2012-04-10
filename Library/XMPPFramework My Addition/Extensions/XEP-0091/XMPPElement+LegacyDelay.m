//
//  XMPPElement+LegacyDelay.m
//  TinyChatter
//
//  Created by jj on 12/4/10.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "XMPPElement+LegacyDelay.h"
#import "XMPPDateTimeProfiles.h"
#import "NSXMLElement+XMPP.h"

@implementation XMPPElement (XEP0091)

- (BOOL)wasDelayedLegacy
{
    NSXMLElement *delay;
    
    delay = [self elementForName:@"x" xmlns:@"jabber:x:delay"];
    if (delay)
    {
        return YES;
    }
    
    return NO;
}

- (NSDate *)delayedDeliveryDateLegacy
{
	NSXMLElement *delay;
	
	// From XEP-0091 (Delayed Delivery LEGACY)
	// 
	// <x xmlns="jabber:x:delay" stamp="20120409T05:26:44"/>
    // <time xmlns="google:timestamp" ms="1333949204426"/>
    //
	// The format [of the stamp attribute] MUST adhere to the dateTime format
	// specified in XEP-0091 and MUST be expressed in UTC.
	delay = [self elementForName:@"x" xmlns:@"jabber:x:delay"];
	if (delay)
	{
		NSDate *stamp;
		
		NSString *stampValue = [delay attributeStringValueForName:@"stamp"];
		
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[dateFormatter setDateFormat:@"yyyyMMdd'T'HH:mm:ss"];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
		
		stamp = [dateFormatter dateFromString:stampValue];
		[dateFormatter release];
        
		return stamp;
	}
	
	return nil;
}

@end

