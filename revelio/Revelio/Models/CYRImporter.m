//
//  CYRImporter.m
//  Revelio
//
//  Created by Christine Yen on 11/21/13.
//  Copyright (c) 2013 ChristineYen. All rights reserved.
//

#import "CYRImporter.h"
#import "CYRAppDelegate.h"

#import "User.h"
#import "Conversation.h"

@interface CYRImporter ()<NSXMLParserDelegate>

@property (strong, nonatomic) User *user;
@property (strong, nonatomic) User *buddy;
@property (strong, nonatomic) Conversation *conversation;
@property (strong, nonatomic) NSMutableArray *messages;

@property (nonatomic) NSInteger myMsgCount;
@property (nonatomic) NSInteger totalCount;

// Buffers the last message time seen
@property (nonatomic, strong) NSString *latestTime;

// Captures the handle of the buddy from the conversation
@property (strong, nonatomic) NSString *buddyHandle;

// Buffers the various parts of a single message, to compensate for NSXMLParser sucking
@property (strong, nonatomic) NSMutableArray *messageComponents;

@property (strong, nonatomic) NSXMLParser *parser;
@property (strong, nonatomic) NSManagedObjectContext *context;

- (id)initWithPath:(NSString *)path size:(unsigned long long)size;
- (id)initWithXMLDocument:(NSString *)doc;
- (void)_parseDocument;
- (void)_handleMessage:(NSDictionary *)attributeDict;
- (void)_handleWindowClosed:(NSDictionary *)attributeDict;
- (User *)_ensureUser:(NSString *)handle;

+ (NSDateFormatter *)dateFormatter;
@end

@implementation CYRImporter

static NSString *const kLogPathKey = @"LogsPath4";

+ (NSString *)logsPath {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kLogPathKey];
}

+ (BOOL)setLogsPath:(NSString *)path error:(NSError **)error {
    // TODO there should be lots better logic in here 
    NSArray *segments = [path pathComponents];
    NSString *errorMsg;
    if ([segments count] < 2) {
        errorMsg = @"path looks invalid";
    } else if ([[[segments lastObject] componentsSeparatedByString:@"."] count] < 2) {
        errorMsg = @"doesn't look like a SERVICE.user format";
    }

    if (errorMsg) {
        *error = [NSError errorWithDomain:NSURLErrorDomain
                                     code:0
                                 userInfo:@{NSLocalizedDescriptionKey: @"path looks invalid",
                                            NSFilePathErrorKey: path}];
        return NO;
    }

    [[NSUserDefaults standardUserDefaults] setObject:path forKey:kLogPathKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

+ (void)clearLogsPath {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kLogPathKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)maybeUpdate {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:[NSURL fileURLWithPath:[self logsPath]]
                                          includingPropertiesForKeys:@[ NSURLIsRegularFileKey ]
                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler:nil];
    NSError *err;
    for (NSURL *theURL in enumerator) {
        NSNumber *isFileKey;
        [theURL getResourceValue:&isFileKey forKey:NSURLIsRegularFileKey error:nil];
        if (![isFileKey boolValue]) {
            continue;
        }

        NSDictionary *attributes = [fileManager attributesOfItemAtPath:[theURL path] error:&err];
        if (err != nil) {
            NSLog(@"Failed to stat file at %@", [theURL path]);
            break;
        }
        [[self alloc] initWithPath:[theURL path] size:[attributes fileSize]];
    }
}

+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    }
    return formatter;
}

- (id)initWithPath:(NSString *)path size:(unsigned long long)size {
    NSString *conv = [NSString stringWithContentsOfFile:path
                                               encoding:NSUTF8StringEncoding
                                                  error:NULL];
    if (self = [self initWithXMLDocument:conv]) {
        self.conversation.path = path;
        self.conversation.size = @(size);
    }
    return self;
}

// TODO: actually verify that this input is valid XML somehow
- (id)initWithXMLDocument:(NSString *)doc {
    if (self = [super init]) {
        self.parser = [[NSXMLParser alloc] initWithData:[doc dataUsingEncoding:NSUTF8StringEncoding]];
        self.parser.delegate = self;
        [self _parseDocument];
    }
    return self;
}

- (Conversation *)conversation {
    if (_conversation == nil) {
        NSEntityDescription *convEntity = [NSEntityDescription entityForName:@"Conversation"
                                                      inManagedObjectContext:self.context];
        _conversation = [[Conversation alloc] initWithEntity:convEntity
                              insertIntoManagedObjectContext:self.context];
        _conversation.initiated = @NO;
    }
    return _conversation;
}

- (NSManagedObjectContext *)context {
    if (_context == nil) {
        CYRAppDelegate *delegate = [[NSApplication sharedApplication] delegate];
        _context = delegate.managedObjectContext;
    }
    return _context;
}

#pragma mark - NSXMLParserDelegate methods
// https://github.com/mwaterfall/MWFeedParser/blob/master/Classes/MWFeedParser.m

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"message"]) {
        [self _handleMessage:attributeDict];
    } else if ([elementName isEqualToString:@"windowClosed"]) {
        [self _handleWindowClosed:attributeDict];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"message"]) {
        [self.messages addObject:[self.messageComponents componentsJoinedByString:@""]];
        [self.messageComponents removeAllObjects];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    NSString *content = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([content length] > 0) {
        [self.messageComponents addObject:content];
    }
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    self.messages = [NSMutableArray array];
    self.messageComponents = [NSMutableArray array];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    self.conversation.msgsUser = @(self.myMsgCount);
    self.conversation.msgsBuddy = @(self.totalCount - self.myMsgCount);
    self.conversation.endTime = [[[self class] dateFormatter] dateFromString:self.latestTime];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"parse error: %@", parseError);
}


#pragma mark - Private methods
- (void)_parseDocument {
    if (self.parser == nil) {
        return;
    }
    if (![self.parser parse]) {
        NSLog(@"FAILED PARSING: %@", [self.parser parserError]);
    }
    self.parser = nil;
    self.user = [self _ensureUser:@"cyenatwork"];
    self.buddy = [self _ensureUser:self.buddyHandle];
    
    NSError *err;
    [self.context save:&err];
    if (err != nil) {
        NSLog(@"errrr: %@", err);
    }
}

- (void)_handleMessage:(NSDictionary *)attributeDict {
    BOOL firstMsg = self.totalCount == 0;
    BOOL senderIsSelf = [[attributeDict objectForKey:@"sender"] isEqualToString:@"cyenatwork"];
    
    if (firstMsg && senderIsSelf) {
        self.conversation.initiated = @YES;
    }
    if (firstMsg) {
        self.conversation.startTime = [[[self class] dateFormatter] dateFromString:[attributeDict objectForKey:@"time"]];
    }
    if (senderIsSelf) {
        self.myMsgCount += 1;
    } else {
        self.buddyHandle = [attributeDict objectForKey:@"sender"];
    }

    self.latestTime = [attributeDict objectForKey:@"time"];
    self.totalCount += 1;
}

- (void)_handleWindowClosed:(NSDictionary *)attributeDict {
    self.conversation.timestamp = [[[self class] dateFormatter] dateFromString:[attributeDict objectForKey:@"time"]];
}

- (User *)_ensureUser:(NSString *)handle {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"handle = %@", handle];
    request.predicate = predicate;
    
    NSError *err = nil;
    NSArray *results = [self.context executeFetchRequest:request error:&err];
    if (results != nil && [results count] > 0) {
        if ([results count] > 1) {
            NSLog(@"WARNING: we have multiple User objects?!");
        }
        return [results lastObject];
    }
    
    // else, create a record
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User"
                                              inManagedObjectContext:self.context];
    User *user = [[User alloc] initWithEntity:entity
               insertIntoManagedObjectContext:self.context];
    user.handle = handle;
    return (User *)user;
}

@end
