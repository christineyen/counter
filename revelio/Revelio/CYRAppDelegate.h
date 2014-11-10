//
//  CYRAppDelegate.h
//  Revelio
//
//  Created by Christine Yen on 11/20/13.
//  Copyright (c) 2013 ChristineYen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CYRAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
