//
//  ChatListViewController.m
//  TinyChatter
//
//  Created by jj on 12/4/3.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "ChatListViewController.h"
#import "XMPPManager.h"
#import "DDLog.h"
#import "ChatViewController.h"


// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface ChatListViewController ()
- (void)setupNotification;
- (void)setupListContent;
- (void)setupTableView;
- (void)configureCell:(UITableViewCell *)aCell atIndexPath:(NSIndexPath *)aIndexPath;
@end


@implementation ChatListViewController

#pragma mark - define

#define SIGNINVC_MESSAGE_SIGN_IN_SUCCESSFUL             @"signInVCSignInSuccessful"

#pragma mark - synthesize

@synthesize myTableView;
@synthesize managedObjectContext;
@synthesize fetchedResultsController;

#pragma mark - dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [myTableView release];
    [managedObjectContext release];
    [fetchedResultsController release];
    
    [super dealloc];
}

#pragma mark - init and setup

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"聊天室";
    }
    return self;
}

- (void)setupNotification
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    // we need to reload chat list the when there is a sign in event
    [center addObserver:self 
               selector:@selector(setupListContent)
                   name:SIGNINVC_MESSAGE_SIGN_IN_SUCCESSFUL 
                 object:nil];
}

- (void)setupListContent
{
    XMPPManager *manager = [XMPPManager sharedInstance];
    self.managedObjectContext = manager.managedObjectContext_account;
    
    // get the current user
    NSString *accountJidBare = [[XMPPManager sharedInstance] getCurrentAccountJidBare];
    
    // setup fetch request
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPAccountChatSessionCoreDataStorageObject" inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
    
    // setup predicate
    if(accountJidBare)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"accountJid == %@", accountJidBare];
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

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setupNotification];
    [self setupListContent];
    [self setupTableView];
}

- (void)viewDidUnload
{
    [self setMyTableView:nil];
    [self setManagedObjectContext:nil];
    [self setFetchedResultsController:nil];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ChatViewController *cvc = [[ChatViewController alloc] init];
    XMPPAccountChatSessionCoreDataStorageObject *chatSession = [[self fetchedResultsController] objectAtIndexPath:indexPath];
	cvc.chatSession = chatSession.sessionId;
    cvc.recipient = chatSession.recipientJid;
    
    cvc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:cvc animated:YES];
    [cvc release];
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
    static NSString *CellIdentifier = @"ChatViewCell";
    
    UITableViewCell *cell = [self.myTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    XMPPAccountChatSessionCoreDataStorageObject *chatSession = [[self fetchedResultsController] objectAtIndexPath:indexPath];
	cell.textLabel.text = chatSession.recipientJid;
    cell.detailTextLabel.text = chatSession.latestMessage;
    
    return cell;
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
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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

#pragma mark - support methods

- (void)configureCell:(UITableViewCell *)aCell atIndexPath:(NSIndexPath *)aIndexPath
{
    XMPPAccountChatSessionCoreDataStorageObject *chatSession = [[self fetchedResultsController] objectAtIndexPath:aIndexPath];
	aCell.textLabel.text = chatSession.recipientJid;
    aCell.detailTextLabel.text = chatSession.latestMessage;
    
    //NSLog(@"hoho the state: %@", chatSession.recipientStatus);
}

@end
