//
//  XMPPAccountCoreDataStorage.h
//  TinyChatter
//
//  Created by jj on 12/4/9.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "XMPPCoreDataStorage.h"
#import "XMPPAccountCoreDataStorageObject.h"
#import "XMPPAccountSettingsCoreDataStorageObject.h"
#import "XMPPAccountChatSessionCoreDataStorageObject.h"
#import "XMPPAccountChatLogCoreDataStorageObject.h"
#import "XMPPAccount.h"

@interface XMPPAccountCoreDataStorage : XMPPCoreDataStorage <XMPPAccountStorage>

@property (retain, readwrite) NSString *accountEntityName;
@property (retain, readwrite) NSString *accountSettingsEntityName;
@property (retain, readwrite) NSString *accountChatSessionEntityName;
@property (retain, readwrite) NSString *accountChatLogEntityName;

+ (XMPPAccountCoreDataStorage *)sharedInstance;

- (NSEntityDescription *)accountEntity:(NSManagedObjectContext *)managedObjectContext;
- (NSEntityDescription *)accountSettingsEntity:(NSManagedObjectContext *)managedObjectContext;
- (NSEntityDescription *)accountChatSessionEntity:(NSManagedObjectContext *)managedObjectContext;
- (NSEntityDescription *)accountChatLogEntity:(NSManagedObjectContext *)managedObjectContext;

@end
