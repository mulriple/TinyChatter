//
//  SignInViewController.h
//  TinyChatter
//
//  Created by jj on 12/4/5.
//  Copyright (c) 2012年jtg2078@hotmail.com. All rights reserved.
//

#import "SignInViewController.h"
//#import "RegisterViewController.h"
#import "XMPPManager.h"
#import "SVProgressHUD.h"
#import "AppDelegate.h"


@implementation SignInViewController

#pragma mark - define

#define REGISTER_COMPLETED_NOTIFICATION         @"com.cactuarsoft.tinychatter.registerCompleted"
#define BUTTON_TEXT_FOR_SIGN_IN                 @"登入"
#define BUTTON_TEXT_FOR_SIGN_OUT                @"登出"
#define SIGNINVC_MESSAGE_SIGN_IN_SUCCESSFUL     @"signInVCSignInSuccessful"


#pragma mark - synthesize

@synthesize registerButton;
@synthesize signInScrollView;
@synthesize signInView;
@synthesize userIdField;
@synthesize userPasswordField;
@synthesize signInButton;
@synthesize statusLabel;

#pragma mark - dealloc

- (void)dealloc {
    [signInScrollView release];
    [signInView release];
    [userIdField release];
    [userPasswordField release];
    [signInButton release];
    [statusLabel release];
    [registerButton release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

#pragma mark - memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"登入";
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self 
               selector:@selector(handleRegisterCompletedEvent:) 
                   name:REGISTER_COMPLETED_NOTIFICATION 
                 object:nil];
}

- (void)viewDidUnload
{
    [self setSignInScrollView:nil];
    [self setSignInView:nil];
    [self setUserIdField:nil];
    [self setUserPasswordField:nil];
    [self setSignInButton:nil];
    [self setStatusLabel:nil];
    [self setRegisterButton:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSString *savedUserId = [[XMPPManager sharedInstance] getUserId];
    if(savedUserId && [savedUserId length])
    {
        self.userIdField.text = savedUserId;
    }
    
    NSString *savedPwd = [[XMPPManager sharedInstance] getUserPassword];
    if(savedPwd && [savedPwd length])
    {
        self.userPasswordField.text = savedPwd;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - user interaction

- (IBAction)signInButtonPressed:(id)sender 
{
    [self dismissKeyboard];
    
    XMPPManager *manager = [XMPPManager sharedInstance];
    
    NSString *buttonText = [self.signInButton titleForState:UIControlStateNormal];
    
    if([buttonText isEqualToString:BUTTON_TEXT_FOR_SIGN_IN])
    {
        [manager signInWithJID:self.userIdField.text pwd:self.userPasswordField.text begin:^ {
            [SVProgressHUD showWithStatus:@"登入中..."];
            self.signInButton.enabled = NO;
        } success:^(NSString *message) {
            [SVProgressHUD dismissWithSuccess:message afterDelay:3.0f];
            [self.signInButton setTitle:BUTTON_TEXT_FOR_SIGN_OUT forState:UIControlStateNormal];
            [manager setUserId:self.userIdField.text password:self.userPasswordField.text];
            [[NSNotificationCenter defaultCenter] postNotificationName:SIGNINVC_MESSAGE_SIGN_IN_SUCCESSFUL object:nil];
        } failure:^(FailureType errorType, NSError *error, NSString *message) {
            [SVProgressHUD dismissWithError:message afterDelay:5.0f];
        } end:^{
            self.signInButton.enabled = YES;
        }];  
    }
    
    if([buttonText isEqualToString:BUTTON_TEXT_FOR_SIGN_OUT])
    {
        [SVProgressHUD showSuccessWithStatus:@"已登出" duration:2.5f];
        [manager disconnect];
        [self.signInButton setTitle:BUTTON_TEXT_FOR_SIGN_IN forState:UIControlStateNormal];
    }
}

- (IBAction)registerButtonPressed:(id)sender 
{/*
    RegisterViewController *cavc = [[RegisterViewController alloc] init];
    cavc.mode = RVCModeSignInRegisterWorkFlow;
    [self.navigationController pushViewController:cavc animated:YES];
    [cavc release];*/
}

#pragma mark - support methods

- (void)dismissKeyboard
{
    [self.view endEditing:TRUE];
}

- (void)handleRegisterCompletedEvent:(NSNotification *)notif
{
    NSString *registeredUserId = (NSString *)[notif object];
    
    if([registeredUserId length])
        self.userIdField.text = registeredUserId;
}

@end
