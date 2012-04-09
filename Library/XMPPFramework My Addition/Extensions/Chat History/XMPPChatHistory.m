//
//  XMPPChatHistory.m
//  TinyChatter
//
//  Created by ling tsu hsuan on 4/7/12.
//  Copyright (c) 2012 jtg2078@hotmail.com. All rights reserved.
//

#import "XMPPChatHistory.h"
#import "XMPPFramework.h"
#import "XMPPIDTracker.h"
#import "XMPPMessage+XEP0045.h"
#import "XMPPLogging.h"

// Log levels: off, error, warn, info, verbose
// Log flags: trace
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

@implementation XMPPChatHistory

- (id)initWithChatHistoryStorage:(id <XMPPChatHistoryStorage>)storage
{
	return [self initWithChatHistoryStorage:storage dispatchQueue:NULL];
}

- (id)initWithChatHistoryStorage:(id <XMPPChatHistoryStorage>)storage dispatchQueue:(dispatch_queue_t)queue
{
	NSParameterAssert(storage != nil);
	
	if ((self = [super initWithDispatchQueue:queue]))
	{
		if ([storage configureWithParent:self queue:moduleQueue])
		{
			xmppChatHistoryStorage = storage;
		}
		else
		{
			XMPPLogError(@"%@: %@ - Unable to configure storage!", THIS_FILE, THIS_METHOD);
		}
	}
	return self;
}

- (BOOL)activate:(XMPPStream *)aXmppStream
{
	if ([super activate:aXmppStream])
	{
		responseTracker = [[XMPPIDTracker alloc] initWithDispatchQueue:moduleQueue];
		
		return YES;
	}
	
	return NO;
}

- (void)deactivate
{
	XMPPLogTrace();
	
	dispatch_block_t block = ^{ @autoreleasepool {
		
		[responseTracker removeAllIDs];
		responseTracker = nil;
		
	}};
	
	if (dispatch_get_current_queue() == moduleQueue)
		block();
	else
		dispatch_sync(moduleQueue, block);
	
	[super deactivate];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Internal
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method may optionally be used by XMPPRosterStorage classes (method declared in XMPPRosterPrivate.h)
 **/
- (dispatch_queue_t)moduleQueue
{
	return moduleQueue;
}

/**
 * This method may optionally be used by XMPPRosterStorage classes (method declared in XMPPRosterPrivate.h).
 **/
- (GCDMulticastDelegate *)multicastDelegate
{
	return multicastDelegate;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id <XMPPChatHistoryStorage>)xmppChatHistoryStorage
{
	// This variable is readonly - set in init method and never changed.
	return xmppChatHistoryStorage;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Messages
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)sendMessage:(NSString *)msg to:(NSString *)toJid
{
	if ([msg length] == 0) return;
	
	dispatch_block_t block = ^{ @autoreleasepool {
		
		XMPPLogTrace();
		
		// <message type='groupchat' to='darkcave@chat.shakespeare.lit/firstwitch'>
		//   <body>I'll give thee a wind.</body>
		// </message>
        
		NSXMLElement *body = [NSXMLElement elementWithName:@"body" stringValue:msg];
		
		XMPPMessage *message = [XMPPMessage message];
		[message addAttributeWithName:@"to" stringValue:toJid];
		[message addAttributeWithName:@"type" stringValue:@"chat"];
		[message addChild:body];
		
		[xmppStream sendElement:message];
		
	}};
	
	if (dispatch_get_current_queue() == moduleQueue)
		block();
	else
		dispatch_async(moduleQueue, block);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	// This method is invoked on the moduleQueue.
	
	XMPPLogTrace();
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	// This method is invoked on the moduleQueue.
	
	XMPPLogTrace();
	
	// Is this a message we need to store (a chat message)?
	// 
	// A message to all recipients MUST be of type groupchat.
	// A message to an individual recipient would have a <body/>.
	
	BOOL isChatMessage = [message isChatMessageWithBody];
	
	if (isChatMessage)
	{
		[xmppChatHistoryStorage handleIncomingMessage:message xmppStream:sender];
	}
	else
	{
		// Todo... Handle other types of messages.
	}
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
	// This method is invoked on the moduleQueue.
	
	XMPPLogTrace();
	
	// Is this a message we need to store (a chat message)?
	// 
	// A message to all recipients MUST be of type groupchat.
	// A message to an individual recipient would have a <body/>.
	
	BOOL isChatMessage = [message isChatMessageWithBody];
	
	if (isChatMessage)
	{
		[xmppChatHistoryStorage handleOutgoingMessage:message xmppStream:sender];	
	}
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	// This method is invoked on the moduleQueue.
	
	XMPPLogTrace();
	
	[responseTracker removeAllIDs];
}

@end

