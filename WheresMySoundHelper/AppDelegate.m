//
//  AppDelegate.m
//  WheresMySoundHelper
//
//  Created by Marco Barisione on 22/09/2017.
//  Copyright © 2017 Marco Barisione. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSArray<NSString *> *pathComponents = NSBundle.mainBundle.bundlePath.pathComponents;
    // Remove "Contents/Library/LoginItems/WheresMySoundHelper.app".
    pathComponents = [pathComponents subarrayWithRange:NSMakeRange(0, pathComponents.count - 4)];
    NSString *path = [NSString pathWithComponents:pathComponents];

    NSLog(@"Helper for Where’s My Sound starting main app: %@", path);
    [[NSWorkspace sharedWorkspace] launchApplication:path];

    [NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

@end
