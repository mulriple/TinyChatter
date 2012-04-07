//
//  XMPPChatHistoryCoreDataStorageObject.m
//  TinyChatter
//
//  Created by ling tsu hsuan on 4/8/12.
//  Copyright (c) 2012 jtg2078@hotmail.com. All rights reserved.
//

#import "XMPPChatHistoryCoreDataStorageObject.h"

@interface XMPPChatHistoryCoreDataStorageObject()
@property(nonatomic, retain) XMPPJID    * primitiveJid;
@property(nonatomic, retain) NSString   * primitiveJidStr;
@end


@implementation XMPPChatHistoryCoreDataStorageObject

@dynamic displayName;
@dynamic jid;
@dynamic jidStr;
@dynamic nickname;
@dynamic streamBareJidStr;
@dynamic lastMessage;
@dynamic lastMessageTime;
@dynamic lastMessageIsFromMe;

@dynamic primitiveJid;
@dynamic primitiveJidStr;
@dynamic isLastMessageFromMe;


#pragma mark Transient jid

- (XMPPJID *)jid
{
	// Create and cache on demand
	
	[self willAccessValueForKey:@"jid"];
	XMPPJID *tmp = self.primitiveJid;
	[self didAccessValueForKey:@"jid"];
	
	if (tmp == nil)
	{
		NSString *jidStr = self.jidStr;
		if (jidStr)
		{
			tmp = [XMPPJID jidWithString:jidStr];
			self.primitiveJid = tmp;
		}
	}
	
	return tmp;
}

- (void)setJid:(XMPPJID *)jid
{
	[self willChangeValueForKey:@"jid"];
	[self willChangeValueForKey:@"jidStr"];
	
	self.primitiveJid = jid;
	self.primitiveJidStr = [jid full];
	
	[self didChangeValueForKey:@"jid"];
	[self didChangeValueForKey:@"jidStr"];
}

- (void)setJidStr:(NSString *)jidStr
{
	[self willChangeValueForKey:@"jid"];
	[self willChangeValueForKey:@"jidStr"];
	
	self.primitiveJid = [XMPPJID jidWithString:jidStr];
	self.primitiveJidStr = jidStr;
	
	[self didChangeValueForKey:@"jid"];
	[self didChangeValueForKey:@"jidStr"];
}

#pragma mark Scalar

- (BOOL)isLastMessageFromMe
{
	return [[self lastMessageIsFromMe] boolValue];
}

- (void)setIsLastMessageFromMe:(BOOL)value
{
	self.lastMessageIsFromMe = [NSNumber numberWithBool:value];
}

@end