//
//  XMPPAccountChatLogCoreDataStorageObject.m
//  TinyChatter
//
//  Created by jj on 12/4/9.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "XMPPAccountChatLogCoreDataStorageObject.h"
#import "XMPPAccountChatSessionCoreDataStorageObject.h"


@implementation XMPPAccountChatLogCoreDataStorageObject

@dynamic addedDate;
@dynamic body;
@dynamic delivered;
@dynamic fromJidStr;
@dynamic jsonSpec;
@dynamic readByRecipient;
@dynamic toJidStr;
@dynamic chatSession;
@dynamic sessionId;
@dynamic fromMe;

+ (XMPPAccountChatLogCoreDataStorageObject *)createChatLogWithChatSession:(XMPPAccountChatSessionCoreDataStorageObject *)aChatSession nManagedObjectContext:(NSManagedObjectContext *)context
{
    XMPPAccountChatLogCoreDataStorageObject *chatLog = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPAccountChatLogCoreDataStorageObject" inManagedObjectContext:context];
    chatLog.chatSession = aChatSession;
    chatLog.sessionId = aChatSession.sessionId;
    
    return chatLog;
}

@end
