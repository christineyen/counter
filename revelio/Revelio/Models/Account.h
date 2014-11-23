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

@property (strong, nonatomic) NSString * handle;
@property (strong, nonatomic) NSSet *conversations;
@property (strong, nonatomic) NSSet *selfConversations;

@property (strong, nonatomic) NSArray *conversationsByCount;
@property (strong, nonatomic) NSArray *conversationsByMessages;
@property (strong, nonatomic) NSArray *conversationsBySize;

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

@interface DataPoint : NSObject
@property (strong, nonatomic) NSNumber *x;
@property (strong, nonatomic) NSNumber *y;
@end