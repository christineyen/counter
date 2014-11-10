//
//  CYRAppDelegate.m
//  Revelio
//
//  Created by Christine Yen on 11/20/13.
//  Copyright (c) 2013 ChristineYen. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "CYRAppDelegate.h"
#import "CYRMainWindowController.h"

#import "CYRImporter.h"

@interface CYRAppDelegate ()
@property (strong, nonatomic) NSOpenPanel *openPanel;
@property (strong, nonatomic) CYRMainWindowController *mainWindowController;

- (void)_reset;
- (void)_clear;
@end

@implementation CYRAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSLog(@"context: %@", self.managedObjectContext);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    NSError *err;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&err];
    NSLog(@"got: %@", results);
    
    NSManagedObject *obj = [NSEntityDescription insertNewObjectForEntityForName:@"Account"
                                                         inManagedObjectContext:self.managedObjectContext];
//    [obj setValue:@"Handle" forKey:@"handle"];
    
    NSError *error = nil;
    
    if (![self.managedObjectContext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    NSLog(@"has changes? %@", [self.managedObjectContext hasChanges] ? @"Y": @"N");
    if ([self.managedObjectContext save:&error]) {
        NSLog(@"saved!");
    } else {
        NSLog(@"save error: %@", error);
        NSLog(@"Unresolved error %@, %@, %@", error, [error userInfo],[error localizedDescription]);
    }
    
    results = [self.managedObjectContext executeFetchRequest:request error:&err];
    NSLog(@"got: %@", results);
    
//    if ([CYRImporter logsPath]) {
//        [self.mainWindowController showWindow:self];
//        [CYRImporter maybeUpdate];
//    } else {
//        [self _reset];
//    }
}

- (IBAction)logout:(id)sender {
    [CYRImporter clearLogsPath];
    [self.mainWindowController close];
    [self _reset];
    [self _clear];
}

- (void)_reset {
    if ([self.openPanel runModal] == NSFileHandlingPanelOKButton) {
        NSString *directoryPath = [[self.openPanel URL] path];
        NSError *error;
        if ([CYRImporter setLogsPath:directoryPath error:&error]) {
            [self.mainWindowController showWindow:self];
            [CYRImporter maybeUpdate];
        } else {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            [self _reset];
        }
    }
}

- (void)_clear {
    NSFetchRequest *all = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    [all setIncludesPropertyValues:NO]; //only fetch the managedObjectID

    NSError *error = nil;
    NSArray *objs = [self.managedObjectContext executeFetchRequest:all error:&error];
    //error handling goes here
    for (NSManagedObject *obj in objs) {
        [self.managedObjectContext deleteObject:obj];
    }
    NSError *saveError = nil;
    [self.managedObjectContext save:&saveError];
}

#pragma mark - Properties
- (CYRMainWindowController *)mainWindowController {
    if (_mainWindowController == nil) {
        _mainWindowController = [[CYRMainWindowController alloc] initWithWindowNibName:@"CYRMainWindowController"];
    }
    return _mainWindowController;
}

- (NSOpenPanel *)openPanel {
    if (_openPanel == nil) {
        _openPanel = [NSOpenPanel openPanel];
        _openPanel.canChooseDirectories = YES;
        _openPanel.canChooseFiles = NO;
        NSString *unsandboxedLibrary = [NSString stringWithFormat:@"%@/Library", NSHomeDirectoryForUser(NSUserName())];
        _openPanel.directoryURL = [NSURL fileURLWithPath:unsandboxedLibrary];
        _openPanel.message = @"Select the directory your libpurple logs live in.\n"
        "For example, Adium stores logs by default at ~/Library/Application Support/Adium 2.0/Users/Default/Logs/(Account)\n"
        "Be sure (for now) to select the directory of the ACCOUNT you want to start with.";
    }
    return _openPanel;
}

#pragma mark - Core Data stack

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.christineyen.Revellio" in the user's Application Support directory.
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.christineyen.Revelio"];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Revelio" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationDocumentsDirectory = [self applicationDocumentsDirectory];
    BOOL shouldFail = NO;
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    // Make sure the application files directory is there
    NSDictionary *properties = [applicationDocumentsDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (properties) {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            failureReason = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationDocumentsDirectory path]];
            shouldFail = YES;
        }
    } else if ([error code] == NSFileReadNoSuchFileError) {
        error = nil;
        [fileManager createDirectoryAtPath:[applicationDocumentsDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (!shouldFail && !error) {
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSURL *url = [applicationDocumentsDirectory URLByAppendingPathComponent:@"OSXCoreDataObjC.storedata"];
        if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) {
            coordinator = nil;
        }
        _persistentStoreCoordinator = coordinator;
    }
    
    if (shouldFail || error) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        if (error) {
            dict[NSUnderlyingErrorKey] = error;
        }
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return _managedObjectContext;
}

#pragma mark - Core Data Saving and Undo support

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        
        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertFirstButtonReturn) {
            return NSTerminateCancel;
        }
    }
    
    return NSTerminateNow;
}

@end
