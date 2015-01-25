//
//  RevelioTests.m
//  RevelioTests
//
//  Created by Christine Yen on 11/20/13.
//  Copyright (c) 2013 ChristineYen. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CorePlot/CorePlot.h>

#import "CYRImporter.h"
#import "Account.h"
#import "Conversation.h"

#import "ISO8601.h"

@interface CYRImporter (Tests)
@property (strong, nonatomic) Account *user;
@property (strong, nonatomic) Account *buddy;
@property (strong, nonatomic) Conversation *conversation;
@property (strong, nonatomic) NSArray *messages;

- (id)initWithPath:(NSString *)path attributes:(NSDictionary *)attributes;
- (void)parseDocument:(NSString *)documentContents;
@end

@interface RevelioTests : XCTestCase

@end

static NSString *const xml = @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?> \
<chat xmlns=\"http://purl.org/net/ulf/ns/0.4-02\" account=\"cyenatwork\" service=\"AIM\"><event type=\"windowOpened\" sender=\"cyenatwork\" time=\"2007-08-08T12:55:55-07:00\"/> \
<message sender=\"sjw0n\" time=\"2007-08-08T12:55:55-07:00\"><div><span style=\"font-family: Lucida Grande; font-size: 12pt;\">m... is seth cmin in?</span></div></message> \
<message sender=\"cyenatwork\" time=\"2007-08-08T12:56:02-07:00\"><div><span style=\"font-family: Helvetica; font-size: 12pt;\">don&apos;t know, doubt it</span></div></message> \
<message sender=\"sjw0n\" time=\"2007-08-08T12:56:17-07:00\"><div><span style=\"font-family: Lucida Grande; font-size: 12pt;\">aw</span></div></message> \
<message sender=\"cyenatwork\" time=\"2007-08-08T12:56:18-07:00\"><div><span style=\"font-family: Helvetica; font-size: 12pt;\">want me to check if he&apos;s coming in tomorrow?</span></div></message> \
<message sender=\"sjw0n\" time=\"2007-08-08T12:56:26-07:00\"><div><span style=\"font-family: Lucida Grande; font-size: 12pt;\">sure</span></div></message> \
<status type=\"offline\" sender=\"sjw0n\" time=\"2007-08-08T13:05:44-07:00\"/> \
<status type=\"online\" sender=\"sjw0n\" time=\"2007-08-08T15:50:52-07:00\"/> \
<message sender=\"cyenatwork\" time=\"2007-08-08T16:25:20-07:00\"><div><span style=\"font-family: Helvetica; font-size: 12pt;\">omg</span></div></message> \
<message sender=\"cyenatwork\" time=\"2007-08-08T16:25:23-07:00\"><div><span style=\"font-family: Helvetica; font-size: 12pt;\">trunk is so fucking crashy</span></div></message> \
<message sender=\"sjw0n\" time=\"2007-08-08T16:25:56-07:00\"><div><span style=\"font-family: Lucida Grande; font-size: 12pt;\">haha</span></div></message> \
<message sender=\"sjw0n\" time=\"2007-08-08T16:25:58-07:00\"><div><span style=\"font-family: Lucida Grande; font-size: 12pt;\">ic</span></div></message> \
<status type=\"offline\" sender=\"sjw0n\" time=\"2007-08-08T17:14:18-07:00\"/> \
<status type=\"online\" sender=\"sjw0n\" time=\"2007-08-08T17:31:29-07:00\"/> \
<status type=\"offline\" sender=\"sjw0n\" time=\"2007-08-08T17:31:43-07:00\"/> \
<status type=\"online\" sender=\"sjw0n\" time=\"2007-08-08T20:00:02-07:00\"/> \
<status type=\"offline\" sender=\"sjw0n\" time=\"2007-08-08T20:01:45-07:00\"/> \
<event type=\"windowClosed\" sender=\"cyenatwork\" time=\"2007-08-09T02:13:50-07:00\"/> \
</chat>";

static NSString *const estXML = @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?> \
<chat xmlns=\"http://purl.org/net/ulf/ns/0.4-02\" account=\"cyenatwork\" service=\"AIM\"><event type=\"windowOpened\" sender=\"cyenatwork\" time=\"2008-10-08T12:55:55-04:00\"/> \
<message sender=\"sjw0n\" time=\"2008-10-08T12:55:55-04:00\"><div><span style=\"font-family: Lucida Grande; font-size: 12pt;\">m... is seth cmin in?</span></div></message> \
<event type=\"windowClosed\" sender=\"cyenatwork\" time=\"2008-10-09T02:13:50-04:00\"/> \
</chat>";

static NSString *const crossDayXML = @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?> \
<chat xmlns=\"http://purl.org/net/ulf/ns/0.4-02\" account=\"cyenatwork\" service=\"AIM\"><event type=\"windowOpened\" sender=\"cyenatwork\" time=\"2007-08-08T22:55:54-07:00\"/> \
<message sender=\"sjw0n\" time=\"2007-08-08T22:55:55-07:00\"><div><span style=\"font-family: Lucida Grande; font-size: 12pt;\">m... is seth cmin in?</span></div></message> \
<message sender=\"cyenatwork\" time=\"2007-08-08T23:36:02-07:00\"><div><span style=\"font-family: Helvetica; font-size: 12pt;\">don&apos;t know, doubt it</span></div></message> \
<message sender=\"sjw0n\" time=\"2007-08-09T00:12:02-07:00\"><div><span style=\"font-family: Lucida Grande; font-size: 12pt;\">aw</span></div></message> \
<message sender=\"cyenatwork\" time=\"2007-08-09T01:24:02-07:00\"><div><span style=\"font-family: Helvetica; font-size: 12pt;\">want me to check if he&apos;s coming in tomorrow?</span></div></message> \
<event type=\"windowClosed\" sender=\"cyenatwork\" time=\"2007-08-09T02:12:02-07:00\"/> \
</chat>";

@implementation RevelioTests

- (void)setUp
{
    [super setUp];
    [CYRImporter clearState];
    [[NSUserDefaults standardUserDefaults] setObject:@"cyenatwork" forKey:@"CurrentHandle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testParse {
    CYRImporter *importer = [[CYRImporter alloc] init];
    [importer parseDocument:xml];
    Account *user = importer.user;
    XCTAssertEqualObjects(user.handle, @"cyenatwork");
    Account *buddy = importer.buddy;
    XCTAssertEqualObjects(buddy.handle, @"sjw0n");
    XCTAssertEqual(9, [importer.messages count], @"incorrect: %@", importer.messages);
    NSInteger expectedTotal = [importer.conversation.msgsUser integerValue] + [importer.conversation.msgsBuddy integerValue];
    XCTAssertEqual(9, expectedTotal);
    XCTAssertEqual(4, [importer.conversation.msgsUser integerValue]);
    XCTAssertEqual(5, [importer.conversation.msgsBuddy integerValue]);
    XCTAssertFalse([importer.conversation.initiated boolValue]);
    XCTAssertNotNil(importer.conversation.startTime);
    XCTAssertNotNil(importer.conversation.endTime);
    XCTAssertEqual(-25200, [importer.conversation.tzOffset integerValue]);
    XCTAssertEqual(1186602955, [importer.conversation.startTime timeIntervalSince1970]);
}

- (void)testParseWithAttributes {
    NSDictionary *attrs = @{
                            NSFileSize: @500,
                            NSFileCreationDate: [NSDate dateWithTimeIntervalSince1970:1262304000] };
    CYRImporter *importer = [[CYRImporter alloc] initWithPath:@"foo" attributes:attrs];
    XCTAssertEqualObjects(importer.conversation.size, attrs[NSFileSize]);
    XCTAssertEqualObjects(importer.conversation.timestamp, attrs[NSFileCreationDate]);
}

- (void)testParseEST {
    CYRImporter *importer = [[CYRImporter alloc] init];
    [importer parseDocument:estXML];
    XCTAssertEqual(-14400, [importer.conversation.tzOffset integerValue]);
    XCTAssertEqual(1223484955, [importer.conversation.startTime timeIntervalSince1970]);
}

- (void)testCrossDay {
    CYRImporter *importer = [[CYRImporter alloc] init];
    [importer parseDocument:crossDayXML];
    Account *user = importer.user;
    user.conversations = (NSSet *)[NSOrderedSet orderedSetWithObjects:importer.conversation, nil];
    XCTAssertEqual(1, [user.conversations count]);

    XCTAssertEqual(2, [user.conversationsByTime count]);
    // First location: 2007/08/08 22:55:55
    NSDictionary *pt1 = user.conversationsByTime[0];
    XCTAssertEqual(1186638955, [pt1[@(CPTBarPlotFieldBarLocation)] integerValue]);
    XCTAssertEqual(82555, [pt1[@(CPTBarPlotFieldBarBase)] integerValue]);
    XCTAssertEqual(86399, [pt1[@(CPTBarPlotFieldBarTip)] integerValue]);
    // Second time: 2007/08/09 01:24:02
    NSDictionary *pt2 = user.conversationsByTime[1];
    XCTAssertEqual(1186642800, [pt2[@(CPTBarPlotFieldBarLocation)] integerValue]);
    XCTAssertEqual(0, [pt2[@(CPTBarPlotFieldBarBase)] integerValue]);
    XCTAssertEqual(5042, [pt2[@(CPTBarPlotFieldBarTip)] integerValue]);
}

@end
