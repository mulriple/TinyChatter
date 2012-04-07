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

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface ChatViewController ()
- (void)setupListContent;
- (void)setupTableView;
@end



@implementation ChatViewController
#pragma mark - define

#pragma mark - synthesize

@synthesize myTableView;
@synthesize managedObjectContext;
@synthesize fetchedResultsController;

#pragma mark - dealloc

- (void)dealloc {
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
        self.title = @"聊天";
    }
    return self;
}

- (void)setupListContent
{
    XMPPManager *manager = [XMPPManager sharedInstance];
    self.managedObjectContext = manager.managedObjectContext_chatHistory;
    
    // setup fetch request
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageCoreDataStorageObject" inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
	
	// setup sorting
	NSSortDescriptor *sort1 = [[[NSSortDescriptor alloc] initWithKey:@"localTimestamp" ascending:YES] autorelease];
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

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
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
    
    XMPPMessageCoreDataStorageObject *message = [[self fetchedResultsController] objectAtIndexPath:indexPath];
	cell.textLabel.text = message.body;
    
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
@end
