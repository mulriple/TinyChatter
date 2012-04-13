//
//  ChatViewController.h
//  TinyChatter
//
//  Created by jj on 12/4/3.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIInputToolbar.h"

// INACTIVE <--> ACTIVE <--> COMPOSING <--> PAUSED
typedef enum {
    ChatViewControllerUserInteractionStateInactive,
    ChatViewControllerUserInteractionStateActive,
    ChatViewControllerUserInteractionStateComposing,
    ChatViewControllerUserInteractionStatePaused,
    ChatViewControllerUserInteractionStateGone,
}ChatViewControllerUserInteractionState;


@interface ChatViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UIInputToolbarDelegate, UIExpandingTextViewDelegate> {
    BOOL userStateChanged;
}
@property (retain, nonatomic) IBOutlet UITableView *myTableView;
@property (retain, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (retain, nonatomic) UIInputToolbar *inputToolbar;
@property (assign, nonatomic) BOOL keyboardIsVisible;
@property (retain, nonatomic) NSString *recipient;
@property (retain, nonatomic) NSString *chatSession;
@property (assign, nonatomic) ChatViewControllerUserInteractionState userState;
@property (retain, nonatomic) NSDate *lastInputTime;
@property (retain, nonatomic) NSDate *lastActiveTime;
@property (retain, nonatomic) NSTimer *myTimer;
@end
