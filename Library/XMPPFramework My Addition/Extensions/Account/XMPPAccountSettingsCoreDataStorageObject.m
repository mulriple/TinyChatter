//
//  XMPPAccountSettingsCoreDataStorageObject.m
//  TinyChatter
//
//  Created by jj on 12/4/9.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "XMPPAccountSettingsCoreDataStorageObject.h"
#import "XMPPAccountCoreDataStorageObject.h"


@implementation XMPPAccountSettingsCoreDataStorageObject

@dynamic email;
@dynamic enablePush;
@dynamic phone;
@dynamic rememberPwd;
@dynamic rememberUserId;
@dynamic userId;
@dynamic account;
@dynamic jidStr;

+ (XMPPAccountSettingsCoreDataStorageObject *)getAccountSettingsIfExistWithJid:(NSString *)aJid inManagedObjectContext:(NSManagedObjectContext *)context
{
    XMPPAccountSettingsCoreDataStorageObject *settings = nil;
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    request.entity = [NSEntityDescription entityForName:@"XMPPAccountSettingsCoreDataStorageObject" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"jidStr = %@", aJid];
    
    NSError *error = nil;
    settings = [[context executeFetchRequest:request error:&error] lastObject];
    
    if(!error && !settings)
        return nil;
    
    return settings;
}

+ (XMPPAccountSettingsCoreDataStorageObject *)getOrCreateSettingsWithJid:(NSString *)aJid account:(XMPPAccountCoreDataStorageObject *)anAccount inManagedObjectContext:(NSManagedObjectContext *)context
{
    XMPPAccountSettingsCoreDataStorageObject *settings = [XMPPAccountSettingsCoreDataStorageObject getAccountSettingsIfExistWithJid:aJid inManagedObjectContext:context];
    
    if(settings == nil) {
        settings = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPAccountSettingsCoreDataStorageObject" inManagedObjectContext:context];
        settings.jidStr = aJid;
        settings.account = anAccount;
    }
    
    return settings;
}

@end
