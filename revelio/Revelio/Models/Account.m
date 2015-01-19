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
- (NSArray *)_conversationsWithYCalculation:(void(^)(Conversation *conv, DataPoint *point))setY;
@end

@implementation Account

@dynamic handle;
@dynamic conversations;
@dynamic selfConversations;

@synthesize conversationsByCount = _conversationsByCount;
@synthesize conversationsByMessages = _conversationsByMessages;
@synthesize conversationsBySize = _conversationsBySize;
@synthesize conversationsBySkew = _conversationsBySkew;

@synthesize sortedConversations = _sortedConversations;

#pragma mark - Properties
- (NSArray *)conversationsByCount {
    if (_conversationsByCount == nil) {
        __block NSInteger accum = 0;
        _conversationsByCount = [self _conversationsWithYCalculation:^(Conversation *conv, DataPoint *point) {
            accum += 1;
            point.y = @(accum);
        }];
    }
    return _conversationsByCount;
}

- (NSArray *)conversationsByMessages {
    if (_conversationsByMessages == nil) {
        __block NSInteger accum = 0;
        _conversationsByMessages = [self _conversationsWithYCalculation:^(Conversation *conv, DataPoint *point) {
            accum += [conv.msgsUser integerValue];
            accum += [conv.msgsBuddy integerValue];
            point.y = @(accum);
        }];
    }
    return _conversationsByMessages;
}

- (NSArray *)conversationsBySize {
    if (_conversationsBySize == nil) {
        __block CGFloat accum = 0;
        _conversationsBySize = [self _conversationsWithYCalculation:^(Conversation *conv, DataPoint *point) {
            accum += [conv.size integerValue] / 1024.0;
            point.y = @(accum);
        }];
    }
    return _conversationsBySize;
}

- (NSArray *)conversationsBySkew {
    if (_conversationsBySkew == nil) {
        _conversationsBySkew = [self _conversationsWithYCalculation:^(Conversation *conv, DataPoint *point) {
            NSInteger total = [conv.msgsUser integerValue] + [conv.msgsBuddy integerValue];
            point.y = @(([conv.msgsUser floatValue] - [conv.msgsBuddy floatValue]) / (float)total);
        }];
    }
    return _conversationsBySkew;
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

#pragma mark - Private Methods
- (NSArray *)_conversationsWithYCalculation:(void(^)(Conversation *conv, DataPoint *point))setY {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self.sortedConversations count]];
    [self.sortedConversations enumerateObjectsUsingBlock:^(Conversation *conv, NSUInteger idx, BOOL *stop) {
        DataPoint *point = [[DataPoint alloc] init];
        point.x = @([conv.timestamp timeIntervalSince1970]);
        setY(conv, point);

        [array addObject:point];
    }];
    return array;
}

@end
