//
//  XMPPAccountChatSessionCoreDataStorageObject.h
//  TinyChatter
//
//  Created by jj on 12/4/9.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class XMPPAccountChatLogCoreDataStorageObject, XMPPAccountCoreDataStorageObject;

@interface XMPPAccountChatSessionCoreDataStorageObject : NSManagedObject

@property (nonatomic, retain) NSDate                            * addedDate;
@property (nonatomic, retain) NSDate                            * lastActiveDate;
@property (nonatomic, retain) NSString                          * recipientJid;
@property (nonatomic, retain) NSString                          * latestMessage;
@property (nonatomic, retain) NSString                          * accountJid;
@property (nonatomic, retain) NSString                          * sessionId;
@property (nonatomic, retain) NSString                          * recipientStatus;
@property (nonatomic, retain) XMPPAccountCoreDataStorageObject  * account;
@property (nonatomic, retain) NSSet                             * chatLogs;

+ (XMPPAccountChatSessionCoreDataStorageObject *)getChatSessionIfExistWithSessionId:(NSString *)anID inManagedObjectContext:(NSManagedObjectContext *)context;
+ (XMPPAccountChatSessionCoreDataStorageObject *)getOrCreateChatSessionWithRecipientJid:(NSString *)aJid account:(XMPPAccountCoreDataStorageObject *)anAccount inManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSString *)createSessionIdFromSelfJidBare:(NSString *)aSelfJidBare recipientJidBare:(NSString *)aRecipientJidBare;

@end

@interface XMPPAccountChatSessionCoreDataStorageObject (CoreDataGeneratedAccessors)

- (void)addChatLogsObject:(XMPPAccountChatLogCoreDataStorageObject *)value;
- (void)removeChatLogsObject:(XMPPAccountChatLogCoreDataStorageObject *)value;
- (void)addChatLogs:(NSSet *)values;
- (void)removeChatLogs:(NSSet *)values;

@end
