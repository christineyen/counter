//
//  CYRMainWindowController.m
//  Revelio
//
//  Created by Christine Yen on 11/21/13.
//  Copyright (c) 2013 ChristineYen. All rights reserved.
//

#import "CYRMainWindowController.h"

#import "CYRAppDelegate.h"
#import "Account.h"
#import "Conversation.h"

@interface CYRMainWindowController ()<NSTableViewDataSource, NSTableViewDelegate>
@property (strong, nonatomic) NSArray *results;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation CYRMainWindowController

- (id)initWithWindow:(NSWindow *)window {
    if (self = [super initWithWindow:window]) {
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"handle != %@", @"cyenatwork"];
    request.predicate = predicate;
    
    CYRAppDelegate *delegate = [[NSApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.managedObjectContext;
    NSError *err;
    self.results = [context executeFetchRequest:request error:&err];
    if (err) {
        NSLog(@"nope! %@", err);
    }
    [self.tableView reloadData];
}

#pragma mark - Properties
- (NSDateFormatter *)dateFormatter {
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    }
    return _dateFormatter;
}

#pragma mark - NSTableViewDataSource methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.results count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    Account *account = [self.results objectAtIndex:row];
    if ([tableColumn.identifier isEqualToString:@"snColumn"]) {
        return account.handle;
    } else if ([tableColumn.identifier isEqualToString:@"numColumn"]) {
        return @([account.conversations count]);
    }
    // lastColumn
    return [self.dateFormatter stringFromDate:[[account lastConversation] timestamp]];
}

#pragma mark - NSTableViewDelegate methods
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSLog(@"clicked %@", [notification userInfo]);
}

@end
