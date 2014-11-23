//
//  Account.m
//  Revelio
//
//  Created by Christine Yen on 11/9/14.
//  Copyright (c) 2014 ChristineYen. All rights reserved.
//

#import "Account.h"
#import "Conversation.h"

@implementation DataPoint
@end

@interface Account ()
@property (strong, nonatomic) NSArray *sortedConversations;
@end

@implementation Account

@dynamic handle;
@dynamic conversations;
@dynamic selfConversations;

@synthesize conversationsByCount = _conversationsByCount;
@synthesize conversationsByMessages = _conversationsByMessages;
@synthesize conversationsBySize = _conversationsBySize;

@synthesize sortedConversations = _sortedConversations;

#pragma mark - Properties
- (NSArray *)conversationsByCount {
    if (_conversationsByCount == nil) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self.conversations count]];
        [self.sortedConversations enumerateObjectsUsingBlock:^(Conversation *conv, NSUInteger idx, BOOL *stop) {
            DataPoint *point = [[DataPoint alloc] init];
            point.x = @([conv.timestamp timeIntervalSince1970]);
            point.y = @(idx + 1);

            [array addObject:point];
        }];
        _conversationsByCount = array;
    }
    return _conversationsByCount;
}

- (NSArray *)conversationsByMessages {
    if (_conversationsByMessages == nil) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self.conversations count]];
        __block NSInteger accum = 0;
        [self.sortedConversations enumerateObjectsUsingBlock:^(Conversation *conv, NSUInteger idx, BOOL *stop) {
            DataPoint *point = [[DataPoint alloc] init];
            point.x = @([conv.timestamp timeIntervalSince1970]);
            accum += [conv.msgsUser integerValue];
            accum += [conv.msgsBuddy integerValue];
            point.y = @(accum);

            [array addObject:point];
        }];
        _conversationsByMessages = array;
    }
    return _conversationsByMessages;
}

- (NSArray *)conversationsBySize {
    if (_conversationsBySize == nil) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self.conversations count]];
        __block CGFloat accum = 0;
        [self.sortedConversations enumerateObjectsUsingBlock:^(Conversation *conv, NSUInteger idx, BOOL *stop) {
            DataPoint *point = [[DataPoint alloc] init];
            point.x = @([conv.timestamp timeIntervalSince1970]);
            accum += [conv.size integerValue] / 1024.0;
            point.y = @(accum);

            [array addObject:point];
        }];
        _conversationsByMessages = array;
    }
    return _conversationsBySize;
}

- (NSArray *)sortedConversations {
    if (_sortedConversations == nil) {
        NSSortDescriptor *time = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
        _sortedConversations = [self.conversations sortedArrayUsingDescriptors:@[ time ]];
    }
    return _sortedConversations;
}

#pragma mark - Methods
- (Conversation *)lastConversation {
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
    return [[self.conversations sortedArrayUsingDescriptors:@[ sort ]] firstObject];
}

@end
