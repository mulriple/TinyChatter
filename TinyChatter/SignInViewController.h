//
//  SignInViewController.h
//  TinyChatter
//
//  Created by jj on 12/4/5.
//  Copyright (c) 2012年jtg2078@hotmail.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SignInViewController : UIViewController

@property (retain, nonatomic) IBOutlet UIScrollView *signInScrollView;
@property (retain, nonatomic) IBOutlet UIView *signInView;
@property (retain, nonatomic) IBOutlet UITextField *userIdField;
@property (retain, nonatomic) IBOutlet UITextField *userPasswordField;
@property (retain, nonatomic) IBOutlet UIButton *signInButton;
@property (retain, nonatomic) IBOutlet UIButton *registerButton;
@property (retain, nonatomic) IBOutlet UILabel *statusLabel;

- (IBAction)signInButtonPressed:(id)sender;
- (IBAction)registerButtonPressed:(id)sender;
- (void)dismissKeyboard;



@end
