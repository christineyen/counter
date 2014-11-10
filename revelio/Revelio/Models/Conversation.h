//
//  Conversation.h
//  Revelio
//
//  Created by Christine Yen on 11/21/13.
//  Copyright (c) 2013 ChristineYen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Account;

@interface Conversation : NSManagedObject

@property (nonatomic, retain) NSNumber * size;
@property (nonatomic, retain) NSNumber * initiated;
@property (nonatomic, retain) NSNumber * msgsUser;
@property (nonatomic, retain) NSNumber * msgsBuddy;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) Account *user;
@property (nonatomic, retain) Account *buddy;

@end
