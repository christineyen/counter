//
//  CYRImporter.h
//  Revelio
//
//  Created by Christine Yen on 11/21/13.
//  Copyright (c) 2013 ChristineYen. All rights reserved.
//

@interface CYRImporter : NSObject
+ (NSString *)logsPath;
+ (BOOL)setLogsPath:(NSString *)path error:(NSError **)error;
+ (void)clearLogsPath;
+ (void)maybeUpdate;
@end
