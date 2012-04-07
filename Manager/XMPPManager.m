//
//  XMPPManager.m
//  TinyChatter
//
//  Created by jj on 12/4/5.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "XMPPManager.h"
#import "DDLog.h"
#import "DDTTYLogger.h"


static XMPPManager *singletonManager = nil;

#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

typedef void (^XMPPManagerSignInOperationBeginBlock)();
typedef void (^XMPPManagerSignInOperationSuccessBlock)(NSString *message);
typedef void (^XMPPManagerSignInOperationFailureBlock)(FailureType errorType, NSError *error, NSString *message);
typedef void (^XMPPManagerSignInOperationEndBlock)();

@interface XMPPManager()
@property (readwrite, nonatomic, copy) XMPPManagerSignInOperationBeginBlock     signInBegin;
@property (readwrite, nonatomic, copy) XMPPManagerSignInOperationSuccessBlock   signInSuccess;
@property (readwrite, nonatomic, copy) XMPPManagerSignInOperationFailureBlock   signInFailure;
@property (readwrite, nonatomic, copy) XMPPManagerSignInOperationEndBlock       signInEnd;
- (void)setup;
- (void)setupStream;
- (void)setupMisc;
- (void)teardownStream;
@end

@implementation XMPPManager

#pragma mark - define

#define USERDEFAULT_KEY_USER_ID         @"userId"
#define USERDEFAULT_KEY_USER_PW         @"userPw"

#pragma mark - synthesize

@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize xmppRoster;
@synthesize xmppRosterStorage;
@synthesize xmppvCardStorage;
@synthesize xmppvCardTempModule;
@synthesize xmppvCardAvatarModule;
@synthesize xmppCapabilities;
@synthesize xmppCapabilitiesStorage;
@synthesize xmppChatHistory;
@synthesize xmppChatHistoryStorage;
@synthesize managedObjectContext_roster;
@synthesize managedObjectContext_capabilities;
@synthesize managedObjectContext_chatHistory;

@synthesize signInBegin;
@synthesize signInSuccess;
@synthesize signInFailure;
@synthesize signInEnd;

#pragma mark - dealloc and clean up

- (void)dealloc
{
    [self teardownStream];
    [xmppStream release];
    [xmppReconnect release];
    [xmppRoster release];
    [xmppRosterStorage release];
    [xmppvCardStorage release];
    [xmppvCardTempModule release];
    [xmppvCardAvatarModule release];
    [xmppCapabilities release];
    [xmppCapabilitiesStorage release];
    [xmppChatHistory release];
    [xmppChatHistoryStorage release];
    [managedObjectContext_roster release];
    [managedObjectContext_capabilities release];
    [managedObjectContext_chatHistory release];
    [passord release];
    
    [signInBegin release];
    [signInSuccess release];
    [signInFailure release];
    [signInEnd release];
    
    [super dealloc];
}

- (void)teardownStream
{
    [xmppStream removeDelegate:self];
    [xmppRoster removeDelegate:self];
    
    [xmppReconnect          deactivate];
    [xmppRoster             deactivate];
    [xmppvCardTempModule    deactivate];
    [xmppvCardAvatarModule  deactivate];
    [xmppCapabilities       deactivate];
    
    [xmppStream disconnect];
}

#pragma mark - init and setup

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
        [self setupMisc];
    }
    return self;
}

- (void)setup
{
    // configuring logging network
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // setup the XMPP stream
    [self setupStream];
}

- (void)setupStream
{
    NSAssert(xmppStream == nil, @"Method setupStream invoked multiple times");
    
    xmppStream = [[XMPPStream alloc] init];
    
#if !TARGET_IPHONE_SIMULATOR
    {
        xmppStream.enableBackgroundingOnSocket = YES;
    }
#endif
    
    xmppReconnect =[[XMPPReconnect alloc] init];
    
    xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
    xmppRoster.autoFetchRoster = YES;
    xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    
    xmppvCardStorage = [[XMPPvCardCoreDataStorage sharedInstance] retain];
    xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:xmppvCardStorage];
    xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
    
    xmppCapabilitiesStorage = [[XMPPCapabilitiesCoreDataStorage sharedInstance] retain];
    xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
    xmppCapabilities.autoFetchHashedCapabilities = YES;
    xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    
    xmppChatHistoryStorage = [[XMPPChatHistoryCoreDataStorage sharedInstance] retain];
    xmppChatHistory = [[XMPPChatHistory alloc] initWithChatHistoryStorage:xmppChatHistoryStorage];
    
    // activate xmpp modules
    [xmppReconnect          activate:xmppStream];
    [xmppRoster             activate:xmppStream];
    [xmppvCardTempModule    activate:xmppStream];
    [xmppvCardAvatarModule  activate:xmppStream];
    [xmppCapabilities       activate:xmppStream];
    [xmppChatHistory        activate:xmppStream];
    
    // setup delegate
    [xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // follow the example code
    allowSelfSignedCertificates = NO;
    allowSSLHostNameMismatch = NO;
}

- (void)setupMisc
{
    self.managedObjectContext_roster = [xmppRosterStorage mainThreadManagedObjectContext]; 
    self.managedObjectContext_capabilities = [xmppCapabilitiesStorage mainThreadManagedObjectContext];
    self.managedObjectContext_chatHistory = [xmppChatHistoryStorage mainThreadManagedObjectContext];
}

#pragma mark - action methods

- (void)goOnline
{
    XMPPPresence *presence = [XMPPPresence presence];
    [[self xmppStream] sendElement:presence];
}

- (void)goOffline
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [[self xmppStream] sendElement:presence];
}

- (void)signInWithJID:(NSString *)myJID 
                   pwd:(NSString *)myPwd 
                 begin:(void (^)())begin 
               success:(void (^)(NSString *message))success 
               failure:(void (^)(FailureType errorType, NSError *error, NSString *message))failure 
                   end:(void (^)())end
{
    self.signInBegin = begin;
    self.signInSuccess = success;
    self.signInFailure = failure;
    self.signInEnd = end;
    
    //dispatch_async(dispatch_get_main_queue(), ^{ [self signInBegin](); });
    [self signInBegin]();
    
    [xmppStream setMyJID:[XMPPJID jidWithString:myJID]];
    passord = myPwd;
    
    if([xmppStream isDisconnected] == YES)
    {
        NSError *error = nil;
        if([xmppStream connect:&error] == NO)
        {
            [self signInFailure](FailureTypeConnectionError, error, [error description]);
            [self signInEnd]();
        }
    }
}

- (void)disconnect
{
    [self goOffline];
    [xmppStream disconnect];
}

#pragma mark - support methods

- (NSString *)getUserPassword
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:USERDEFAULT_KEY_USER_PW];
}

- (NSString *)getUserId
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:USERDEFAULT_KEY_USER_ID];
}

- (void)setUserId:(NSString *)anId password:(NSString *)aPw
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:anId forKey:USERDEFAULT_KEY_USER_ID];
    [userDefault setObject:aPw forKey:USERDEFAULT_KEY_USER_PW];
    [userDefault synchronize];
}

#pragma mark - XMPPStreamDelegate

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    if(allowSelfSignedCertificates)
        [settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
    
    if(allowSSLHostNameMismatch)
        [settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
    else
    {
        NSString *expectedCertName = nil;
        NSString *serverDomain = xmppStream.hostName;
        NSString *virtualDomain = [xmppStream.myJID domain];
        
        if([serverDomain isEqualToString:@"talk.google.com"])
        {
            expectedCertName = [virtualDomain isEqualToString:@"gmail.com"] ? virtualDomain: serverDomain;
        }
        else if(serverDomain == nil)
            expectedCertName = virtualDomain;
        else
            expectedCertName = serverDomain;
        
        if(expectedCertName)
            [settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
    }
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    isXmppConnected = YES;
    
    NSError *error = nil;
    if([[self xmppStream] authenticateWithPassword:passord error:&error] == NO)
    {
        DDLogError(@"Error authenticating: %@", error);
        [self signInFailure](FailureTypeConnectionError, error, [error description]);
        [self signInEnd]();
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self signInSuccess](@"Signed In!");
    [self signInEnd]();
    
    [self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self signInFailure](FailureTypeError, nil, @"Invalid user id and/or password");
    [self signInEnd]();
    
    // since authenticate failed, just sever the connection
    [xmppStream disconnect];
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [iq elementID]);
    return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    if([message isChatMessageWithBody])
    {
        XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[message from] 
                                                                 xmppStream:xmppStream 
                                                       managedObjectContext:self.managedObjectContext_roster];
        
        DDLogCInfo(@"[%@]: %@", [user displayName], [[message elementForName:@"body"] stringValue]);
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(DDXMLElement *)error
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    if(isXmppConnected == NO)
    {
        DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
        [self signInFailure](FailureTypeConnectionError, error, [error description]);
        [self signInEnd]();
    }
}

#pragma mark - XMPPRosterDelegate

/**
 * Sent when a presence subscription request is received.
 * That is, another user has added you to their roster,
 * and is requesting permission to receive presence broadcasts that you send.
 * 
 * The entire presence packet is provided for proper extensibility.
 * You can use [presence from] to get the JID of the user who sent the request.
 * 
 * The methods acceptPresenceSubscriptionRequestFrom: and rejectPresenceSubscriptionRequestFrom: can
 * be used to respond to the request.
 **/
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[presence from] 
                                                             xmppStream:xmppStream 
                                                   managedObjectContext:self.managedObjectContext_roster];
    NSString *displayName = [user displayName];
    NSString *jidStrBare = [presence fromStr];
    NSString *body = nil;
    
    if([displayName isEqualToString:jidStrBare] == NO)
    {
        body = [NSString stringWithFormat:@"Buddy request from %@ <%@>", displayName, jidStrBare];
    }
    else
    {
        body = [NSString stringWithFormat:@"Buddy request from %@", displayName];
    }
}
                
#pragma mark - singleton implementation code

+ (XMPPManager *)sharedInstance {
    
    static dispatch_once_t pred;
    static XMPPManager *manager;
    
    dispatch_once(&pred, ^{
        manager = [[self alloc] init];
    });
    return manager;
}
+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (singletonManager == nil) {
            singletonManager = [super allocWithZone:zone];
            return singletonManager;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
- (id)retain {
    return self;
}
- (unsigned)retainCount {
    return UINT_MAX;  // denotes an object that cannot be released
}
- (oneway void)release {
    //do nothing
}
- (id)autorelease {
    return self;
}

@end
