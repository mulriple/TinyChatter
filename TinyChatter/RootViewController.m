//
//  RootViewController.m
//  TinyChatter
//
//  Created by jj on 12/4/3.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "RootViewController.h"
#import "SignInViewController.h"
#import "AddFriendViewController.h"
#import "FriendListViewController.h"
#import "ChatListViewController.h"
#import "SettingViewController.h"
#import "ChatViewController.h"

#import "TinyChatterManager.h"
#import "SVProgressHUD.h"
#import "FTAnimation.h"


@interface RootViewController ()
- (void)setupTabBarControllers;
- (void)setupNotification;
- (void)setupManager;
- (void)showSignInController;
- (void)hideSignInController;
@end

@implementation RootViewController

#pragma mark - define

#define NAME_OF_SELF                                    @"RootViewController"
#define SIGN_IN_VC_ANIMATION_TRANSITION_TIME            0.4f
#define HUD_MESSAGE_DURATION                            2.0

#define MANAGER_NOTIFICATION_AUTO_SIGN_IN_BEGIN         @"autoSignInBegin"
#define MANAGER_NOTIFICATION_AUTO_SIGN_IN_SUCCESSFUL    @"autoSignInSuccessful"
#define MANAGER_NOTIFICATION_AUTO_SIGN_IN_FAILED        @"autoSignInFailed"
#define MANAGER_NOTIFICATION_AUTO_SIGN_IN_END           @"autoSignInEnd"
#define SIGNINVC_MESSAGE_SIGN_IN_SUCCESSFUL             @"signInVCSignInSuccessful"

#pragma mark - synthesize

@synthesize signInViewController;
@synthesize signInVCNav;

#pragma mark - dealloc

- (void)dealloc
{
    [signInViewController release];
    [signInVCNav release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark - init and setup

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setupTabBarControllers
{
    NSMutableArray *array = [NSMutableArray array];
    UIBarStyle barStyle = UIBarStyleBlackOpaque;
    
    AddFriendViewController *afvc = [[[AddFriendViewController alloc] init] autorelease];
    UINavigationController *nav_afvc = [[[UINavigationController alloc] initWithRootViewController:afvc] autorelease];
    nav_afvc.navigationBar.barStyle = barStyle;
    [array addObject:nav_afvc];
    
    FriendListViewController *flvc = [[[FriendListViewController alloc] init] autorelease];
    UINavigationController *nav_flvc = [[[UINavigationController alloc] initWithRootViewController:flvc] autorelease];
    nav_flvc.navigationBar.barStyle = barStyle;
    [array addObject:nav_flvc];
    
    /*
    ChatListViewController *clvc = [[[ChatListViewController alloc] init] autorelease];
    UINavigationController *nav_clvc = [[[UINavigationController alloc] initWithRootViewController:clvc] autorelease];
    nav_clvc.navigationBar.barStyle = barStyle;
    [array addObject:nav_clvc];
     */
    
    ChatViewController *cvc = [[[ChatViewController alloc] init] autorelease];
    UINavigationController *nav_cvc = [[[UINavigationController alloc] initWithRootViewController:cvc] autorelease];
    nav_cvc.navigationBar.barStyle = barStyle;
    [array addObject:nav_cvc];
    
    SettingViewController *svc = [[[SettingViewController alloc] init] autorelease];
    UINavigationController *nav_svc = [[[UINavigationController alloc] initWithRootViewController:svc] autorelease];
    nav_svc.navigationBar.barStyle = barStyle;
    [array addObject:nav_svc];
    
    self.viewControllers = array;
}

- (void)setupNotification
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self 
               selector:@selector(autoSignInActionBegin) 
                   name:MANAGER_NOTIFICATION_AUTO_SIGN_IN_BEGIN 
                 object:nil];
    
    [center addObserver:self 
               selector:@selector(autoSignInActionSuccessful:) 
                   name:MANAGER_NOTIFICATION_AUTO_SIGN_IN_SUCCESSFUL 
                 object:nil];
    
    [center addObserver:self 
               selector:@selector(autoSignInActionFailure:) 
                   name:MANAGER_NOTIFICATION_AUTO_SIGN_IN_FAILED 
                 object:nil];
    
    [center addObserver:self 
               selector:@selector(autoSignInActionEnd) 
                   name:MANAGER_NOTIFICATION_AUTO_SIGN_IN_END 
                 object:nil];
    
    [center addObserver:self 
               selector:@selector(hideSignInController) 
                   name:SIGNINVC_MESSAGE_SIGN_IN_SUCCESSFUL 
                 object:nil];
}

- (void)setupManager
{
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[TinyChatterManager sharedInstance] startAutoSignInService];
        //[SVProgressHUD showWithStatus:@"wtf"];
    });
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self setupTabBarControllers];
    [self setupNotification];
    [self setupManager];
    //
}

- (void)viewDidUnload
{
    [self setSignInViewController:nil];
    [self setSignInVCNav:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - sign in support method

- (void)autoSignInActionBegin
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"登入中...", NAME_OF_SELF)];
                      
}

- (void)autoSignInActionSuccessful:(NSString *)message
{
    [SVProgressHUD dismissWithSuccess:NSLocalizedString(@"登入成功", NAME_OF_SELF)
                           afterDelay:HUD_MESSAGE_DURATION];
}

- (void)autoSignInActionFailure:(NSString *)message
{
    [SVProgressHUD dismissWithError:NSLocalizedString(@"登入失敗", NAME_OF_SELF) 
                         afterDelay:HUD_MESSAGE_DURATION];
    
    [self showSignInController];
}

- (void)autoSignInActionEnd
{
    //[SVProgressHUD dismiss];
}

#pragma mark - sign in view controller related

- (void)showSignInController
{
    if(self.signInViewController == nil)
    {
        signInViewController = [[SignInViewController alloc] init];
        // adjusting the coordinate to deal with status bar
        signInVCNav = [[UINavigationController alloc] initWithRootViewController:signInViewController];
        signInVCNav.navigationBar.barStyle = UIBarStyleBlackOpaque;
        [self.view addSubview:signInVCNav.view];
    }
    
    [self.signInVCNav.view fadeIn:SIGN_IN_VC_ANIMATION_TRANSITION_TIME delegate:nil];
}

- (void)hideSignInController
{
    [self.signInVCNav.view fadeOut:SIGN_IN_VC_ANIMATION_TRANSITION_TIME delegate:nil];
}

@end
