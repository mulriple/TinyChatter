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
@dynamic userId;
@dynamic chatSessions;
@dynamic settings;

+ (XMPPAccountCoreDataStorageObject *)getAccountIfExistWithJid:(NSString *)aJid inManagedObjectContext:(NSManagedObjectContext *)context
{
    XMPPAccountCoreDataStorageObject *account = nil;
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    request.entity = [NSEntityDescription entityForName:@"XMPPAccountCoreDataStorageObject" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"jidStr = %@", aJid];
    
    NSError *error = nil;
    account = [[context executeFetchRequest:request error:&error] lastObject];
    
    if(!error && !account)
        return nil;
    
    return account;
}

+ (XMPPAccountCoreDataStorageObject *)getOrCreateAccountWithJid:(NSString *)aJid inManagedObjectContext:(NSManagedObjectContext *)context
{
    XMPPAccountCoreDataStorageObject *account = [XMPPAccountCoreDataStorageObject getAccountIfExistWithJid:aJid inManagedObjectContext:context];
    
    if(account == nil) {
        account = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPAccountCoreDataStorageObject" inManagedObjectContext:context];
        account.jidStr = aJid;
    }
    
    return account;
}

@end
