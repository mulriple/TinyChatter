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
@dynamic latestMessage;
@dynamic accountJid;
@dynamic sessionId;
@dynamic account;
@dynamic chatLogs;
@dynamic recipientStatus;

+ (XMPPAccountChatSessionCoreDataStorageObject *)getChatSessionIfExistWithSessionId:(NSString *)anID inManagedObjectContext:(NSManagedObjectContext *)context
{
    XMPPAccountChatSessionCoreDataStorageObject *chatSession = nil;
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    request.entity = [NSEntityDescription entityForName:@"XMPPAccountChatSessionCoreDataStorageObject" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"sessionId = %@", anID];
    
    NSError *error = nil;
    chatSession = [[context executeFetchRequest:request error:&error] lastObject];
    
    if(!error && !chatSession)
        return nil;
    
    return chatSession;
}

+ (XMPPAccountChatSessionCoreDataStorageObject *)getOrCreateChatSessionWithRecipientJid:(NSString *)aJid account:(XMPPAccountCoreDataStorageObject *)anAccount inManagedObjectContext:(NSManagedObjectContext *)context;
{
    //NSString *sessionId = [NSString stringWithFormat:@"%@ %@", anAccount.jidStr, aJid];
    NSString *sessionId = [self createSessionIdFromSelfJidBare:anAccount.jidStr recipientJidBare:aJid];
    
    XMPPAccountChatSessionCoreDataStorageObject *chatSession = [XMPPAccountChatSessionCoreDataStorageObject getChatSessionIfExistWithSessionId:sessionId inManagedObjectContext:context];
    
    if(chatSession == nil) {
        chatSession = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPAccountChatSessionCoreDataStorageObject" inManagedObjectContext:context];
        chatSession.recipientJid = aJid;
        chatSession.account = anAccount;
        chatSession.accountJid = anAccount.jidStr;
        chatSession.addedDate = [NSDate date];
        chatSession.sessionId = sessionId;
    }
    
    return chatSession;
}

+ (NSString *)createSessionIdFromSelfJidBare:(NSString *)aSelfJidBare recipientJidBare:(NSString *)aRecipientJidBare
{
    return [NSString stringWithFormat:@"%@ %@", aSelfJidBare, aRecipientJidBare];
}

@end
