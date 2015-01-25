//
//  Account.m
//  Revelio
//
//  Created by Christine Yen on 11/9/14.
//  Copyright (c) 2014 ChristineYen. All rights reserved.
//

#import "Account.h"
#import "Conversation.h"

#import <CorePlot/CorePlot.h>

@interface Account ()
@property (strong, nonatomic) NSArray *sortedConversations;
- (NSArray *)_conversationsWithCalculation:(void(^)(Conversation *conv, NSMutableDictionary *point))setData;
- (NSNumber *)_timeOfDayFromComponents:(NSDateComponents *)components;
- (NSNumber *)_endOfDayTime;
- (NSDate *)_startOfDayFromComponents:(NSDateComponents *)components;
@end

@implementation Account

@dynamic handle;
@dynamic conversations;
@dynamic selfConversations;

@synthesize conversationsByCount = _conversationsByCount;
@synthesize conversationsByMessages = _conversationsByMessages;
@synthesize conversationsBySize = _conversationsBySize;
@synthesize conversationsBySkew = _conversationsBySkew;
@synthesize conversationsByTime = _conversationsByTime;

@synthesize sortedConversations = _sortedConversations;

#pragma mark - Properties
- (NSArray *)conversationsByCount {
    if (_conversationsByCount == nil) {
        __block NSInteger accum = 0;
        _conversationsByCount = [self _conversationsWithCalculation:^(Conversation *conv, NSMutableDictionary *point) {
            accum += 1;
            point[@(CPTScatterPlotFieldY)] = @(accum);
        }];
    }
    return _conversationsByCount;
}

- (NSArray *)conversationsByMessages {
    if (_conversationsByMessages == nil) {
        __block NSInteger accum = 0;
        _conversationsByMessages = [self _conversationsWithCalculation:^(Conversation *conv, NSMutableDictionary *point) {
            accum += [conv.msgsUser integerValue];
            accum += [conv.msgsBuddy integerValue];
            point[@(CPTScatterPlotFieldY)] = @(accum);
        }];
    }
    return _conversationsByMessages;
}

- (NSArray *)conversationsBySize {
    if (_conversationsBySize == nil) {
        __block CGFloat accum = 0;
        _conversationsBySize = [self _conversationsWithCalculation:^(Conversation *conv, NSMutableDictionary *point) {
            accum += [conv.size integerValue] / 1024.0;
            point[@(CPTScatterPlotFieldY)] = @(accum);
        }];
    }
    return _conversationsBySize;
}

- (NSArray *)conversationsBySkew {
    if (_conversationsBySkew == nil) {
        _conversationsBySkew = [self _conversationsWithCalculation:^(Conversation *conv, NSMutableDictionary *point) {
            NSInteger total = [conv.msgsUser integerValue] + [conv.msgsBuddy integerValue];
            point[@(CPTBarPlotFieldBarTip)] = @(([conv.msgsUser floatValue] - [conv.msgsBuddy floatValue]) / (float)total);
        }];
    }
    return _conversationsBySkew;
}

- (NSArray *)conversationsByTime {
    if (_conversationsByTime == nil) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self.sortedConversations count]]; // might expand!
        NSCalendar *cal = [NSCalendar currentCalendar];
        [self.sortedConversations enumerateObjectsUsingBlock:^(Conversation *conv, NSUInteger idx, BOOL *stop) {
            NSTimeZone *timeZone = [NSTimeZone timeZoneForSecondsFromGMT:[conv.tzOffset integerValue]];
            NSDateComponents *startComponents = [cal componentsInTimeZone:timeZone fromDate:conv.startTime];
            NSDateComponents *endComponents = [cal componentsInTimeZone:timeZone fromDate:conv.endTime];

            NSMutableDictionary *point = [NSMutableDictionary dictionary];
            if (startComponents.day == endComponents.day) {
                point[@(CPTBarPlotFieldBarLocation)] = @([conv.startTime timeIntervalSince1970]);
                // Start time, time of day
                point[@(CPTBarPlotFieldBarBase)] = [self _timeOfDayFromComponents:startComponents];
                // End time, time of day
                point[@(CPTBarPlotFieldBarTip)] = [self _timeOfDayFromComponents:endComponents];
                [array addObject:point];
                return;
            }

            // Across days!
            if (endComponents.day - startComponents.day > 1) {
                NSLog(@"AAAAAAA difference of %lu days", endComponents.day - startComponents.day);
                return;
            }

            point[@(CPTBarPlotFieldBarLocation)] = @([conv.startTime timeIntervalSince1970]);
            point[@(CPTBarPlotFieldBarBase)] = [self _timeOfDayFromComponents:startComponents];
            point[@(CPTBarPlotFieldBarTip)] = [self _endOfDayTime];
            [array addObject:point];

            NSMutableDictionary *secondPoint = [NSMutableDictionary dictionary];
            secondPoint[@(CPTBarPlotFieldBarTip)] = [self _timeOfDayFromComponents:endComponents];
            // Set endComponents to beginning of day
            endComponents.hour = endComponents.minute = endComponents.second = 0;
            secondPoint[@(CPTBarPlotFieldBarLocation)] = @([[endComponents date] timeIntervalSince1970]);
            secondPoint[@(CPTBarPlotFieldBarBase)] = [self _timeOfDayFromComponents:endComponents];
            [array addObject:secondPoint];
        }];

        _conversationsByTime = array;
    }
    return _conversationsByTime;
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
- (NSArray *)_conversationsWithCalculation:(void(^)(Conversation *conv, NSMutableDictionary *point))setData {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self.sortedConversations count]];
    [self.sortedConversations enumerateObjectsUsingBlock:^(Conversation *conv, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *point = [NSMutableDictionary dictionary];
        point[@(CPTScatterPlotFieldX)] = @([conv.timestamp timeIntervalSince1970]);
        setData(conv, point);

        [array addObject:point];
    }];
    return array;
}

- (NSNumber *)_timeOfDayFromComponents:(NSDateComponents *)components {
    return @(components.hour * 3600 + components.minute * 60 + components.second);
}

- (NSNumber *)_endOfDayTime {
    return @(23*3600 + 59*60 + 59);
}

- (NSDate *)_startOfDayFromComponents:(NSDateComponents *)components {
    components.hour = 0;
    components.minute = 0;
    components.second = 0;
    return [components date];
}

@end
