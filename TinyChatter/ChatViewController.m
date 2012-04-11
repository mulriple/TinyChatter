//
//  ChatViewController.m
//  TinyChatter
//
//  Created by jj on 12/4/3.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "ChatViewController.h"
#import "XMPPManager.h"
#import "DDLog.h"
#import "ChatViewCell.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface ChatViewController ()
- (void)setupNotification;
- (void)setupListContent;
- (void)setupTableView;
- (void)setupInputToolbar;
- (void)hideTabBar;
- (void)showTabBar;
- (void)subscribeForKeyboardEvents;
- (void)unsubscribeFromKeyboardEvents;
- (void)scrollToIndexPath:(NSIndexPath *)aIndexPath;
- (void)removeSelf;
@end

@implementation ChatViewController

#pragma mark - define

#define SELF_NAME @"ChatViewController"

#define TABBAR_NOTIFICATION_SHOW_OR_HIDE_TAB_BAR                @"showOrHideTabBar"
#define TABBAR_NOTIFICATION_SHOW_OR_HIDE_TAB_BAR_HIDE           @"hideTabBar"
#define TABBAR_NOTIFICATION_SHOW_OR_HIDE_TAB_BAR_SHOW           @"showTabBar"

#define kStatusBarHeight 20
#define kDefaultToolbarHeight 40
#define kKeyboardHeightPortrait 216
#define kKeyboardHeightLandscape 140

#define MESSAGE_LABEL_WIDTH         240
#define MESSAGE_LABEL_MIN_HEIGHT    39

#define SIGNINVC_MESSAGE_SIGN_IN_SUCCESSFUL             @"signInVCSignInSuccessful"

#pragma mark - synthesize

@synthesize myTableView;
@synthesize managedObjectContext;
@synthesize fetchedResultsController;
@synthesize inputToolbar;
@synthesize keyboardIsVisible;
@synthesize recipient;
@synthesize chatSession;

#pragma mark - dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [myTableView release];
    [managedObjectContext release];
    [fetchedResultsController release];
    [inputToolbar release];
    [recipient release];
    [chatSession release];
    
    [super dealloc];
}

#pragma mark - init and setup

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"聊天";
    }
    return self;
}

- (void)setupNotification
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    // we need remove ourself if there is a sign in event took place
    [center addObserver:self 
               selector:@selector(removeSelf)
                   name:SIGNINVC_MESSAGE_SIGN_IN_SUCCESSFUL 
                 object:nil];
}

- (void)setupListContent
{
    XMPPManager *manager = [XMPPManager sharedInstance];
    self.managedObjectContext = manager.managedObjectContext_account;
    
    // setup fetch request
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init]; 
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPAccountChatLogCoreDataStorageObject" inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
    
    // setup nspredicate
    if(self.chatSession)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sessionId == %@", self.chatSession];
        [fetchRequest setPredicate:predicate];
    }
	
	// setup sorting
	NSSortDescriptor *sort1 = [[[NSSortDescriptor alloc] initWithKey:@"addedDate" ascending:YES] autorelease];
	[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sort1, nil]];
	[fetchRequest setFetchBatchSize:10];
	
	// setup fetched result controller
	NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
																				 managedObjectContext:self.managedObjectContext 
																				   sectionNameKeyPath:nil 
																							cacheName:nil];
	controller.delegate = self;
	self.fetchedResultsController = controller;
	[fetchRequest release];
	[controller release];
	
	
	NSError *error;
	if (![self.fetchedResultsController performFetch:&error]) {
		// Update to handle the error appropriately.
		DDLogError(@"Error performing fetch: %@", error);
	}
	else {
		// load the table
		[self.myTableView reloadData];
	}
}

- (void)setupTableView
{
    self.myTableView.sectionIndexMinimumDisplayRowCount = NSIntegerMax;
}

- (void)setupInputToolbar
{
    self.keyboardIsVisible = NO;
    
    CGRect viewFrame = self.view.frame;
    CGRect toolbarFrame = CGRectMake(0, viewFrame.size.height - kDefaultToolbarHeight, viewFrame.size.width, kDefaultToolbarHeight);
    inputToolbar = [[UIInputToolbar alloc] initWithFrame:toolbarFrame];
    inputToolbar.delegate = self;
    inputToolbar.textView.placeholder = NSLocalizedString(@"type your message here...", SELF_NAME);
    inputToolbar.textView.maximumNumberOfLines = 13;
    
    [self.view addSubview:inputToolbar];
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setupNotification];
    [self setupListContent];
    [self setupTableView];
    [self setupInputToolbar];
}

- (void)viewDidUnload
{
    [self setMyTableView:nil];
    [self setManagedObjectContext:nil];
    [self setFetchedResultsController:nil];
    [self setInputToolbar:nil];
    [self setRecipient:nil];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self hideTabBar];
    [self subscribeForKeyboardEvents];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //[self showTabBar];
    [self unsubscribeFromKeyboardEvents];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPAccountChatLogCoreDataStorageObject *message = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    CGFloat height = [message.body sizeWithFont:[UIFont boldSystemFontOfSize:13] constrainedToSize:CGSizeMake(MESSAGE_LABEL_WIDTH, 1000)].height + 10;
    
    return MAX(44, height);
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [[self fetchedResultsController] sections];
	
	if (section < [sections count])
	{
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
		return sectionInfo.numberOfObjects;
	}
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifierLeft = @"ChatViewCellLeft";
    static NSString *CellIdentifierRight = @"ChatViewCellRight";
    
    XMPPAccountChatLogCoreDataStorageObject *message = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    
    if([message.fromMe boolValue] == YES)
    {
        ChatViewCell *cell = (ChatViewCell*)[self.myTableView dequeueReusableCellWithIdentifier:CellIdentifierRight];
        if(cell == nil) {
            cell = [[[ChatViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifierRight mode:CellViewCellModeRightAlign] autorelease];
        }
        
        [cell setMessage:message.body];
        
        return cell;
    }
    else
    {
        ChatViewCell *cell = (ChatViewCell*)[self.myTableView dequeueReusableCellWithIdentifier:CellIdentifierLeft];
        if(cell == nil) {
            cell = [[[ChatViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifierLeft mode:CellViewCellModeLeftAlign] autorelease];
        }
        
        [cell setMessage:message.body];
        
        return cell;
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller 
{
    [self.myTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type 
{
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.myTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                            withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.myTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                            withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath 
{
    
    UITableView *tableView = self.myTableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [self performSelector:@selector(scrollToIndexPath:) withObject:newIndexPath afterDelay:0.3];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            //[self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
    [self.myTableView endUpdates];
}

#pragma mark - input views and keyboard

- (void)subscribeForKeyboardEvents
{
    /* Listen for keyboard */
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)unsubscribeFromKeyboardEvents
{
    /* No longer listen for keyboard */
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification 
{
    /* Move the toolbar to above the keyboard */
    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame = self.inputToolbar.frame;
        frame.origin.y = self.view.frame.size.height - frame.size.height - kKeyboardHeightPortrait;
        self.inputToolbar.frame = frame;
        CGRect frame2 = self.myTableView.frame;
        frame2.size.height = 376 - kKeyboardHeightPortrait;
        self.myTableView.frame = frame2;
    }];
    
    keyboardIsVisible = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification 
{
    /* Move the toolbar back to bottom of the screen */
    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame = self.inputToolbar.frame;
        frame.origin.y = self.view.frame.size.height - frame.size.height;
        self.inputToolbar.frame = frame;
        CGRect frame2 = self.myTableView.frame;
        frame2.size.height = 376;
        self.myTableView.frame = frame2;
    }];
    
    keyboardIsVisible = NO;
}

-(void)inputButtonPressed:(NSString *)inputText
{
    /* Called when toolbar button is pressed */
    NSLog(@"Pressed button with text: '%@'", inputText);
    XMPPManager *manager = [XMPPManager sharedInstance];
    [manager sendChatMessage:inputText toJid:self.recipient];
}

#pragma mark - support methods

- (void)hideTabBar
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:TABBAR_NOTIFICATION_SHOW_OR_HIDE_TAB_BAR 
                          object:TABBAR_NOTIFICATION_SHOW_OR_HIDE_TAB_BAR_HIDE];
}

- (void)showTabBar
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:TABBAR_NOTIFICATION_SHOW_OR_HIDE_TAB_BAR 
                          object:TABBAR_NOTIFICATION_SHOW_OR_HIDE_TAB_BAR_SHOW];
}

- (void)scrollToIndexPath:(NSIndexPath *)aIndexPath
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.myTableView scrollToRowAtIndexPath:aIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)removeSelf
{
    
}

@end
