//
//  RevelioTests.m
//  RevelioTests
//
//  Created by Christine Yen on 11/20/13.
//  Copyright (c) 2013 ChristineYen. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "CYRImporter.h"
#import "User.h"
#import "Conversation.h"

@interface CYRImporter (Tests)
@property (strong, nonatomic) User *user;
@property (strong, nonatomic) User *buddy;
@property (strong, nonatomic) Conversation *conversation;
@property (strong, nonatomic) NSArray *messages;

- (id)initWithPath:(NSString *)path attributes:(NSDictionary *)attributes;
- (id)initWithXMLDocument:(NSString *)doc;
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

@implementation RevelioTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testParse {
    CYRImporter *importer = [[CYRImporter alloc] initWithXMLDocument:xml];
    User *user = (User *)importer.user;
    XCTAssertEqualObjects(user.handle, @"cyenatwork");
    User *buddy = (User *)importer.buddy;
    XCTAssertEqualObjects(buddy.handle, @"sjw0n");
    XCTAssertEqual(9, [importer.messages count], @"incorrect: %@", importer.messages);
    NSInteger expectedTotal = [importer.conversation.msgsUser integerValue] + [importer.conversation.msgsBuddy integerValue];
    XCTAssertEqual(9, expectedTotal);
    XCTAssertFalse([importer.conversation.initiated boolValue]);
    XCTAssertNotNil(importer.conversation.startTime);
    XCTAssertNotNil(importer.conversation.endTime);
}

- (void)testParseWithAttributes {
    NSDictionary *attrs = @{
                            NSFileSize: @500,
                            NSFileCreationDate: [NSDate dateWithTimeIntervalSince1970:1262304000] };
    CYRImporter *importer = [[CYRImporter alloc] initWithPath:@"foo" attributes:attrs];
    XCTAssertEqualObjects(importer.conversation.size, attrs[NSFileSize]);
    XCTAssertEqualObjects(importer.conversation.timestamp, attrs[NSFileCreationDate]);
}

@end
