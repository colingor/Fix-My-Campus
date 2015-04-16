//  AppDelegate.m
//  Estates Audit
//
//  Created by Colin Gormley on 24/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import "AppDelegate.h"
#import "AppDelegate+MOC.h"
#import "HomePageViewController.h"
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
@interface AppDelegate ()

@property (strong, nonatomic) NSManagedObjectContext *reportDatabaseContext;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
  UINavigationBar *bar = [UINavigationBar appearance];

    // Change navbar colour
    UIColor *navBarColour = [UIColor colorWithRed:(0.0/ 255.0f) green:(39.0/ 255.0f) blue:(76.0/ 255.0f) alpha:(1.0f)];

    /*if ([bar respondsToSelector:@selector(setBarTintColor:)]) { // iOS 7+
        bar.barTintColor = navBarColour;
    } else { // what year is this? 2012?
        bar.tintColor = navBarColour;
    }*/
    
    bar.barTintColor = navBarColour;
    bar.tintColor = [UIColor whiteColor];
    
    // Change status bar text to white
    bar.barStyle = UIStatusBarStyleLightContent;
    
    // Change navbar text colour
    NSDictionary *textTitleOptions = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, [UIColor whiteColor], UITextAttributeTextShadowColor, nil];
    [[UINavigationBar appearance] setTitleTextAttributes:textTitleOptions];
    
    if (IS_OS_8_OR_LATER) {
        bar.translucent = NO;
    }
   
    // Override point for customization after application launch.
    self.reportDatabaseContext = [self createMainQueueManagedObjectContext];
    
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    HomePageViewController *homevc = [[navigationController viewControllers] objectAtIndex:0];
    homevc.managedObjectContext = self.reportDatabaseContext;
    
    //TODO: Maybe call API for existing report status in the background
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    // [self saveContext];
}

@end
