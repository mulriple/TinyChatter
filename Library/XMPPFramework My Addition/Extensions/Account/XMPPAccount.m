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

@interface XMPPAccount()
- (NSString *)generateMessageID;
- (void)sendDeliveredNotification:(XMPPMessage *)sentMessage;
@end

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
#ifdef _XMPP_CAPABILITIES_H
		[xmppStream autoAddDelegate:self delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
#endif
		responseTracker = [[XMPPIDTracker alloc] initWithDispatchQueue:moduleQueue];
		
		return YES;
	}
	
	return NO;
}

- (void)deactivate
{
	XMPPLogTrace();
    
#ifdef _XMPP_CAPABILITIES_H
	[xmppStream removeAutoDelegate:self delegateQueue:moduleQueue fromModulesOfClass:[XMPPCapabilities class]];
#endif
	
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
        [message addAttributeWithName:@"id" stringValue:[self generateMessageID]];
		[message addChild:body];
		
		[xmppStream sendElement:message];
		
	}};
	
	if (dispatch_get_current_queue() == moduleQueue)
		block();
	else
		dispatch_async(moduleQueue, block);
}

- (void)sendMessageReadNotification:(NSString *)msgId to:(NSString *)toJid from:(NSString *)fromJid
{
    /*
     this is for generating and sending a notification to notify that the given message has been read(in the sense of displayed)
     
     <message xmlns="jabber:client" id="kHcFE-41" to="75214@mobile01.com" from="2128809@mobile01.com/Smack">
        <x xmlns="jabber:x:event">
        <displayed />
            <id>20120402_75214_150647</id>
        </x>
     </message>
     
     */
    
    dispatch_block_t block = ^{ @autoreleasepool {
		
		XMPPLogTrace();
		
		NSXMLElement *event = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:event"];
        [event addChild:[NSXMLElement elementWithName:@"displayed"]];
        [event addChild:[NSXMLElement elementWithName:@"id" stringValue:msgId]];
        
        
        XMPPMessage *deliveredMessage = [XMPPMessage message];
        [deliveredMessage addAttributeWithName:@"to" stringValue:toJid];
        [deliveredMessage addAttributeWithName:@"from" stringValue:fromJid];
        [deliveredMessage addAttributeWithName:@"type" stringValue:@"chat"];
        [deliveredMessage addChild:event];
        
        [xmppStream sendElement:deliveredMessage];
		
	}};
	
	if (dispatch_get_current_queue() == moduleQueue)
		block();
	else
		dispatch_async(moduleQueue, block);
}

- (NSString *)generateMessageID
{
    return [NSString stringWithFormat:@"tinychatter_%f", [[NSDate date] timeIntervalSince1970]];
}

- (void)sendDeliveredNotification:(XMPPMessage *)sentMessage
{
    /*
     this is the format of the notification message to indicate the message has been successfully delivered to server
     notice that the id has to be the same as the sent message
     //
     
     <message to="123@abc.com" from="456@cde.com">
        <x xmlns="jabber:x:event">
            <delivered/>
            <id>tinychatter_1334209080.328546</id>
        </x>
     </message>
     */
    
    dispatch_block_t block = ^{ @autoreleasepool {
		
		XMPPLogTrace();
		
		NSString *messageId = [sentMessage attributeStringValueForName:@"id"];
        NSString *sentTo = sentMessage.toStr;
        NSString *sentFrom = sentMessage.fromStr;
        
        NSXMLElement *event = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:event"];
        [event addChild:[NSXMLElement elementWithName:@"delivered"]];
        [event addChild:[NSXMLElement elementWithName:@"id" stringValue:messageId]];
        
        XMPPMessage *deliveredMessage = [XMPPMessage message];
        [deliveredMessage addAttributeWithName:@"to" stringValue:sentTo];
        [deliveredMessage addAttributeWithName:@"from" stringValue:sentFrom];
        [deliveredMessage addChild:event];
        
        [xmppStream sendElement:deliveredMessage];
	}};
	
	if (dispatch_get_current_queue() == moduleQueue)
		block();
	else
		dispatch_async(moduleQueue, block);
}

- (void)sendChatStatus:(XMPPAccountChatStatus)aStatus to:(NSString *)toJid from:(NSString *)fromJid;
{
    /*
     <message 
        from='romeo@montague.net/orchard' 
        to='juliet@capulet.com/balcony'
        type='chat'>
            <thread>act2scene2chat1</thread>
            <composing xmlns='http://jabber.org/protocol/chatstates'/>
     </message>
     */
    
    /*
     <message 
        from='romeo@montague.net/orchard' 
        to='juliet@capulet.com/balcony'
        type='chat'>
            <thread>act2scene2chat1</thread>
            <paused xmlns='http://jabber.org/protocol/chatstates'/>
     </message>
     */
    
    /*
     Chat State	Requirement
     <active/>	MUST
     <composing/>	MUST
     <paused/>	SHOULD
     <inactive/>	SHOULD
     <gone/>	SHOULD
     */
    dispatch_block_t block = ^{ @autoreleasepool {
		
		XMPPLogTrace();
		
		XMPPMessage *statusMessage = [XMPPMessage message];
        [statusMessage addAttributeWithName:@"to" stringValue:toJid];
        [statusMessage addAttributeWithName:@"from" stringValue:fromJid];
        [statusMessage addAttributeWithName:@"type" stringValue:@"chat"];
        
        switch (aStatus) {
            case XMPPAccountChatStatusActive:
                [statusMessage addChild:[NSXMLElement elementWithName:@"active" xmlns:@"http://jabber.org/protocol/chatstates"]];
                break;
            case XMPPAccountChatStatusInActive:
                [statusMessage addChild:[NSXMLElement elementWithName:@"inactive" xmlns:@"http://jabber.org/protocol/chatstates"]];
                break;
            case XMPPAccountChatStatusPaused:
                [statusMessage addChild:[NSXMLElement elementWithName:@"paused" xmlns:@"http://jabber.org/protocol/chatstates"]];
                break;
            case XMPPAccountChatStatusComposing:
                [statusMessage addChild:[NSXMLElement elementWithName:@"composing" xmlns:@"http://jabber.org/protocol/chatstates"]];
                break;
                
            default:
                [statusMessage addChild:[NSXMLElement elementWithName:@"gone" xmlns:@"http://jabber.org/protocol/chatstates"]];
                break;
        }
        
		[xmppStream sendElement:statusMessage];
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
    else if([message isChatMessage])
    {
        [xmppAccountStorage handleIncomingChatStatusMessage:message xmppStream:sender];
    }
}

- (void)xmppStream:(XMPPStream *)sender willSendMessage:(XMPPMessage *)message
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

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
	// This method is invoked on the moduleQueue.
	
	XMPPLogTrace();
    
	BOOL isChatMessage = [message isChatMessageWithBody];
	
	if (isChatMessage)
	{
        [self sendDeliveredNotification:message];
        
        NSString *messageId = [message attributeStringValueForName:@"id"];
        
        if(messageId) {
            [xmppAccountStorage handleMessageDeliveredNotificationWithMessageId:messageId];
        }
	}
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	// This method is invoked on the moduleQueue.
	
	XMPPLogTrace();
	
	[responseTracker removeAllIDs];
}

#ifdef _XMPP_CAPABILITIES_H
/**
 * If an XMPPCapabilites instance is used we want to advertise our support for Chat State Notifications XEP-0085.
 **/
- (void)xmppCapabilities:(XMPPCapabilities *)sender collectingMyCapabilities:(NSXMLElement *)query
{
	// This method is invoked on our moduleQueue.
	
	// <query xmlns="http://jabber.org/protocol/disco#info">
	//   ...
	//   <feature var='http://jabber.org/protocol/chatstates'/>
	//   ...
	// </query>
	
	NSXMLElement *feature = [NSXMLElement elementWithName:@"feature"];
	[feature addAttributeWithName:@"var" stringValue:@"http://jabber.org/protocol/chatstates"];
	
	[query addChild:feature];
}
#endif

@end