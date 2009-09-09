//
//  Moccery_AppDelegate.m
//  Moccery
//
//  Created by Andy Lee on 9/8/09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import "Moccery_AppDelegate.h"

@implementation Moccery_AppDelegate

@synthesize window;


- (void)dealloc
{
    [window release];
    [managedObjectContext release];
    [persistentStoreCoordinator release];
    [managedObjectModel release];
	
    [super dealloc];
}


#pragma mark -
#pragma mark Getters and setters

- (NSString *)applicationSupportDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Moccery"];
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel)
        return managedObjectModel;
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator)
        return persistentStoreCoordinator;

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom)
    {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if (![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL])
    {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error])
        {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory, error]));
            NSLog(@"Error creating application support directory at %@ : %@", applicationSupportDirectory, error);
            return nil;
		}
    }
    
    NSURL *url = [NSURL fileURLWithPath:[applicationSupportDirectory stringByAppendingPathComponent:@"storedata"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType 
                                                  configuration:nil 
                                                            URL:url 
                                                        options:nil 
                                                          error:&error])
    {
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
        return nil;
    }    

    return persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext)
        return managedObjectContext;

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:coordinator];

    return managedObjectContext;
}


#pragma mark -
#pragma mark Action methods

- (IBAction) saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing])
    {
        NSLog(@"%@:%s unable to commit editing before saving", [self class], _cmd);
    }

    if (![[self managedObjectContext] save:&error])
    {
        [[NSApplication sharedApplication] presentError:error];
    }
}


#pragma mark -
#pragma mark NSWindow delegate methods

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}


#pragma mark -
#pragma mark NSApplication delegate methods

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (!managedObjectContext)
        return NSTerminateNow;

    if (![managedObjectContext commitEditing])
    {
        NSLog(@"%@:%s unable to commit editing to terminate", [self class], _cmd);
        return NSTerminateCancel;
    }

    if (![managedObjectContext hasChanges])
        return NSTerminateNow;

    NSError *error = nil;
    if (![managedObjectContext save:&error])
    {
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.

        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
                
        BOOL result = [sender presentError:error];
        if (result)
            return NSTerminateCancel;

        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?",
                                               @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save",
                                           @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn)
            return NSTerminateCancel;
    }

    return NSTerminateNow;
}


@end
