//
//  XMPPAccount.h
//  TinyChatter
//
//  Created by jj on 12/4/9.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPModule.h"
#import "XMPP.h"

#define _XMPP_ACCOUNT_H

@class XMPPIDTracker;
@protocol XMPPAccountStorage;
@interface XMPPAccount : XMPPModule 
{
    XMPPIDTracker *responseTracker;
    id <XMPPAccountStorage> xmppAccountStorage;
	
	uint16_t state;
}

- (id)initWithAccountStorage:(id <XMPPAccountStorage>)storage;
- (id)initWithAccountStorage:(id <XMPPAccountStorage>)storage dispatchQueue:(dispatch_queue_t)queue;


#pragma mark Properties

@property (readonly) id <XMPPAccountStorage> xmppAccountStorage;

#pragma mark Chat Interaction

- (void)sendMessage:(NSString *)msg to:(NSString *)toJid;

@end


@protocol XMPPAccountStorage <NSObject>
@required

- (BOOL)configureWithParent:(XMPPAccount *)aParent queue:(dispatch_queue_t)queue;

- (void)handleIncomingMessage:(XMPPMessage *)message xmppStream:(XMPPStream *)xmppStream;
- (void)handleOutgoingMessage:(XMPPMessage *)message xmppStream:(XMPPStream *)xmppStream;

@optional

@end