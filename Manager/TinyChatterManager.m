//
//  TinyChatter.m
//  TinyChatter
//
//  Created by jj on 12/4/6.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "TinyChatterManager.h"
#import "XMPPManager.h"


static TinyChatterManager *singletonManager = nil;

@implementation TinyChatterManager

#pragma mark - define

#define MANAGER_NOTIFICATION_AUTO_SIGN_IN_BEGIN         @"autoSignInBegin"
#define MANAGER_NOTIFICATION_AUTO_SIGN_IN_SUCCESSFUL    @"autoSignInSuccessful"
#define MANAGER_NOTIFICATION_AUTO_SIGN_IN_FAILED        @"autoSignInFailed"
#define MANAGER_NOTIFICATION_AUTO_SIGN_IN_END           @"autoSignInEnd"

#pragma mark - synthesize

#pragma mark - dealloc

#pragma mark - init and setup

#pragma mark - main methods

/**
 * This method is only useful during the app starts up, because the xmpp
 * framework will take care of reconnect/authenticate once the app has
 * established connection/logged into the server
 *
 * 1. use the user id and pw saved in the user-default
 * 2. attempt to sign in using the id and pw combination from above
 *      - successful: 
 *              do nothing
 *      - failure:
 *              broadcast a message autoSignInFailed
 **/
- (void)startAutoSignInService
{
    XMPPManager *manager = [XMPPManager sharedInstance];
    
    NSString *savedJID = [manager getUserId];
    NSString *savedPwd = [manager getUserPassword];
    
    [manager signInWithJID:savedJID pwd:savedPwd begin:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MANAGER_NOTIFICATION_AUTO_SIGN_IN_BEGIN object:nil];
    } success:^(NSString *message) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MANAGER_NOTIFICATION_AUTO_SIGN_IN_SUCCESSFUL object:message];
    } failure:^(FailureType errorType, NSError *error, NSString *message) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MANAGER_NOTIFICATION_AUTO_SIGN_IN_FAILED object:message];
    } end:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MANAGER_NOTIFICATION_AUTO_SIGN_IN_END object:nil];
    }];
}

- (void)autoAcceptFriendRequest
{
    
}

#pragma mark - singleton implementation code

+ (TinyChatterManager *)sharedInstance {
    
    static dispatch_once_t pred;
    static TinyChatterManager *manager;
    
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
