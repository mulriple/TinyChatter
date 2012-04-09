//
//  XMPPAccountCoreDataStorageObject.m
//  TinyChatter
//
//  Created by jj on 12/4/9.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "XMPPAccountCoreDataStorageObject.h"
#import "XMPPAccountChatSessionCoreDataStorageObject.h"
#import "XMPPAccountSettingsCoreDataStorageObject.h"


@implementation XMPPAccountCoreDataStorageObject

@dynamic accountType;
@dynamic domain;
@dynamic id;
@dynamic jidStr;
@dynamic jsonSpec;
@dynamic lastSignInTime;
@dynamic pwd;
@dynamic chatSessions;
@dynamic settings;

@end
