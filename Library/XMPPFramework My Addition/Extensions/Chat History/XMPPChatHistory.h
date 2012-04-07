//
//  XMPPChatHistory.h
//  TinyChatter
//
//  Created by ling tsu hsuan on 4/7/12.
//  Copyright (c) 2012 jtg2078@hotmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPP.h"

#define _XMPP_CHAT_HISTORY_H

/**
 * The XMPPChatHistory module, combined associated storage classes,
 * provides an implementation of chat history persistence mechanism
 * 
 * 
 * The XMPPChatHistory class provides the following general tasks:
 *  - It integrates with XMPPCapabilities (if available) to properly advertise support for MUC.
 *  - It monitors active XMPPRoom instances on the xmppStream,
 *    and provides an efficient query to see if a presence or message element is targeted at a room.
 *  - It listens for MUC room invitations sent from other users.
 **/
@class XMPPIDTracker;
@protocol XMPPChatHistoryStorage;
@interface XMPPChatHistory : XMPPModule 
{
    XMPPIDTracker *responseTracker;
    id <XMPPChatHistoryStorage> xmppChatHistoryStorage;
	
	uint16_t state;
}

- (id)initWithChatHistoryStorage:(id <XMPPChatHistoryStorage>)storage;
- (id)initWithChatHistoryStorage:(id <XMPPChatHistoryStorage>)storage dispatchQueue:(dispatch_queue_t)queue;


#pragma mark Properties

@property (readonly) id <XMPPChatHistoryStorage> xmppChatHistoryStorage;

#pragma mark Chat Interaction

- (void)sendMessage:(NSString *)msg to:(NSString *)toJid;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol XMPPChatHistoryStorage <NSObject>
@required

- (BOOL)configureWithParent:(XMPPChatHistory *)aParent queue:(dispatch_queue_t)queue;

- (void)handleIncomingMessage:(XMPPMessage *)message xmppStream:(XMPPStream *)xmppStream;
- (void)handleOutgoingMessage:(XMPPMessage *)message xmppStream:(XMPPStream *)xmppStream;

@optional

@end