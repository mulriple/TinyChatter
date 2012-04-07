//
//  XMPPMessageCoreDataStorageObject.h
//  TinyChatter
//
//  Created by ling tsu hsuan on 4/7/12.
//  Copyright (c) 2012 jtg2078@hotmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "XMPP.h"

@interface XMPPMessageCoreDataStorageObject : NSManagedObject

@property (nonatomic, retain) NSString      * body;
@property (nonatomic, retain) XMPPJID       * jid;              // Transient (proper type, not on disk)
@property (nonatomic, retain) NSString      * jidStr;           // Shadow (binary data, written to disk)
@property (nonatomic, retain) NSDate        * localTimestamp;
@property (nonatomic, retain) XMPPMessage   * message;          // Transient (proper type, not on disk)
@property (nonatomic, retain) NSString      * messageStr;       // Shadow (binary data, written to disk)
@property (nonatomic, retain) NSString      * nickname;
@property (nonatomic, retain) NSDate        * remoteTimestamp;
@property (nonatomic, retain) NSString      * streamBareJidStr; // not used(probably)
@property (nonatomic, retain) NSNumber      * type;             // not used(for now)
@property (nonatomic, retain) NSNumber      * fromMe;
@property (nonatomic, assign) BOOL          isFromMe;

@end