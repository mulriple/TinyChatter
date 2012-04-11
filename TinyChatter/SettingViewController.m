//
//  SettingViewController.m
//  TinyChatter
//
//  Created by jj on 12/4/3.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "SettingViewController.h"
#import "XMPPManager.h"

@interface SettingViewController()
- (void)setupNavigationBarButtons;
- (void)SignOut;
@end

@implementation SettingViewController

#pragma mark - define

#define USER_ACTION_SIGN_OUT                            @"userActionSignOut"

#pragma mark - synthesize

@synthesize myTableView;

#pragma mark - dealloc

- (void)dealloc
{
    [myTableView release];
    [super dealloc];
}

#pragma mark - init and setup

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"設定";
    }
    return self;
}

- (void)setupNavigationBarButtons
{
    // setup navigation bar buttons
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    [self setupNavigationBarButtons];
    
    // fking
    // http://stackoverflow.com/questions/1557856/black-corners-on-uitableview-group-style
    [self.myTableView setBackgroundColor:[UIColor clearColor]];
    [self.myTableView setOpaque:NO];
}

- (void)viewDidUnload
{
    [self setMyTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    cell.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"cpattern.png"]];
    cell.contentView.backgroundColor=[UIColor clearColor];
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text=@"登出";
            break;
        case 1:
            cell.textLabel.text=@"修改帳號資料";
            break;
        case 2:
            cell.textLabel.text=@"忘記密碼";
            break;
            
        default:
            break;
    }
    
    cell.textLabel.textColor=[UIColor darkGrayColor];
    cell.textLabel.backgroundColor=[UIColor clearColor];
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row==0) {
        [self SignOut];
    }
}

#pragma mark - user interaction

- (void)SignOut
{
    [[XMPPManager sharedInstance] disconnect];
    [[NSNotificationCenter defaultCenter] postNotificationName:USER_ACTION_SIGN_OUT object:nil];
    
    // remove saved pw
    XMPPManager *manager = [XMPPManager sharedInstance];
    [manager clearSavedPassword];
}

@end
