//
//  AppDelegate.h
//  Estates Audit
//
//  Created by Colin Gormley on 24/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, copy) void (^onCompletion)(void);
@property (strong, nonatomic) NSURLSession *jitBitDownloadSession;

-(NSString *)encodedCredentials;

-(void)syncWithJitBit;
-(BOOL)isNetworkAvailable;
-(void)displayNetworkNotification;
-(void)setUserName:(NSString *)username withPassword:(NSString *)password;
-(BOOL)isLoggedIn;
-(void)removeAllUsersFromKeychain;
-(void)deleteKeyChainCredentialsAndCoreDataRecords;

@end

