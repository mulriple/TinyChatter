//
//  XMPPManager.h
//  TinyChatter
//
//  Created by jj on 12/4/5.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"

typedef enum {
    FailureTypeError,
    FailureTypeConnectionError,
} FailureType;

@interface XMPPManager : NSObject <XMPPStreamDelegate, XMPPRosterDelegate>
{
    XMPPStream                          * xmppStream;
    XMPPReconnect                       * xmppReconnect;
    XMPPRoster                          * xmppRoster;
    XMPPRosterCoreDataStorage           * xmppRosterStorage;
    XMPPvCardCoreDataStorage            * xmppvCardStorage;
    XMPPvCardTempModule                 * xmppvCardTempModule;
    XMPPvCardAvatarModule               * xmppvCardAvatarModule;
    XMPPCapabilities                    * xmppCapabilities;
    XMPPCapabilitiesCoreDataStorage     * xmppCapabilitiesStorage;
    XMPPChatHistory                     * xmppChatHistory;
    XMPPChatHistoryCoreDataStorage      * xmppChatHistoryStorage;
    XMPPAccount                         * xmppAccount;
    XMPPAccountCoreDataStorage          * xmppAccountStorage;
    
    NSString                            * passord;
    XMPPJID                             * myJid;
    
    BOOL allowSelfSignedCertificates;
    BOOL allowSSLHostNameMismatch;
    
    BOOL isXmppConnected;
    
    NSManagedObjectContext *managedObjectContext_roster;
    NSManagedObjectContext *managedObjectContext_capabilities;
    NSManagedObjectContext *managedObjectContext_chatHistory;
    NSManagedObjectContext *managedObjectContext_account;
}

@property (nonatomic, retain, readonly) XMPPStream                          * xmppStream;
@property (nonatomic, retain, readonly) XMPPReconnect                       * xmppReconnect;
@property (nonatomic, retain, readonly) XMPPRoster                          * xmppRoster;
@property (nonatomic, retain, readonly) XMPPRosterCoreDataStorage           * xmppRosterStorage;
@property (nonatomic, retain, readonly) XMPPvCardCoreDataStorage            * xmppvCardStorage;
@property (nonatomic, retain, readonly) XMPPvCardTempModule                 * xmppvCardTempModule;
@property (nonatomic, retain, readonly) XMPPvCardAvatarModule               * xmppvCardAvatarModule;
@property (nonatomic, retain, readonly) XMPPCapabilities                    * xmppCapabilities;
@property (nonatomic, retain, readonly) XMPPCapabilitiesCoreDataStorage     * xmppCapabilitiesStorage;
@property (nonatomic, retain, readonly) XMPPChatHistory                     * xmppChatHistory;
@property (nonatomic, retain, readonly) XMPPChatHistoryCoreDataStorage      * xmppChatHistoryStorage;
@property (nonatomic, retain, readonly) XMPPAccount                         * xmppAccount;
@property (nonatomic, retain, readonly) XMPPAccountCoreDataStorage          * xmppAccountStorage;
@property (nonatomic, copy, readwrite) XMPPJID                              * myJid;

@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext_roster;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext_capabilities;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext_chatHistory;
@property (nonatomic, retain) NSManagedObjectContext * managedObjectContext_account;

+ (XMPPManager *)sharedInstance;

- (void)goOnline;
- (void)goOffline;

- (NSString *)getUserPassword;
- (NSString *)getUserId;
- (NSString *)getCurrentAccountJidBare;
- (void)setUserId:(NSString *)anId password:(NSString *)aPw;
- (void)clearSavedPassword;

- (UIImage *)avatarPhotoForJID:(XMPPJID *)aJid;

- (void)signInWithJID:(NSString *)myJID 
                   pwd:(NSString *)myPwd 
                 begin:(void (^)())begin 
               success:(void (^)(NSString *message))success 
               failure:(void (^)(FailureType errorType, NSError *error, NSString *message))failure 
                   end:(void (^)())end;
- (void)disconnect;

- (void)sendChatMessage:(NSString *)aMessage toJid:(NSString *)aJid;
- (void)sendMessageReadNotificationForMessageWithId:anId toJid:(NSString *)aJid;
- (void)sendChatStatus:(XMPPAccountChatStatus)aStatus to:(NSString *)toJid;

@end
