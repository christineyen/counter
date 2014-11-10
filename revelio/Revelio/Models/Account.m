//
//  Account.m
//  Revelio
//
//  Created by Christine Yen on 11/9/14.
//  Copyright (c) 2014 ChristineYen. All rights reserved.
//

#import "Account.h"
#import "Conversation.h"


@implementation Account

@dynamic handle;
@dynamic conversations;
@dynamic selfConversations;

- (Conversation *)lastConversation {
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
    return [[self.conversations sortedArrayUsingDescriptors:@[ sort ]] firstObject];
}

@end
