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
#import "CYRImporter.h"
#import "Account.h"
#import "Conversation.h"

typedef enum {
    kTabQuantity,
    kTabTime,
    kTabSkew
} TabMode;

typedef enum {
    kQuantityCount,
    kQuantityMessages,
    kQuantitySize
} QuantityMode;

typedef enum {
    kTabLength,
    kTabTimeOfDay
} TimeMode;

@interface CYRMainWindowController ()<NSTableViewDataSource, NSTableViewDelegate, CPTPlotSpaceDelegate, CPTPlotDataSource>
@property (strong, nonatomic) NSArray *results;
@property (strong, nonatomic) NSOrderedSet *selectedBuddies;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) CPTGraph *graph;
@property (nonatomic) TabMode tabMode;
@property (nonatomic) QuantityMode quantityMode;

@property (weak) IBOutlet NSSegmentedControl *quantitySegmentedControl;
@property (weak) IBOutlet NSView *quantityControlView;

- (IBAction)clickedQuantitySegmentedControl:(id)sender;
- (IBAction)clickedModeSegmentedControl:(id)sender;
- (void)handleFinishedImport;

- (void)_fetchBuddies:(void(^)(void))complete;
- (NSString *)_quantityYAxisTitle;
- (void)_reloadAndRescaleAxes;
- (CPTPlot *)_buildPlot:(NSString *)identifier;
- (CPTPlot *)_buildQuantityPlot:(NSString *)identifier;
- (CPTPlot *)_buildSkewPlot:(NSString *)identifier;
- (CPTPlot *)_buildTimePlot:(NSString *)identifier;
- (CPTColor *)_colorForIdentifier:(NSString *)identifier;
- (CPTColor *)_colorForIdentifier:(NSString *)identifier alpha:(CGFloat)alpha;
@end

@implementation CYRMainWindowController

static CGFloat kLineWidthDefault = 1.0;

- (id)initWithWindow:(NSWindow *)window {
    if (self = [super initWithWindow:window]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleFinishedImport)
                                                     name:kNotificationFinishedImporting
                                                   object:nil];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.graphView.hostedGraph = self.graph;
    self.graphView.layer.borderColor = [NSColor redColor].CGColor;
    self.graphView.layer.borderWidth = 1.0;
    
    [self.quantitySegmentedControl setTarget:self];
    [self.quantitySegmentedControl setAction:@selector(clickedQuantitySegmentedControl:)];
    
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
        plotSpace.allowsUserInteraction = (self.tabMode == kTabQuantity);
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
        x.labelRotation             = CPTFloat(M_PI_4/2);
        x.labelOffset               = 0.0;
        x.title                     = @"Date of conversation";
        x.titleOffset               = 30.0;

        CPTXYAxis *y                = axisSet.yAxis;
        y.labelingPolicy            = CPTAxisLabelingPolicyAutomatic;
        y.majorIntervalLength       = CPTDecimalFromDouble(10);
        y.minorTicksPerInterval     = 2;
        y.labelOffset               = 10.0;
        y.titleOffset               = 50.0;

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
    [self _reloadAndRescaleAxes];
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    self.results = [self.results sortedArrayUsingDescriptors:[tableView sortDescriptors]];
    [tableView reloadData];
}

#pragma mark - CPTPlotDataSource
- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    NSUInteger idx = [self.selectedBuddies indexOfObjectPassingTest:^BOOL(Account *account, NSUInteger idx, BOOL *stop) {
        return [account.handle isEqualToString:(NSString *)plot.identifier];
    }];
    Account *account = [self.selectedBuddies objectAtIndex:idx];
    if (self.tabMode == kTabTime) {
        // Breaks over the day boundary
        return [account.conversationsByTime count];
    }
    return [account.conversations count];
}

- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx {
    NSUInteger accIdx = [self.selectedBuddies indexOfObjectPassingTest:^BOOL(Account *account, NSUInteger idx, BOOL *stop) {
        return [account.handle isEqualToString:(NSString *)plot.identifier];
    }];
    Account *account = [self.selectedBuddies objectAtIndex:accIdx];

    NSDictionary *datapoint;
    if (self.tabMode == kTabQuantity) {
        switch (self.quantityMode) {
            case kQuantityCount:
                datapoint = account.conversationsByCount[idx];
                break;
            case kQuantityMessages:
                datapoint = account.conversationsByMessages[idx];
                break;
            case kQuantitySize:
                datapoint = account.conversationsBySize[idx];
                break;
            default:
                NSLog(@"wat? %@", @(self.quantityMode));
                break;
        }
    } else if (self.tabMode == kTabTime) {
        datapoint = account.conversationsByTime[idx];
    } else if (self.tabMode == kTabSkew) {
        datapoint = account.conversationsBySkew[idx];
    }
    return datapoint[@(fieldEnum)];
}

- (CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)idx {
    return nil;
}

#pragma mark - CYRMainWindowController methods

- (void)clear {
    self.results = nil;
    [self.tableView reloadData];
    [self close];
}

- (IBAction)clickedQuantitySegmentedControl:(id)sender {
    NSInteger idx = [self.quantitySegmentedControl selectedSegment];
    if (idx == self.quantityMode) {
        return;
    }
    self.quantityMode = (int)idx;
    [self _reloadAndRescaleAxes];
}

- (IBAction)clickedModeSegmentedControl:(id)sender {
    NSInteger idx = [((NSSegmentedControl *)sender) selectedSegment];
    if (idx == self.tabMode) {
        return;
    }
    self.tabMode = (int)idx;

    [[self.graph allPlots] enumerateObjectsUsingBlock:^(CPTPlot *plot, NSUInteger idx, BOOL *stop) {
        [self.graph removePlot:plot];
        [self.graph.legend removePlot:plot];
    }];
    
    [self.selectedBuddies enumerateObjectsUsingBlock:^(Account *account, NSUInteger idx, BOOL *stop) {
        CPTPlot *plot = [self _buildPlot:account.handle];
        [self.graph addPlot:plot];
        [self.graph.legend addPlot:plot];
    }];
    
    self.quantityControlView.hidden = !(self.tabMode == kTabQuantity);
    
    if (self.tabMode == kTabQuantity) {
        self.graph.defaultPlotSpace.allowsUserInteraction = YES;
    } else {
        self.graph.defaultPlotSpace.allowsUserInteraction = NO;
    }

    [self _reloadAndRescaleAxes];
}

- (void)handleFinishedImport {
    NSLog(@"triggering handle finished import");
    [self _fetchBuddies:^{
        [self.tableView reloadData];
    }];
}

#pragma mark - Private methods
- (void)_fetchBuddies:(void(^)(void))complete {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"handle != %@", [CYRImporter handle]];
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

- (NSString *)_quantityYAxisTitle {
    if (self.quantityMode == kQuantityCount) {
        return @"Number of conversation over time";
    } else if (self.quantityMode == kQuantityMessages) {
        return @"Number of messages over time";
    }
    return @"Number of bytes on disk over time";
}

- (void)_reloadAndRescaleAxes {
    [self.graph reloadData];
    
    // Auto scale the plot space to fit the plot data
    // Extend the ranges by 30% for neatness
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    [plotSpace scaleToFitPlots:[self.graph allPlots]];

    float xOffset = 0.15;
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    CPTXYAxis *xAxis = axisSet.xAxis;
    CPTXYAxis *yAxis = axisSet.yAxis;

    // Set up common X-Axis handling
    NSDecimal earliestDate = plotSpace.xRange.location;
    CPTMutablePlotRange *originalXRange = [plotSpace.xRange mutableCopy];

    xAxis.titleLocation = plotSpace.xRange.midPoint;
    xAxis.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.0); // probably doesn't have to go here

    CPTMutablePlotRange *expandedXRange = [plotSpace.xRange mutableCopy];
    [expandedXRange expandRangeByFactor:CPTDecimalFromDouble(1 + 2*xOffset)];
    plotSpace.xRange = expandedXRange;

    // Set up common Y-Axis handling
    NSDecimal orthogonal = CPTDecimalAdd(earliestDate, CPTDecimalMultiply(CPTDecimalSubtract(expandedXRange.location, earliestDate), CPTDecimalFromFloat(xOffset)));
    yAxis.orthogonalCoordinateDecimal = orthogonal;
    yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    yAxis.axisLabels = nil;
    yAxis.majorTickLocations = nil;

    [originalXRange unionPlotRange:[CPTPlotRange plotRangeWithLocation:orthogonal length:CPTDecimalFromInt(0)]];
    xAxis.visibleRange = originalXRange;

    if (self.tabMode == kTabQuantity) {
        CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
        [yRange unionPlotRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(0)]];
        [yRange expandRangeByFactor:CPTDecimalFromDouble(1 + 2*xOffset)];
        plotSpace.yRange = yRange;

        yAxis.title = [self _quantityYAxisTitle];
        yAxis.visibleRange = plotSpace.yRange;
    } else if (self.tabMode == kTabTime) {
        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(-8000) length:CPTDecimalFromInt(100800)];

        yAxis.title = @"time of day in conversation";
        yAxis.labelingPolicy = CPTAxisLabelingPolicyLocationsProvided;

        NSMutableSet *labels = [NSMutableSet set];
        NSMutableSet *tickLocations = [NSMutableSet set];
        for (NSUInteger i = 0; i <= 24; i += 2) {
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%.2lu:00", i]
                                                           textStyle:yAxis.labelTextStyle];
            NSDecimal location = CPTDecimalFromUnsignedInteger(i*3600);
            [tickLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:location]];
            label.tickLocation = location;
            label.offset = yAxis.labelOffset;
            [labels addObject:label];
        }
        yAxis.axisLabels = labels;
        yAxis.majorTickLocations = tickLocations;
        yAxis.visibleRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(86400)];
    } else if (self.tabMode == kTabSkew) {
        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(-1.2) length:CPTDecimalFromDouble(2.4)];

        yAxis.title = @"They sent more messages                              I sent more messages";
        yAxis.titleLocation = CPTDecimalFromDouble(0);
        yAxis.visibleRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(-1) length:CPTDecimalFromInt(2)];
    }
    
    yAxis.titleLocation = plotSpace.yRange.midPoint;
    self.graphView.hostedGraph.axisSet.axes = @[ xAxis, yAxis ];
}

- (CPTPlot *)_buildPlot:(NSString *)identifier {
    if (self.tabMode == kTabQuantity) {
        return [self _buildQuantityPlot:identifier];
    } else if (self.tabMode == kTabSkew) {
        return [self _buildSkewPlot:identifier];
    } else if (self.tabMode == kTabTime) {
        return [self _buildTimePlot:identifier];
    }
    return nil;
}

- (CPTPlot *)_buildQuantityPlot:(NSString *)identifier {
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
    plotSymbol.size               = CGSizeMake(1.0, 1.0);
    plot.plotSymbol               = plotSymbol;
    
    // Put an area gradient under the plot above
    CPTFill *areaGradientFill = [CPTFill fillWithColor:fillColor];
    plot.areaFill      = areaGradientFill;
    plot.areaBaseValue = CPTDecimalFromDouble(0);

    return plot;
}

- (CPTPlot *)_buildSkewPlot:(NSString *)identifier {
    // Create a plot that uses the data source method
    CPTBarPlot *plot = [[CPTBarPlot alloc] init];
    plot.identifier = identifier;
    plot.dataSource = self;
    plot.delegate   = self;

    // Set line and fill styles
    CPTColor *color = [self _colorForIdentifier:identifier alpha:0.3];
    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineColor = [color colorWithAlphaComponent:0.5];
    plot.lineStyle = lineStyle;
    plot.fill = [CPTFill fillWithColor:color];
    plot.barWidthsAreInViewCoordinates = YES;
    plot.barWidth = CPTDecimalFromFloat(10.0f);
    
    return plot;
}

- (CPTPlot *)_buildTimePlot:(NSString *)identifier {
    // Create a plot that uses the data source method
    CPTBarPlot *plot = [[CPTBarPlot alloc] init];
    plot.identifier = identifier;
    plot.dataSource = self;
    plot.delegate   = self;
    plot.barBasesVary = YES;
    
    // Set line and fill styles
    CPTColor *color = [self _colorForIdentifier:identifier alpha:0.3];
    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineColor = [color colorWithAlphaComponent:0.5];
    plot.lineStyle = lineStyle;
    plot.fill = [CPTFill fillWithColor:color];
    plot.barWidthsAreInViewCoordinates = YES;
    plot.barWidth = CPTDecimalFromFloat(10.0f);
    
    return plot;
}

- (CPTColor *)_colorForIdentifier:(NSString *)identifier {
    return [self _colorForIdentifier:identifier alpha:1];
}

- (CPTColor *)_colorForIdentifier:(NSString *)identifier alpha:(CGFloat)alpha {
    NSUInteger hash = [identifier hash];
    NSUInteger r = (hash & 0xFF0000) >> 16;
    NSUInteger g = (hash & 0x00FF00) >> 8;
    NSUInteger b = hash & 0x0000FF;
    return [CPTColor colorWithComponentRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:alpha];
}

@end