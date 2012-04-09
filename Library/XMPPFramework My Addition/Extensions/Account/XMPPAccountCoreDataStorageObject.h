//
//  XMPPAccountCoreDataStorageObject.h
//  TinyChatter
//
//  Created by jj on 12/4/9.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class XMPPAccountChatSessionCoreDataStorageObject, XMPPAccountSettingsCoreDataStorageObject;

@interface XMPPAccountCoreDataStorageObject : NSManagedObject

@property (nonatomic, retain) NSString * accountType;
@property (nonatomic, retain) NSString * domain;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * jidStr;
@property (nonatomic, retain) NSString * jsonSpec;
@property (nonatomic, retain) NSDate * lastSignInTime;
@property (nonatomic, retain) NSString * pwd;
@property (nonatomic, retain) NSSet *chatSessions;
@property (nonatomic, retain) XMPPAccountSettingsCoreDataStorageObject *settings;
@end

@interface XMPPAccountCoreDataStorageObject (CoreDataGeneratedAccessors)

- (void)addChatSessionsObject:(XMPPAccountChatSessionCoreDataStorageObject *)value;
- (void)removeChatSessionsObject:(XMPPAccountChatSessionCoreDataStorageObject *)value;
- (void)addChatSessions:(NSSet *)values;
- (void)removeChatSessions:(NSSet *)values;

@end
