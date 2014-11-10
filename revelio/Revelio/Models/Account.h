//
//  Account.h
//  Revelio
//
//  Created by Christine Yen on 11/21/13.
//  Copyright (c) 2013 ChristineYen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation;

@interface Account : NSManagedObject

@property (nonatomic, retain) NSString * handle;
@property (nonatomic, retain) Conversation *conversations;

@end
