//
//  XMPPElement+LegacyDelay.h
//  TinyChatter
//
//  Created by jj on 12/4/10.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "XMPPElement.h"

@interface XMPPElement (XEP0091)

- (BOOL)wasDelayedLegacy;
- (NSDate *)delayedDeliveryDateLegacy;

@end
