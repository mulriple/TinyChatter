//
//  XMPPChatHistoryCoreDataStorage.h
//  TinyChatter
//
//  Created by ling tsu hsuan on 4/7/12.
//  Copyright (c) 2012 jtg2078@hotmail.com. All rights reserved.
//

#import "XMPPCoreDataStorage.h"
#import "XMPP.h"
#import "XMPPChatHistory.h"
#import "XMPPMessageCoreDataStorageObject.h"
#import "XMPPChatHistoryCoreDataStorageObject.h"


@interface XMPPChatHistoryCoreDataStorage : XMPPCoreDataStorage <XMPPChatHistoryStorage>

/**
 * Convenience method to get an instance with the default database name.
 * 
 * IMPORTANT:
 * You are NOT required to use the sharedInstance.
 * 
 * Um... I am not so sure, since I just copied this comment from MUC's code files
 **/
+ (XMPPChatHistoryCoreDataStorage *)sharedInstance;

/* Inherited from XMPPCoreDataStorage
 * Please see the XMPPCoreDataStorage header file for extensive documentation.
 
 - (id)initWithDatabaseFilename:(NSString *)databaseFileName;
 - (id)initWithInMemoryStore;
 
 @property (readonly) NSString *databaseFileName;
 
 @property (readwrite) NSUInteger saveThreshold;
 
 @property (readonly) NSManagedObjectModel *managedObjectModel;
 @property (readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
 
 */

/**
 * You may choose to extend this class, and/or the message classes for customized functionality.
 * These properties allow for such customization.
 * 
 * You must set your desired entity names, if different from default, before you begin using the storage class.
 **/
@property (strong, readwrite) NSString * messageEntityName;

/**
 * It is likely you don't want the message history to persist forever.
 * Doing so would allow the database to grow infinitely large over time.
 * 
 * The maxMessageAge property provides a way to specify how old a message can get
 * before it should get deleted from the database.
 * 
 * The deleteInterval specifies how often to sweep for old messages.
 * Since deleting is an expensive operation (disk io) it is done on a fixed interval.
 * 
 * You can optionally disable the maxMessageAge by setting it to zero (or a negative value).
 * If you disable the maxMessageAge then old messages are not deleted.
 * 
 * You can optionally disable the deleteInterval by setting it to zero (or a negative value).
 * 
 * The default maxAge is 7 days.
 * The default deleteInterval is 5 minutes.
 **/
@property (assign, readwrite) NSTimeInterval maxMessageAge;
@property (assign, readwrite) NSTimeInterval deleteInterval;

/**
 * You may optionally prevent old message deletion for particular entity.
 **/
- (void)pauseOldMessageDeletionForEntity:(XMPPJID *)entityJID;
- (void)resumeOldMessageDeletionForEntity:(XMPPJID *)entityJID;

/**
 * Convenience method to get the message entity description.
 * 
 * @see messageEntityName
 **/
- (NSEntityDescription *)messageEntity:(NSManagedObjectContext *)moc;

@end