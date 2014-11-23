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
@property (strong, nonatomic) NSOrderedSet *selectedBuddies;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) CPTGraph *graph;

- (void)_fetchBuddies:(void(^)(void))complete;
- (CPTPlot *)_buildPlot:(NSString *)identifier;
- (CPTColor *)_colorForIdentifier:(NSString *)identifier;
@end

@implementation CYRMainWindowController

static CGFloat kLineWidthDefault = 1.0;
static CGFloat kLineWidthSelected = 3.0;

- (id)initWithWindow:(NSWindow *)window {
    if (self = [super initWithWindow:window]) {
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.graphView.hostedGraph = self.graph;

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

- (CPTGraph *)graph {
    if (_graph == nil) {
        _graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero]; //xScaleType:CPTScaleTypeLinear yScaleType:CPTScaleTypeLinear];
        // Setup scatter plot space
        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)_graph.defaultPlotSpace;
        plotSpace.allowsUserInteraction = YES;
        plotSpace.delegate              = self;
        
        // Axes
        CPTXYAxisSet *axisSet         = (CPTXYAxisSet *)_graph.axisSet;
        CPTXYAxis *x                  = axisSet.xAxis;
        x.title                       = @"Date";
        x.labelingPolicy              = CPTAxisLabelingPolicyAutomatic;
        x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.0);
        x.minorTicksPerInterval       = 0;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = kCFDateFormatterShortStyle;
        CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
        timeFormatter.referenceDate = [NSDate dateWithTimeIntervalSince1970:0];
        x.labelFormatter            = timeFormatter;
        x.labelRotation             = CPTFloat(M_PI_4);
        x.labelOffset               = 5.0;
        x.titleOffset               = 20.0;
        x.titleLocation             = CPTDecimalFromDouble(1.25);
        
        CPTXYAxis *y                = axisSet.yAxis;
        y.title                     = @"FOOOOO";
        y.labelingPolicy            = CPTAxisLabelingPolicyAutomatic;
        y.majorIntervalLength       = CPTDecimalFromDouble(10);
        y.minorTicksPerInterval     = 2;
        y.labelOffset               = 10.0;
        y.titleOffset               = 20.0;
        y.titleLocation             = CPTDecimalFromDouble(50.0);
        
        // Set axes
        _graph.axisSet.axes = @[x, y];
        
        // Add legend
        CPTLegend *legend      = [CPTLegend legendWithGraph:_graph];
        legend.textStyle       = x.titleTextStyle;
        legend.borderLineStyle = x.axisLineStyle;
        legend.cornerRadius    = 5.0;
        legend.numberOfColumns = 1;
        
        _graph.legend = legend;
        _graph.legendAnchor           = CPTRectAnchorTopRight;
        _graph.legendDisplacement     = CGPointMake(-5.0, -12.0);
    }
    return _graph;
        
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
    // Identify selected users
    NSIndexSet *indexSet = [self.tableView selectedRowIndexes];
    NSMutableOrderedSet *newSelection = [NSMutableOrderedSet orderedSetWithCapacity:[indexSet count]];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [newSelection addObject:self.results[idx]];
    }];
    
    // Identify Accounts to remove
    NSMutableOrderedSet *oldUsers = [NSMutableOrderedSet orderedSetWithOrderedSet:self.selectedBuddies];
    [oldUsers minusOrderedSet:newSelection];
    // Identify Accounts to add
    NSMutableOrderedSet *newUsers = [NSMutableOrderedSet orderedSetWithOrderedSet:newSelection];
    [newUsers minusOrderedSet:self.selectedBuddies];

    [oldUsers enumerateObjectsUsingBlock:^(Account *account, NSUInteger idx, BOOL *stop) {
        CPTPlot *plot = [self.graph plotWithIdentifier:account.handle];
        [self.graph removePlot:plot];
        [self.graph.legend removePlot:plot];
    }];
    [newUsers enumerateObjectsUsingBlock:^(Account *account, NSUInteger idx, BOOL *stop) {
        CPTPlot *plot = [self _buildPlot:account.handle];
        [self.graph addPlot:plot];
        [self.graph.legend addPlot:plot];
    }];
    
    // Set new selection
    self.selectedBuddies = newSelection;
    [self.graph reloadData];
    
    // Auto scale the plot space to fit the plot data
    // Extend the ranges by 30% for neatness
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    [plotSpace scaleToFitPlots:[self.graph allPlots]];
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
    NSUInteger idx = [self.selectedBuddies indexOfObjectPassingTest:^BOOL(Account *account, NSUInteger idx, BOOL *stop) {
        return [account.handle isEqualToString:(NSString *)plot.identifier];
    }];
    Account *account = [self.selectedBuddies objectAtIndex:idx];
    return [account.conversations count];
}

- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx {
    NSUInteger accIdx = [self.selectedBuddies indexOfObjectPassingTest:^BOOL(Account *account, NSUInteger idx, BOOL *stop) {
        return [account.handle isEqualToString:(NSString *)plot.identifier];
    }];
    Account *account = [self.selectedBuddies objectAtIndex:accIdx];
    DataPoint *datapoint = account.conversationsByMessages[idx];
    if (fieldEnum == CPTScatterPlotFieldX) {
        return datapoint.x;
    }
    return datapoint.y;
}

- (CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)idx {
    return nil;
}

#pragma mark - CPTPlotDelegate methods
-(void)scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)idx {
    NSLog(@"touch symbol at idx %lu in  %@", idx, plot);
}

-(void)scatterPlotDataLineWasSelected:(CPTScatterPlot *)plot {
    [[self.graph allPlots] enumerateObjectsUsingBlock:^(CPTScatterPlot *gPlot, NSUInteger idx, BOOL *stop) {
        CPTMutableLineStyle *lineStyle = [gPlot.dataLineStyle mutableCopy];
        CGFloat oldWidth = lineStyle.lineWidth;
        if (plot == gPlot) {
            lineStyle.lineWidth = kLineWidthSelected;
        } else {
            lineStyle.lineWidth = kLineWidthDefault;
        }
        if (oldWidth == lineStyle.lineWidth) {
            return;
        }
        gPlot.dataLineStyle = lineStyle;
        [gPlot reloadPlotSymbols];
    }];
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

- (CPTPlot *)_buildPlot:(NSString *)identifier {
    // Create a plot that uses the data source method
    CPTScatterPlot *plot = [[CPTScatterPlot alloc] init];
    plot.identifier = identifier;
    plot.dataSource = self;
    plot.delegate   = self;
    plot.plotSymbolMarginForHitDetection = 5.0;
    
    // Set line style
    CPTColor *color                  = [self _colorForIdentifier:identifier];
    CPTColor *fillColor              = [color colorWithAlphaComponent:0.25];
    CPTMutableLineStyle *lineStyle   = [plot.dataLineStyle mutableCopy];
    lineStyle.lineWidth              = kLineWidthDefault;
    lineStyle.lineColor              = color;
    plot.dataLineStyle = lineStyle;
    plot.interpolation = CPTScatterPlotInterpolationStepped;
    
    // Add plot symbols
    CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
    symbolLineStyle.lineColor     = color;
    CPTPlotSymbol *plotSymbol     = [CPTPlotSymbol ellipsePlotSymbol];
    plotSymbol.fill               = [CPTFill fillWithColor:fillColor];
    plotSymbol.lineStyle          = symbolLineStyle;
    plotSymbol.size               = CGSizeMake(5.0, 5.0);
    plot.plotSymbol               = plotSymbol;
    
    // Put an area gradient under the plot above
    CPTFill *areaGradientFill = [CPTFill fillWithColor:fillColor];
    plot.areaFill      = areaGradientFill;
    plot.areaBaseValue = CPTDecimalFromDouble(0);

    return plot;
}

- (CPTColor *)_colorForIdentifier:(NSString *)identifier {
    NSUInteger hash = [identifier hash];
    NSUInteger r = (hash & 0xFF0000) >> 16;
    NSUInteger g = (hash & 0x00FF00) >> 8;
    NSUInteger b = hash & 0x0000FF;
    return [CPTColor colorWithComponentRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1];
}

@end