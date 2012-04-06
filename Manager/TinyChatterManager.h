//
//  TinyChatter.h
//  TinyChatter
//
//  Created by jj on 12/4/6.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TinyChatterManager : NSObject

- (void)startAutoSignInService;

+ (TinyChatterManager *)sharedInstance;

@end
