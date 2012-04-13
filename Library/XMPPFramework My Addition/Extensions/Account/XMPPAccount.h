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

#define _XMPP_CAPABILITIES_H

typedef enum {
    XMPPAccountChatStatusActive,
    XMPPAccountChatStatusInActive,
    XMPPAccountChatStatusPaused,
    XMPPAccountChatStatusComposing,
    XMPPAccountChatStatusGone,
}XMPPAccountChatStatus;

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

- (void)sendMessage:(NSString *)msg to:(NSString *)toJid from:(NSString *)fromJid;
- (void)sendMessageReadNotification:(NSString *)msgId to:(NSString *)toJid from:(NSString *)fromJid;
- (void)sendChatStatus:(XMPPAccountChatStatus)aStatus to:(NSString *)toJid from:(NSString *)fromJid;

@end


@protocol XMPPAccountStorage <NSObject>
@required

- (BOOL)configureWithParent:(XMPPAccount *)aParent queue:(dispatch_queue_t)queue;
- (void)handleAuthenticateSuccessful:(XMPPStream *)xmppStream;
- (void)handleIncomingMessage:(XMPPMessage *)message xmppStream:(XMPPStream *)xmppStream;
- (void)handleOutgoingMessage:(XMPPMessage *)message xmppStream:(XMPPStream *)xmppStream;
- (void)handleMessageDeliveredNotificationWithMessageId:(NSString *)anId;
- (void)handleIncomingChatStatusMessage:(XMPPMessage *)message xmppStream:(XMPPStream *)xmppStream;

@optional

@end