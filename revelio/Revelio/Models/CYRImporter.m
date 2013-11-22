//
//  CYRImporter.m
//  Revelio
//
//  Created by Christine Yen on 11/21/13.
//  Copyright (c) 2013 ChristineYen. All rights reserved.
//

#import "CYRImporter.h"

@implementation CYRImporter

static NSString *const kLogPathKey = @"LogsPath";

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
    for (NSURL *theURL in enumerator) {
        NSNumber *isFileKey;
        [theURL getResourceValue:&isFileKey forKey:NSURLIsRegularFileKey error:nil];
        if (![isFileKey boolValue]) {
            continue;
        }

        NSString *conv = [NSString stringWithContentsOfFile:[theURL path]
                                                   encoding:NSUTF8StringEncoding
                                                      error:NULL];
        // do stuff with conv
    }
}

@end
