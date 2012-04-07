//
//  XMPPChatHistoryCoreDataStorageObject.h
//  TinyChatter
//
//  Created by ling tsu hsuan on 4/8/12.
//  Copyright (c) 2012 jtg2078@hotmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "XMPP.h"


@interface XMPPChatHistoryCoreDataStorageObject : NSManagedObject

@property (nonatomic, retain) NSString      * displayName;
@property (nonatomic, retain) XMPPJID       * jid;              // Transient (proper type, not on disk)
@property (nonatomic, retain) NSString      * jidStr;           // Shadow (binary data, written to disk)
@property (nonatomic, retain) NSString      * nickname;
@property (nonatomic, retain) NSString      * streamBareJidStr;
@property (nonatomic, retain) NSString      * lastMessage;
@property (nonatomic, retain) NSDate        * lastMessageTime;
@property (nonatomic, retain) NSNumber      * lastMessageIsFromMe;
@property (nonatomic, assign) BOOL          isLastMessageFromMe;

@end