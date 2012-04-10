//
//  XMPPAccount.m
//  TinyChatter
//
//  Created by jj on 12/4/9.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "XMPPAccount.h"
#import "XMPPFramework.h"
#import "XMPPIDTracker.h"
#import "XMPPLogging.h"
#import "XMPPElement+Delay.h"
#import "XMPPElement+LegacyDelay.h"

// Log levels: off, error, warn, info, verbose
// Log flags: trace
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

@implementation XMPPAccount

- (id)initWithAccountStorage:(id <XMPPAccountStorage>)storage
{
	return [self initWithAccountStorage:storage dispatchQueue:NULL];
}

- (id)initWithAccountStorage:(id <XMPPAccountStorage>)storage dispatchQueue:(dispatch_queue_t)queue
{
	NSParameterAssert(storage != nil);
	
	if ((self = [super initWithDispatchQueue:queue]))
	{
		if ([storage configureWithParent:self queue:moduleQueue])
		{
			xmppAccountStorage = storage;
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

- (id <XMPPAccountStorage>)xmppAccountStorage
{
	// This variable is readonly - set in init method and never changed.
	return xmppAccountStorage;
}

#pragma mark - Message

- (void)sendMessage:(NSString *)msg to:(NSString *)toJid from:(NSString *)fromJid
{
	if ([msg length] == 0) return;
	
	dispatch_block_t block = ^{ @autoreleasepool {
		
		XMPPLogTrace();
		
		// <message type='chat' to='darkcave@chat.shakespeare.lit/firstwitch'>
		//   <body>I'll give thee a wind.</body>
		// </message>
        
		NSXMLElement *body = [NSXMLElement elementWithName:@"body" stringValue:msg];
		
		XMPPMessage *message = [XMPPMessage message];
		[message addAttributeWithName:@"to" stringValue:toJid];
        [message addAttributeWithName:@"from" stringValue:fromJid];
		[message addAttributeWithName:@"type" stringValue:@"chat"];
		[message addChild:body];
		
		[xmppStream sendElement:message];
		
	}};
	
	if (dispatch_get_current_queue() == moduleQueue)
		block();
	else
		dispatch_async(moduleQueue, block);
}

#pragma mark - XMPPStream Delegate

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	// This method is invoked on the moduleQueue.
	
	XMPPLogTrace();
    
    [xmppAccountStorage handleAuthenticateSuccessful:sender];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	// This method is invoked on the moduleQueue.
	
	XMPPLogTrace();
    
    if([message isChatMessageWithBody] || [message wasDelayed] || [message wasDelayedLegacy])
    {
        [xmppAccountStorage handleIncomingMessage:message xmppStream:sender];
    }
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
	// This method is invoked on the moduleQueue.
	
	XMPPLogTrace();
	
	// Is this a message we need to store (a chat message)?
	BOOL isChatMessage = [message isChatMessageWithBody];
	
	if (isChatMessage)
	{
		[xmppAccountStorage handleOutgoingMessage:message xmppStream:sender];	
	}
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	// This method is invoked on the moduleQueue.
	
	XMPPLogTrace();
	
	[responseTracker removeAllIDs];
}

@end