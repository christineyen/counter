//
//  Account.h
//  Revelio
//
//  Created by Christine Yen on 11/9/14.
//  Copyright (c) 2014 ChristineYen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation;

@interface Account : NSManagedObject

@property (nonatomic, retain) NSString * handle;
@property (nonatomic, retain) NSSet *conversations;
@property (nonatomic, retain) NSSet *selfConversations;

- (Conversation *)lastConversation;

@end

@interface Account (CoreDataGeneratedAccessors)

- (void)addConversationsObject:(Conversation *)value;
- (void)removeConversationsObject:(Conversation *)value;
- (void)addConversations:(NSSet *)values;
- (void)removeConversations:(NSSet *)values;

- (void)addSelfConversationsObject:(Conversation *)value;
- (void)removeSelfConversationsObject:(Conversation *)value;
- (void)addSelfConversations:(NSSet *)values;
- (void)removeSelfConversations:(NSSet *)values;

@end
