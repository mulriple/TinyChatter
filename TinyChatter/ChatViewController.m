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
- (void)setupController;
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
- (void)configureCell:(ChatViewCell *)aCell atIndexPath:(NSIndexPath *)anIndexPath;
- (void)scrollToTableBottom;

- (void)userActivityStatusFigureOutator;
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
#define CHAT_RECIPIENT_CHAT_STATUS_RECEIVED             @"chatRecipientChatStatusReceived"

#pragma mark - synthesize

@synthesize myTableView;
@synthesize managedObjectContext;
@synthesize fetchedResultsController;
@synthesize inputToolbar;
@synthesize keyboardIsVisible;
@synthesize recipient;
@synthesize chatSession;
@synthesize userState;
@synthesize lastInputTime;
@synthesize lastActiveTime;
@synthesize myTimer;

#pragma mark - dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [myTableView release];
    [managedObjectContext release];
    [fetchedResultsController release];
    [inputToolbar release];
    [recipient release];
    [chatSession release];
    [lastInputTime release];
    [lastActiveTime release];
    [myTimer invalidate];
    [myTimer release];
    
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

- (void)setupController
{
    self.userState = ChatViewControllerUserInteractionStateActive;
    userStateChanged = YES;
}

- (void)setupNotification
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    // we need remove ourself if there is a sign in event took place
    [center addObserver:self 
               selector:@selector(removeSelf)
                   name:SIGNINVC_MESSAGE_SIGN_IN_SUCCESSFUL 
                 object:nil];
    
    [center addObserver:self 
               selector:@selector(viewWillBeActive)
                   name:UIApplicationWillEnterForegroundNotification 
                 object:nil];
    
    [center addObserver:self 
               selector:@selector(viewWillBeInactive)
                   name:UIApplicationWillResignActiveNotification 
                 object:nil];
    
    [center addObserver:self 
               selector:@selector(updateRecipientChatStatusIfNeeded:)
                   name:CHAT_RECIPIENT_CHAT_STATUS_RECEIVED 
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
    inputToolbar.textViewDelegate = self;
    inputToolbar.textView.placeholder = NSLocalizedString(@"type your message here...", SELF_NAME);
    inputToolbar.textView.maximumNumberOfLines = 13;
    
    [self.view addSubview:inputToolbar];
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setupController];
    [self setupNotification];
    [self setupListContent];
    [self setupTableView];
    [self setupInputToolbar];
    [self scrollToTableBottom];
    [self startTimer];
}

- (void)viewDidUnload
{
    [self setMyTableView:nil];
    [self setManagedObjectContext:nil];
    [self setFetchedResultsController:nil];
    [self setInputToolbar:nil];
    [self setRecipient:nil];
    [self setLastInputTime:nil];
    [self setLastActiveTime:nil];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self subscribeForKeyboardEvents];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // so the user has left the chat
    [[XMPPManager sharedInstance] sendChatStatus:XMPPAccountChatStatusGone to:self.recipient];
    [self unsubscribeFromKeyboardEvents];
    
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillBeActive
{
    self.userState = ChatViewControllerUserInteractionStateActive;
    [self startTimer];
}

- (void)viewWillBeInactive
{
    self.userState = ChatViewControllerUserInteractionStateInactive;
    [self stopTimer];
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
        
        [self configureCell:cell atIndexPath:indexPath];
        
        return cell;
    }
    else
    {
        ChatViewCell *cell = (ChatViewCell*)[self.myTableView dequeueReusableCellWithIdentifier:CellIdentifierLeft];
        if(cell == nil) {
            cell = [[[ChatViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifierLeft mode:CellViewCellModeLeftAlign] autorelease];
        }
        
        [self configureCell:cell atIndexPath:indexPath];
        
        return cell;
    }
}

- (void)configureCell:(ChatViewCell *)aCell atIndexPath:(NSIndexPath *)anIndexPath
{
    XMPPAccountChatLogCoreDataStorageObject *message = [[self fetchedResultsController] objectAtIndexPath:anIndexPath];
    NSLog(@"%@", message.body);
    
    [aCell setMessage:message.body];
    aCell.deliverLabel.hidden = ![message.delivered boolValue];
    
    if([message.fromMe boolValue] == NO)
    {
        if([message.readByRecipient boolValue] == NO && message.messageId)
        {
            [[XMPPManager sharedInstance] sendMessageReadNotificationForMessageWithId:message.messageId toJid:message.fromJidStr];
            message.readByRecipient = [NSNumber numberWithBool:YES];
        }
        aCell.readLabel.hidden = NO;
    }
    else
    {
        aCell.readLabel.hidden = ![message.readByRecipient boolValue];
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
            [self configureCell:(ChatViewCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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
    } completion:^(BOOL finished) {
        // scroll the table view to last poition
        [self scrollToTableBottom];
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
    
    self.userState = ChatViewControllerUserInteractionStateActive;
    self.lastActiveTime = [NSDate date];
}

#pragma mark - UIExpandingTextViewDelegate

- (void)expandingTextViewDidBeginEditing:(UIExpandingTextView *)expandingTextView
{
    self.userState = ChatViewControllerUserInteractionStateComposing;
    self.lastActiveTime = [NSDate date];
}

- (void)expandingTextViewDidEndEditing:(UIExpandingTextView *)expandingTextView
{
    self.userState = ChatViewControllerUserInteractionStateActive;
    self.lastActiveTime = [NSDate date];
}

- (void)expandingTextViewDidChange:(UIExpandingTextView *)expandingTextView
{
    if([expandingTextView.text length])
    {
        // this is for throttling
        // (not to self: investigate other ways to achieve the same result)
        if(self.userState != ChatViewControllerUserInteractionStateComposing)
            self.userState = ChatViewControllerUserInteractionStateComposing;
    }
    else
        self.userState = ChatViewControllerUserInteractionStateActive;
    
    self.lastInputTime = [NSDate date];
    self.lastActiveTime = [NSDate date];
}

#pragma mark - timer related code

- (void)startTimer
{
    if(self.myTimer) {
        [self stopTimer];
    }
    
    // hmm... the event will not fire if UI thread are handling touches(i.e. keystrokes from users)
    // i hope it does not matter
    self.myTimer = [NSTimer timerWithTimeInterval:1.0 
                                           target:self 
                                         selector:@selector(userActivityStatusFigureOutator) 
                                         userInfo:nil 
                                          repeats:YES];
    
    [[NSRunLoop mainRunLoop] addTimer:self.myTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopTimer
{
    [[self myTimer] invalidate];
    [self setMyTimer:nil];
}

#pragma mark - user input state related code

- (void)setUserState:(ChatViewControllerUserInteractionState)aUserState {
    userStateChanged = (self.userState != aUserState);
    userState = aUserState;
}

/*
 <active/>	User is actively participating in the chat session.	User accepts an initial content message, sends a content message, gives focus to the chat session interface (perhaps after being inactive), or is otherwise paying attention to the conversation.
 <inactive/>	User has not been actively participating in the chat session.	User has not interacted with the chat session interface for an intermediate period of time (e.g., 2 minutes).
 <gone/>	User has effectively ended their participation in the chat session.	User has not interacted with the chat session interface, system, or device for a relatively long period of time (e.g., 10 minutes).
 <composing/>	User is composing a message.	User is actively interacting with a message input interface specific to this chat session (e.g., by typing in the input area of a chat window).
 <paused/>	User had been composing but now has stopped.	User was composing but has not interacted with the message input interface for a short period of time (e.g., 30 seconds).
 
 INACTIVE <--> ACTIVE <--> COMPOSING <--> PAUSED
 */

#define USER_STATE_INACTIVE_TIME_TRIGGER        120
#define USER_STATE_GONE_TIME_TRIGGER            600
#define USER_STATE_PAUSED_TIME_TRIGGER          2

// lol
// using the var userStateChanged for decision making is too fragile
// i need to use some other ways to handle this
- (void)userActivityStatusFigureOutator {
    
    XMPPManager *manager = [XMPPManager sharedInstance];
    
    // one check at a time, if the state already changed prior
    // this method is called, then we do check on next time
    if(userStateChanged == NO)
    {
        // check inactive
        // can only come from state of paused or active
        if(self.userState == ChatViewControllerUserInteractionStatePaused ||
           self.userState == ChatViewControllerUserInteractionStateActive)
        {
            NSTimeInterval  elapsedTime = [[NSDate date] timeIntervalSinceDate:self.lastActiveTime];
            
            if(elapsedTime > USER_STATE_INACTIVE_TIME_TRIGGER)
                self.userState = ChatViewControllerUserInteractionStateInactive;
        }
        // check paused
        // can only come from state of composing
        else if (self.userState == ChatViewControllerUserInteractionStateComposing)
        {
            NSTimeInterval  elapsedTime = [[NSDate date] timeIntervalSinceDate:self.lastInputTime];
            
            if(elapsedTime > USER_STATE_PAUSED_TIME_TRIGGER)
                self.userState = ChatViewControllerUserInteractionStatePaused;
        }
        
        // state gone
        // lets make it the rule that can only be trigger if the app goes to background or the chat view is popped
    }
    
    if(userStateChanged == YES)
    {
        // this is like a state machine
        switch (self.userState) {
            case ChatViewControllerUserInteractionStateInactive:
            {
                [manager sendChatStatus:XMPPAccountChatStatusInActive to:self.recipient];
            }
                break;
            case ChatViewControllerUserInteractionStateActive:
            {
                [manager sendChatStatus:XMPPAccountChatStatusActive to:self.recipient];
            }
                break;
            case ChatViewControllerUserInteractionStateComposing:
            {
                [manager sendChatStatus:XMPPAccountChatStatusComposing to:self.recipient];
            }
                break;
            case ChatViewControllerUserInteractionStatePaused:
            {
                [manager sendChatStatus:XMPPAccountChatStatusPaused to:self.recipient];
            }
                break;
            case ChatViewControllerUserInteractionStateGone:
            {
                [manager sendChatStatus:XMPPAccountChatStatusGone to:self.recipient];
            }
                break;
                
            default:
                break;
        }
        
        userStateChanged = NO;
    }
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
    self.userState = ChatViewControllerUserInteractionStateGone;
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)scrollToTableBottom
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetchedResultsController] sections] lastObject];
    NSIndexPath *lastCellIndex = [NSIndexPath indexPathForRow:[sectionInfo numberOfObjects] - 1 inSection:[[[self fetchedResultsController] sections] count] - 1];
    
    if([lastCellIndex row] >= 0 && [lastCellIndex section] >= 0)
        [self scrollToIndexPath:lastCellIndex];
}

- (void)updateRecipientChatStatusIfNeeded:(NSNotification *)notif
{
    NSArray *statusInfo = [notif object];
    if(statusInfo && [statusInfo count] == 2) {
        NSString *from = [statusInfo objectAtIndex:0];
        NSString *status = [statusInfo objectAtIndex:1];
        
        if([from isEqualToString:self.recipient])
            self.navigationItem.title = status;
    }
}

@end
