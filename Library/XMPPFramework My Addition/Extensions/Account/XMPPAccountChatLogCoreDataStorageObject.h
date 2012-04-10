//
//  XMPPAccountChatLogCoreDataStorageObject.h
//  TinyChatter
//
//  Created by jj on 12/4/9.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class XMPPAccountChatSessionCoreDataStorageObject;

@interface XMPPAccountChatLogCoreDataStorageObject : NSManagedObject

@property (nonatomic, retain) NSDate * addedDate;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSNumber * delivered;
@property (nonatomic, retain) NSString * fromJidStr;
@property (nonatomic, retain) NSString * jsonSpec;
@property (nonatomic, retain) NSNumber * readByRecipient;
@property (nonatomic, retain) NSString * toJidStr;
@property (nonatomic, retain) NSString * sessionId;
@property (nonatomic, retain) NSNumber * fromMe;
@property (nonatomic, retain) XMPPAccountChatSessionCoreDataStorageObject *chatSession;

+ (XMPPAccountChatLogCoreDataStorageObject *)createChatLogWithChatSession:(XMPPAccountChatSessionCoreDataStorageObject *)aChatSession nManagedObjectContext:(NSManagedObjectContext *)context;

@end
