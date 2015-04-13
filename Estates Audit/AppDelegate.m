//  AppDelegate.m
//  Estates Audit
//
//  Created by Colin Gormley on 24/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import "AppDelegate.h"
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
@interface AppDelegate ()

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
   /* UINavigationBar *navBar = [UINavigationBar appearance];
    NSArray *ver = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    
    // Change status bar text to white
    navBar.barStyle = UIStatusBarStyleLightContent;
    
    // Change navbar text colour
    NSDictionary *textTitleOptions = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, [UIColor whiteColor], UITextAttributeTextShadowColor, nil];
    [[UINavigationBar appearance] setTitleTextAttributes:textTitleOptions];
    
    
    if ([[ver objectAtIndex:0] intValue] >= 7) {
        // iOS 7.0 or later00274C
        navBar.barTintColor = navBarColour;
        navBar.translucent = NO;
    }else {
        // iOS 6.1 or earlier
        navBar.tintColor = navBarColour;
    }*/
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
