//
//  XMPPAccountSettingsCoreDataStorageObject.h
//  TinyChatter
//
//  Created by jj on 12/4/9.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class XMPPAccountCoreDataStorageObject;

@interface XMPPAccountSettingsCoreDataStorageObject : NSManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * enablePush;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSNumber * rememberPwd;
@property (nonatomic, retain) NSNumber * rememberUserId;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) XMPPAccountCoreDataStorageObject *account;

@end
