//
//  XMPPAccountCoreDataStorage.m
//  TinyChatter
//
//  Created by jj on 12/4/9.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "XMPPAccountCoreDataStorage.h"
#import "XMPPCoreDataStorageProtected.h"
#import "XMPPElement+Delay.h"
#import "XMPPLogging.h"
#import "XMPPElement+LegacyDelay.h"


// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_VERBOSE | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

#define AssertPrivateQueue() \
NSAssert(dispatch_get_current_queue() == storageQueue, @"Private method: MUST run on storageQueue");

@interface XMPPAccountCoreDataStorage ()
{	
	NSString *accountEntityName;
    NSString *accountSettingsEntityName;
    NSString *accountChatSessionEntityName;
    NSString *accountChatLogEntityName;
}

@end

@implementation XMPPAccountCoreDataStorage

static XMPPAccountCoreDataStorage *sharedInstance;

+ (XMPPAccountCoreDataStorage *)sharedInstance
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		sharedInstance = [[XMPPAccountCoreDataStorage alloc] initWithDatabaseFilename:nil];
	});
	
	return sharedInstance;
}

- (void)commonInit
{
	XMPPLogTrace();
	[super commonInit];
	
	// This method is invoked by all public init methods of the superclass
    
    accountEntityName = NSStringFromClass([XMPPAccountCoreDataStorageObject class]);
    accountSettingsEntityName = NSStringFromClass([XMPPAccountSettingsCoreDataStorageObject class]);
    accountChatSessionEntityName = NSStringFromClass([XMPPAccountChatSessionCoreDataStorageObject class]);
    accountChatLogEntityName = NSStringFromClass([XMPPAccountChatLogCoreDataStorageObject class]);
}

- (void)dealloc
{
    [accountEntityName release];
    [accountSettingsEntityName release];
    [accountChatSessionEntityName release];
    [accountChatLogEntityName release];
    
    [super dealloc];
}

#pragma mark Configuration

- (NSString *)accountEntityName
{
	__block NSString *result = nil;
	
	dispatch_block_t block = ^{
		result = accountEntityName;
	};
	
	if (dispatch_get_current_queue() == storageQueue)
		block();
	else
		dispatch_sync(storageQueue, block);
	
	return result;
}

- (void)setAccountEntityName:(NSString *)newAccountEntityName
{
	dispatch_block_t block = ^{
		accountEntityName = newAccountEntityName;
	};
	
	if (dispatch_get_current_queue() == storageQueue)
		block();
	else
		dispatch_async(storageQueue, block);
}

- (NSString *)accountSettingsEntityName
{
	__block NSString *result = nil;
	
	dispatch_block_t block = ^{
		result = accountSettingsEntityName;
	};
	
	if (dispatch_get_current_queue() == storageQueue)
		block();
	else
		dispatch_sync(storageQueue, block);
	
	return result;
}

- (void)setAccountSettingsEntityName:(NSString *)newAccountSettingsEntityName
{
	dispatch_block_t block = ^{
		accountSettingsEntityName = newAccountSettingsEntityName;
	};
	
	if (dispatch_get_current_queue() == storageQueue)
		block();
	else
		dispatch_async(storageQueue, block);
}

- (NSString *)accountChatSessionEntityName
{
	__block NSString *result = nil;
	
	dispatch_block_t block = ^{
		result = accountChatSessionEntityName;
	};
	
	if (dispatch_get_current_queue() == storageQueue)
		block();
	else
		dispatch_sync(storageQueue, block);
	
	return result;
}

- (void)setAccountChatSessionEntityName:(NSString *)newAccountChatSessionEntityName
{
	dispatch_block_t block = ^{
		accountChatSessionEntityName = newAccountChatSessionEntityName;
	};
	
	if (dispatch_get_current_queue() == storageQueue)
		block();
	else
		dispatch_async(storageQueue, block);
}

- (NSString *)accountChatLogEntityName
{
	__block NSString *result = nil;
	
	dispatch_block_t block = ^{
		result = accountChatLogEntityName;
	};
	
	if (dispatch_get_current_queue() == storageQueue)
		block();
	else
		dispatch_sync(storageQueue, block);
	
	return result;
}

- (void)setAccountChatLogEntityName:(NSString *)newAccountChatLogEntityName
{
	dispatch_block_t block = ^{
		accountChatLogEntityName = newAccountChatLogEntityName;
	};
	
	if (dispatch_get_current_queue() == storageQueue)
		block();
	else
		dispatch_async(storageQueue, block);
}

#pragma mark - Overrides

- (void)didCreateManagedObjectContext
{
	XMPPLogTrace();
}

#pragma mark - Support method

- (void)insertMessage:(XMPPMessage *)message outgoing:(BOOL)isOutgoing stream:(XMPPStream *)xmppStream
{
    // Extract needed information
    XMPPJID *from = [message from];
    XMPPJID *to = [message to];
    NSString *messageBody = [[message elementForName:@"body"] stringValue];
    NSDate *messageDate = [NSDate date];
    
    if([message wasDelayed] == YES)
    {
        messageDate = [message delayedDeliveryDate];
    }
    
    if([message wasDelayedLegacy] == YES)
    {
        messageDate = [message delayedDeliveryDateLegacy];
    }
    
    NSString *accountStr = (isOutgoing ==  YES) ? [from bare] : [to bare];
    NSString *recipientStr = (isOutgoing ==  YES) ? [to bare] : [from bare];
    
    // get the the account
    XMPPAccountCoreDataStorageObject *account = [XMPPAccountCoreDataStorageObject getOrCreateAccountWithJid:accountStr inManagedObjectContext:self.managedObjectContext];
    
    // check if the chat session exists or not
    XMPPAccountChatSessionCoreDataStorageObject *session = [XMPPAccountChatSessionCoreDataStorageObject getOrCreateChatSessionWithRecipientJid:recipientStr account:account inManagedObjectContext:self.managedObjectContext];
    session.lastActiveDate = [NSDate date];
    session.latestMessage = messageBody;
    
    // add the message log to the session
    XMPPAccountChatLogCoreDataStorageObject *log = [XMPPAccountChatLogCoreDataStorageObject createChatLogWithChatSession:session inManagedObjectContext:self.managedObjectContext];
    log.addedDate = messageDate;
    log.body = messageBody;
    log.fromJidStr = [from bare];
    log.toJidStr = [to bare];
    log.readByRecipient = [NSNumber numberWithBool:NO];
    log.fromMe = [NSNumber numberWithBool:isOutgoing];
    
    NSString *messageId = [message attributeStringValueForName:@"id"];
    if(messageId)
    {
        log.messageId = messageId;
        // if it is from another chatter, and we are here, then the message is definitely delivered!
        // if this message is from us, then we set to NO initially
        log.delivered = [NSNumber numberWithBool:!isOutgoing];
    }
}

#pragma mark - Public API

- (NSEntityDescription *)accountEntity:(NSManagedObjectContext *)managedObjectContext
{
    return [NSEntityDescription entityForName:[self accountEntityName] inManagedObjectContext:managedObjectContext];
}

- (NSEntityDescription *)accountSettingsEntity:(NSManagedObjectContext *)managedObjectContext
{
	return [NSEntityDescription entityForName:[self accountSettingsEntityName] inManagedObjectContext:managedObjectContext];
}

- (NSEntityDescription *)accountChatSessionEntity:(NSManagedObjectContext *)managedObjectContext
{
	return [NSEntityDescription entityForName:[self accountChatSessionEntityName] inManagedObjectContext:managedObjectContext];
}

- (NSEntityDescription *)accountChatLogEntity:(NSManagedObjectContext *)managedObjectContext
{	
	return [NSEntityDescription entityForName:[self accountChatLogEntityName] inManagedObjectContext:managedObjectContext];
}

#pragma mark - XMPPAccountStorage Protocol

- (void)handleAuthenticateSuccessful:(XMPPStream *)xmppStream
{
    XMPPLogTrace();
	
	[self scheduleBlock:^{
        
        XMPPJID *jid = [xmppStream myJID];
		
		XMPPAccountCoreDataStorageObject *account = [XMPPAccountCoreDataStorageObject getOrCreateAccountWithJid:[jid bare] inManagedObjectContext:self.managedObjectContext];
        account.domain = [xmppStream hostName];
        account.lastSignInTime = [NSDate date];
        account.userId = jid.bare;
	}];
}

- (void)handleOutgoingMessage:(XMPPMessage *)message xmppStream:(XMPPStream *)xmppStream
{
	XMPPLogTrace();
	
	[self scheduleBlock:^{
		
		[self insertMessage:message outgoing:YES stream:xmppStream];
        
	}];
}

- (void)handleIncomingMessage:(XMPPMessage *)message xmppStream:(XMPPStream *)xmppStream
{
	XMPPLogTrace();
	
	[self scheduleBlock:^{
        
        [self insertMessage:message outgoing:NO stream:xmppStream];
        
	}];
}

- (void)handleMessageDeliveredNotificationWithMessageId:(NSString *)anId
{
    XMPPLogTrace();
	
	[self scheduleBlock:^{
        
        // set the deliver flag
        XMPPAccountChatLogCoreDataStorageObject *chatLog = [XMPPAccountChatLogCoreDataStorageObject getChatLogIfExistWithMessageId:anId inManagedObjectContext:self.managedObjectContext];
        
        if(chatLog) {
            chatLog.delivered = [NSNumber numberWithBool:YES];
        }
        
	}];
}

- (void)handleIncomingChatStatusMessage:(XMPPMessage *)message xmppStream:(XMPPStream *)xmppStream
{
    XMPPLogTrace();
	
	[self scheduleBlock:^{
        
        /*
         <message xmlns="jabber:client" id="kHcFE-41" to="75214@mobile01.com" from="2128809@mobile01.com/Smack">
            <x xmlns="jabber:x:event">
                <displayed />
                <id>20120402_75214_150647</id>
            </x>
         </message>
         <message xmlns="jabber:client" from="jtg2078@jabber.org/dad7b88ef2103698" to="jtg2078@gmail.com" type="chat">
            <x xmlns="jabber:x:event">
                <displayed/>
                <id>tinychatter_1334220541.362009</id>
            </x>
         </message>
         */
        NSString *type = [[message elementForName:@"displayed"] stringValue];
        NSString *iddd = [[message elementForName:@"id"] stringValue];
        
        NSXMLElement *x = [message elementForName:@"x" xmlns:@"jabber:x:event"];
        NSXMLElement *displayedElement = [x elementForName:@"displayed"];
        NSXMLElement *idElement = [x elementForName:@"id"];
        
        NSLog(@"type:%@ idd:%@", type, iddd);
        
        // check to see what type of chat status
        
        if(displayedElement && idElement)
        {
            NSString *messageId = [idElement stringValue];
            XMPPAccountChatLogCoreDataStorageObject *chatLog = [XMPPAccountChatLogCoreDataStorageObject getChatLogIfExistWithMessageId:messageId inManagedObjectContext:self.managedObjectContext];
            if(chatLog) {
                chatLog.readByRecipient = [NSNumber numberWithBool:YES];
            }
            
        }
	}];
}

@end
