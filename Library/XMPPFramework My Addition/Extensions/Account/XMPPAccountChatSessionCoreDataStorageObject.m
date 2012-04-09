//
//  XMPPAccountChatSessionCoreDataStorageObject.m
//  TinyChatter
//
//  Created by jj on 12/4/9.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "XMPPAccountChatSessionCoreDataStorageObject.h"
#import "XMPPAccountChatLogCoreDataStorageObject.h"
#import "XMPPAccountCoreDataStorageObject.h"


@implementation XMPPAccountChatSessionCoreDataStorageObject

@dynamic addedDate;
@dynamic lastActiveDate;
@dynamic recipientJid;
@dynamic account;
@dynamic chatLogs;

+ (XMPPAccountChatSessionCoreDataStorageObject *)getChatSessionIfExistWithRecipientJid:(NSString *)aJid inManagedObjectContext:(NSManagedObjectContext *)context
{
    XMPPAccountChatSessionCoreDataStorageObject *chatSession = nil;
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    request.entity = [NSEntityDescription entityForName:@"XMPPAccountChatSessionCoreDataStorageObject" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"recipientJid = %@", aJid];
    
    NSError *error = nil;
    chatSession = [[context executeFetchRequest:request error:&error] lastObject];
    
    if(!error && !chatSession)
        return nil;
    
    return chatSession;
}

+ (XMPPAccountChatSessionCoreDataStorageObject *)getOrCreateChatSessionWithRecipientJid:(NSString *)aJid account:(XMPPAccountCoreDataStorageObject *)anAccount inManagedObjectContext:(NSManagedObjectContext *)context
{
    XMPPAccountChatSessionCoreDataStorageObject *chatSession = [XMPPAccountChatSessionCoreDataStorageObject getChatSessionIfExistWithRecipientJid:aJid inManagedObjectContext:context];
    
    if(chatSession == nil) {
        chatSession = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPAccountChatSessionCoreDataStorageObject" inManagedObjectContext:context];
        chatSession.recipientJid = aJid;
        chatSession.account = anAccount;
    }
    
    return chatSession;
}

@end
