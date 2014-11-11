//
//  CYRMainWindowController.m
//  Revelio
//
//  Created by Christine Yen on 11/21/13.
//  Copyright (c) 2013 ChristineYen. All rights reserved.
//

#import <CorePlot/CorePlot.h>

#import "CYRMainWindowController.h"

#import "CYRAppDelegate.h"
#import "Account.h"
#import "Conversation.h"

static NSString *const dataSourcePlot = @"Data Source Plot";

@interface CYRMainWindowController ()<NSTableViewDataSource, NSTableViewDelegate, CPTPlotDataSource>
@property (strong, nonatomic) NSArray *results;
@property (strong, nonatomic) NSArray *selectedBuddies;
@property (strong, nonatomic) NSArray *contentArray;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

- (void)_fetchBuddies:(void(^)(void))complete;
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

        // Add some initial data
        NSMutableArray *contentArray = [NSMutableArray arrayWithCapacity:4];
        for ( NSUInteger i = 0; i < 4; i++ ) {
            NSNumber *x = @(1.0 + i * 0.05);
            NSNumber *y = @(1.2 * arc4random() / (double)UINT32_MAX + 1.2);
            [contentArray addObject:@{ @"x": x,
                                       @"y": y }
             ];
        }
    self.contentArray = contentArray;
    
    
    
    CPTXYGraph *graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero xScaleType:CPTScaleTypeLinear yScaleType:CPTScaleTypeLinear];
    graph.title = @"hi graph";
    
    CPTScatterPlot *plot = [[CPTScatterPlot alloc] init];
    plot.identifier = dataSourcePlot;
    plot.dataSource = self;
    plot.interpolation = CPTScatterPlotInterpolationStepped;
    [graph addPlot:plot];
    
    // Put an area gradient under the plot above
    CPTColor *areaColor       = [CPTColor colorWithComponentRed:0.3 green:1.0 blue:0.3 alpha:0.1];
    CPTFill *areaGradientFill = [CPTFill fillWithColor:areaColor];
    plot.areaFill      = areaGradientFill;
    plot.areaBaseValue = CPTDecimalFromDouble(1);
    
//    CPTXYPlotSpace *space = (CPTXYPlotSpace *)graph.defaultPlotSpace;
//    [space scaleToFitPlots:@[plot]];
    
    self.graphView.hostedGraph = graph;

    [plot reloadData];

    [self _fetchBuddies:^{
        [self.tableView reloadData];
    }];
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
    Account *account = self.results[row];
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
    NSIndexSet *indexSet = [self.tableView selectedRowIndexes];
    NSMutableArray *users = [NSMutableArray arrayWithCapacity:[indexSet count]];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [users addObject:self.results[idx]];
    }];
    self.selectedBuddies = users;
    
    Account *account = [self.selectedBuddies firstObject];
    CPTXYPlotSpace *space = (CPTXYPlotSpace *)self.graphView.hostedGraph.defaultPlotSpace;
    space.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble([account.conversations count])];
//    NSDate *minX = [account.conversations valueForKeyPath:@"@min.timestamp"];
//    NSDate *maxX = [account.conversations valueForKeyPath:@"@max.timestamp"];
//    NSLog(@"minX: %f, maxX: %@", [minX timeIntervalSince1970], maxX);
//    space.xRange = [CPTPlotRange plotRangeWithLocation:[minX decimalValue] length:[maxX decimalValue]];
    
//    NSNumber *minY = [account.conversations valueForKeyPath:@"@min.size"];
//    NSNumber *maxY = [account.conversations valueForKeyPath:@"@max.size"];
//    space.yRange = [CPTPlotRange plotRangeWithLocation:[minY decimalValue] length:[maxY decimalValue]];
    
    [self.graphView.hostedGraph reloadData];
}

#pragma mark - CPTPlotDataSource
- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    // hm? we actually want a bunch of time series laid on top of each other.
    Account *account = [self.selectedBuddies firstObject];
    return [account.conversations count];
}

- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx {
    NSNumber *num;
    // the x-axis should be time and the y-axis should be the increasing count of conversations
    Account *account = [self.selectedBuddies firstObject];
    Conversation *conv = [account.conversations allObjects][idx];
    if (fieldEnum == CPTScatterPlotFieldX) {
//        num = @([conv.timestamp timeIntervalSince1970]);
        num = @(idx);
    } else {
        num = @([conv.size doubleValue] / 50000.0);
    }
    
    return num;
}

- (CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)idx {
    return nil;
}

#pragma mark - Private methods
- (void)_fetchBuddies:(void(^)(void))complete {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"handle != %@", @"cyenatwork"];
    request.predicate = predicate;
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"handle" ascending:YES];
    request.sortDescriptors = @[sort];
    
    CYRAppDelegate *delegate = [[NSApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.managedObjectContext;
    NSError *err;
    self.results = [context executeFetchRequest:request error:&err];
    if (!err) {
        complete();
    } else {
        NSLog(@"Nope! _fetchBuddies got error: %@", err);
    }
}

@end
