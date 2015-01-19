//
//  CYRImporter.h
//  Revelio
//
//  Created by Christine Yen on 11/21/13.
//  Copyright (c) 2013 ChristineYen. All rights reserved.
//

@interface CYRImporter : NSObject

extern NSString *const kDefaultsLogPathKey;
extern NSString *const kDefaultsLastImportedKey;
extern NSString *const kDefaultsHandleKey;
extern NSString *const kNotificationFinishedImporting;

+ (NSString *)logsPath;
+ (NSString *)handle;
+ (BOOL)setLogsPath:(NSString *)path error:(NSError **)error;
+ (void)clearState;
+ (void)maybeUpdate;
@end
