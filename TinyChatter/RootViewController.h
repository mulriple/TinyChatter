//
//  RootViewController.h
//  TinyChatter
//
//  Created by jj on 12/4/3.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SignInViewController;
@interface RootViewController : UITabBarController

@property (nonatomic, retain) SignInViewController *signInViewController;
@property (nonatomic, retain) UINavigationController *signInVCNav;

- (void)showSignInController;
- (void)hideSignInController;

@end
