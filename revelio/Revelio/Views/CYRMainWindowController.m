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

@interface CYRMainWindowController ()<NSTableViewDataSource, NSTableViewDelegate, CPTPlotDataSource, CPTPlotSpaceDelegate>
@property (strong, nonatomic) NSArray *results;
@property (strong, nonatomic) NSArray *selectedBuddies;

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
    
    CPTXYGraph *graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero]; //xScaleType:CPTScaleTypeLinear yScaleType:CPTScaleTypeLinear];
    
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.delegate              = self;
    
    
    // If you make sure your dates are calculated at noon, you shouldn't have to
    // worry about daylight savings. If you use midnight, you will have to adjust
    // for daylight savings time.
    NSTimeInterval oneDay = 24 * 60 * 60;
    
    // Axes
    // Label x axis with a fixed interval policy
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.labelingPolicy              = CPTAxisLabelingPolicyAutomatic;
    x.majorIntervalLength         = CPTDecimalFromDouble(oneDay);
    x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.0);
    x.minorTicksPerInterval       = 0;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = kCFDateFormatterShortStyle;
    CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
    timeFormatter.referenceDate = [NSDate dateWithTimeIntervalSince1970:0];
    x.labelFormatter            = timeFormatter;
    x.labelRotation             = CPTFloat(M_PI_4);
    x.labelOffset = 5.0;
    
    x.title         = @"Date";
    x.titleOffset   = 30.0;
    x.titleLocation = CPTDecimalFromDouble(1.25);
    
    // Label y with an automatic label policy.
    CPTXYAxis *y = axisSet.yAxis;
    y.labelingPolicy              = CPTAxisLabelingPolicyAutomatic;
    y.majorIntervalLength = CPTDecimalFromDouble(10);
    y.minorTicksPerInterval       = 2;
//    y.preferredNumberOfMajorTicks = 8;
    y.labelOffset                 = 10.0;
    
    y.title         = @"Messages";
    y.titleOffset   = 20.0;
    y.titleLocation = CPTDecimalFromDouble(50.0);
    
    // Set axes
    graph.axisSet.axes = @[x, y];
    
    
    // Create a plot that uses the data source method
    CPTScatterPlot *plot = [[CPTScatterPlot alloc] init];
    plot.dataSource = self;
    plot.identifier = @"foo";
    CPTMutableLineStyle *lineStyle = [plot.dataLineStyle mutableCopy];
    lineStyle.lineWidth              = 1.0;
    lineStyle.lineColor              = [CPTColor blackColor];
    plot.dataLineStyle = lineStyle;
    
    plot.interpolation = CPTScatterPlotInterpolationStepped;
    [graph addPlot:plot];
    
    // Add plot symbols
    CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
    symbolLineStyle.lineColor = [CPTColor blackColor];
    CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    plotSymbol.fill               = [CPTFill fillWithColor:[CPTColor blueColor]];
    plotSymbol.lineStyle          = symbolLineStyle;
    plotSymbol.size               = CGSizeMake(5.0, 5.0);
    plot.plotSymbol               = plotSymbol;
    
    // Set plot delegate, to know when symbols have been touched
    // We will display an annotation when a symbol is touched
    plot.delegate                        = self;
    plot.plotSymbolMarginForHitDetection = 5.0;
    
    // Add legend
    graph.legend                 = [CPTLegend legendWithGraph:graph];
    graph.legend.textStyle       = x.titleTextStyle;
    graph.legend.borderLineStyle = x.axisLineStyle;
    graph.legend.cornerRadius    = 5.0;
    graph.legend.swatchSize      = CGSizeMake(25.0, 25.0);
    graph.legendAnchor           = CPTRectAnchorBottomRight;
    graph.legendDisplacement     = CGPointMake(0.0, 12.0);
    
    // Put an area gradient under the plot above
    CPTColor *areaColor       = [CPTColor colorWithComponentRed:0.3 green:1.0 blue:0.3 alpha:0.1];
    CPTFill *areaGradientFill = [CPTFill fillWithColor:areaColor];
    plot.areaFill      = areaGradientFill;
    plot.areaBaseValue = CPTDecimalFromDouble(0);
    
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
    CPTPlot *plot = [self.graphView.hostedGraph plotAtIndex:0];
    plot.identifier = account.handle;

    
    [self.graphView.hostedGraph reloadData];
    
    // Auto scale the plot space to fit the plot data
    // Extend the ranges by 30% for neatness
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graphView.hostedGraph.defaultPlotSpace;
    [plotSpace scaleToFitPlots:@[plot]];
    CPTMutablePlotRange *xRange = [plotSpace.xRange mutableCopy];
    NSDecimal earliestDate = xRange.location;
    CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
    [xRange expandRangeByFactor:CPTDecimalFromDouble(1.3)];
    [yRange expandRangeByFactor:CPTDecimalFromDouble(1.3)];
    plotSpace.xRange = xRange;
    plotSpace.yRange = yRange;
    
    // Update to have Y-Axis cross X-Axis at earliest chat date
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graphView.hostedGraph.axisSet;
    CPTXYAxis *yAxis = axisSet.yAxis;
    yAxis.orthogonalCoordinateDecimal = earliestDate;
    self.graphView.hostedGraph.axisSet.axes = @[ axisSet.xAxis, yAxis ];
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
        num = @([conv.timestamp timeIntervalSince1970]);
    } else {
        num = @([conv.size doubleValue] / 1024.0);
    }
    
    return num;
}

- (CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)idx {
    return nil;
}

#pragma mark - CPTPlotDelegate methods
-(void)scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)idx {
    NSLog(@"touch symbol at idx %lu in  %@", idx, plot);
}

-(void)scatterPlotDataLineWasSelected:(CPTScatterPlot *)plot {
    NSLog(@"touched plot %@", plot);
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
