//  AppDelegate.m
//  Estates Audit
//
//  Created by Colin Gormley on 24/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import "AppDelegate.h"
#import "AppDelegate+MOC.h"
#import "HomePageViewController.h"
#import "Report+Create.h"
#import "ReportDatabaseAvailability.h"
#import "SSKeychain.h"


#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
@interface AppDelegate () <NSURLSessionDownloadDelegate>

@property (copy, nonatomic) void (^jitBitDownloadBackgroundURLSessionCompletionHandler)();
@property (strong, nonatomic) NSManagedObjectContext *reportDatabaseContext;

@property (strong, nonatomic) NSTimer *jitBitForegroundFetchTimer;
@property (strong, nonatomic) NSMutableDictionary *ticketsFromJitBit;
@property (strong, nonatomic) NSMutableDictionary *ticketsCustomFieldsFromJitBit;

@property (strong, nonatomic) NSString *username;

@end

// name of the Flickr fetching background download session
#define JITBIT_FETCH @"Fetch tickets from JitBit"
#define JITBIT_FETCH_TICKET @"Fetch individual ticket from JitBit"
#define JITBIT_FETCH_ADDITIONAL_FIELDS @"Fetch aditional ticket fields from JitBit"

// Update every 10 mins
#define FOREGROUND_JITBIT_FETCH_INTERVAL (10*60)
// how long we'll wait for a JitBit fetch to return when we're in the background
#define BACKGROUND_JITBIT_FETCH_TIMEOUT (60)

NSString *const ESTATES_AUDIT_KEYCHAIN_SERVICE = @"Estates Audit";

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
    
    //Fire off a sync when app starts if user is logged in
    if([self isLoggedIn]){
        [self syncWithJitBit];
    }
   
    
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // Need to ask for notification permission in iOS8
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    
    NSDictionary *notificationOptions = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if ([notificationOptions objectForKey:@"message"]) {
        NSLog(@"%@", [notificationOptions objectForKey:@"message"]);
        application.applicationIconBadgeNumber -= 1;
     
    }
    
    
//    NSString *const KEYCHAIN_SERVICE = @"Estates Audit";
//    
//    NSError *error = nil;
//
//    NSArray *accounts = [SSKeychain accountsForService:KEYCHAIN_SERVICE];
//    if([accounts count] > 0){
//        NSDictionary *account = [accounts objectAtIndex:0];
//        NSLog(@"account %@", account);
//        
//        
//        NSString *p = [SSKeychain passwordForService:KEYCHAIN_SERVICE account:[account valueForKey:@"acct"]];
//        
//        NSLog(@"%@", p);
//    }else{
//        BOOL passwordSet = [SSKeychain setPassword:@"cgtest" forService:KEYCHAIN_SERVICE account:@"cgtest" error:&error];
//        
//        if ([error code] == SSKeychainErrorNotFound) {
//            NSLog(@"Password not set");
//        }
//    };
    
    return YES;
}


-(void)setUserName:(NSString *)username withPassword:(NSString *)password
{
    NSError *error = nil;
    
    [SSKeychain setPassword:password forService:ESTATES_AUDIT_KEYCHAIN_SERVICE account:username error:&error];
    if ([error code] == SSKeychainErrorNotFound) {
        NSLog(@"Password not set");
    }else{
        self.username = username;
    }
}

-(void)deleteCredentialsForUser:(NSString *)username
{
    [SSKeychain deletePasswordForService:ESTATES_AUDIT_KEYCHAIN_SERVICE account:username];
    self.username = nil;
}

-(void)deleteCredentials{
    
    NSArray *accounts = [SSKeychain accountsForService:ESTATES_AUDIT_KEYCHAIN_SERVICE];
    for (id account in accounts){
        NSString *user = [account valueForKey:@"acct"];
           [SSKeychain deletePasswordForService:ESTATES_AUDIT_KEYCHAIN_SERVICE account:user];
    }
}

-(BOOL)isLoggedIn
{
    if([[self encodedCredentials] length] > 0){
        return TRUE;
    }
    return FALSE;
}

-(NSString *)encodedCredentials
{
    NSString *authValue;

    NSArray *accounts = [SSKeychain accountsForService:ESTATES_AUDIT_KEYCHAIN_SERVICE];    
 
    if([accounts count] > 0){
        
        for (id account in accounts){
            NSString *user = [account valueForKey:@"acct"];
            if([user isEqualToString:self.username]){
                NSString *pass = [SSKeychain passwordForService:ESTATES_AUDIT_KEYCHAIN_SERVICE account:user];
                
                NSString *authStr = [NSString stringWithFormat:@"%@:%@", user, pass];
                NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
                return authValue = [NSString stringWithFormat: @"Basic %@",[authData base64EncodedStringWithOptions:0]];
            }
        }
        // Just use the first one?
        NSDictionary *account = [accounts objectAtIndex:0];
        NSString *user = [account valueForKey:@"acct"];
        NSString *pass = [SSKeychain passwordForService:ESTATES_AUDIT_KEYCHAIN_SERVICE account:user];
        
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", user, pass];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        return authValue = [NSString stringWithFormat: @"Basic %@",[authData base64EncodedStringWithOptions:0]];
    };
    
    return authValue;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{

    application.applicationIconBadgeNumber -= 1;
//    UIAlertView *notificationAlert = [[UIAlertView alloc] initWithTitle:@"Notification"    message: [notification alertBody]
//                                                               delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//    
//    [notificationAlert show];
}


// this is called occasionally by the system WHEN WE ARE NOT THE FOREGROUND APPLICATION
// in fact, it will LAUNCH US if necessary to call this method
// the system has lots of smarts about when to do this, but it is entirely opaque to us

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    // in lecture, we relied on our background flickrDownloadSession to do the fetch by calling [self startFlickrFetch]
    // that was easy to code up, but pretty weak in terms of how much it will actually fetch (maybe almost never)
    // that's because there's no guarantee that we'll be allowed to start that discretionary fetcher when we're in the background
    // so let's simply make a non-discretionary, non-background-session fetch here
    // we don't want it to take too long because the system will start to lose faith in us as a background fetcher and stop calling this as much
    // so we'll limit the fetch to BACKGROUND_FETCH_TIMEOUT seconds (also we won't use valuable cellular data)
    
    if (self.reportDatabaseContext) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        sessionConfig.allowsCellularAccess = NO;
        sessionConfig.timeoutIntervalForRequest = BACKGROUND_JITBIT_FETCH_TIMEOUT; // want to be a good background citizen!

        
        NSString *authValue = [self encodedCredentials];
        [sessionConfig setHTTPAdditionalHeaders:@{@"Authorization": authValue}];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                              delegate:self    // we MUST have a delegate for background configurations
                                                         delegateQueue:nil];
        
        NSString *apiStr = @"https://eaudit.jitbit.com/helpdesk/api/Tickets?count=5";
        
        NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
        
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request];
        task.taskDescription = JITBIT_FETCH;
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [task resume];
        
        // Need to ensure the completion handler is set or we get a warning
        self.jitBitDownloadBackgroundURLSessionCompletionHandler = completionHandler;
        
    } else {
        completionHandler(UIBackgroundFetchResultNoData); // no app-switcher update if no database!
    }
}

// this is called whenever a URL we have requested with a background session returns and we are in the background
// it is essentially waking us up to handle it
// if we were in the foreground iOS would just call our delegate method and not bother with this

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    // this completionHandler, when called, will cause our UI to be re-cached in the app switcher
    // but we should not call this handler until we're done handling the URL whose results are now available
    // so we'll stash the completionHandler away in a property until we're ready to call it
    // (see flickrDownloadTasksMightBeComplete for when we actually call it)
    self.jitBitDownloadBackgroundURLSessionCompletionHandler = completionHandler;
}




#pragma mark - Database Context

// we do some stuff when our database's context becomes available
// we kick off our foreground NSTimer so that we are fetching every once in a while in the foreground
// we post a notification to let others know the context is available

- (void)setReportDatabaseContext:(NSManagedObjectContext *)reportDatabaseContext
{
    _reportDatabaseContext = reportDatabaseContext;
    
    // every time the context changes, we'll restart our timer
    // so kill (invalidate) the current one
    // (we didn't get to this line of code in lecture, sorry!)
    [self.jitBitForegroundFetchTimer invalidate];
    self.jitBitForegroundFetchTimer = nil;
    
    if (self.reportDatabaseContext)
    {
        // this timer will fire only when we are in the foreground
        self.jitBitForegroundFetchTimer = [NSTimer scheduledTimerWithTimeInterval:FOREGROUND_JITBIT_FETCH_INTERVAL
                                                                           target:self
                                                                         selector:@selector(syncWithJitBit:)
                                                                         userInfo:nil
                                                                          repeats:YES];
    }
    
    // let everyone who might be interested know this context is available
    // this happens very early in the running of our application
    // it would make NO SENSE to listen to this radio station in a View Controller that was segued to, for example
    // (but that's okay because a segued-to View Controller would presumably be "prepared" by being given a context to work in)
    NSDictionary *userInfo = self.reportDatabaseContext ? @{ ReportDatabaseAvailabilityContext : self.reportDatabaseContext } : nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:ReportDatabaseAvailabilityNotification
                                                        object:self
                                                      userInfo:userInfo];
}


- (void)syncWithJitBit:(NSTimer *)timer // NSTimer target/action always takes an NSTimer as an argument
{
    [self syncWithJitBit];
}


- (void)syncWithJitBit
{
    // getTasksWithCompletionHandler: is ASYNCHRONOUS
    // but that's okay because we're not expecting startFlickrFetch to do anything synchronously anyway
    [self.jitBitDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        // let's see if we're already working on a fetch ...
        if (![downloadTasks count]) {
            // ... not working on a fetch, let's start one up
            
            // Create new dict to store ticket results
            _ticketsFromJitBit = [NSMutableDictionary dictionary];
            _ticketsCustomFieldsFromJitBit = [NSMutableDictionary dictionary];
            
            
            NSString *apiStr = @"https://eaudit.jitbit.com/helpdesk/api/Tickets?count=5";
            
            NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
            [request setHTTPMethod:@"GET"];
            
            NSURLSessionDownloadTask *task = [self.jitBitDownloadSession downloadTaskWithRequest:request];
            task.taskDescription = JITBIT_FETCH;
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            [task resume];
            
        } else {
            // ... we are working on a fetch (let's make sure it (they) is (are) running while we're here)
            for (NSURLSessionDownloadTask *task in downloadTasks) [task resume];
        }
    }];
}


- (NSURLSession *)jitBitDownloadSession // the NSURLSession we will use to fetch jitBit data in the background
{
    if (!_jitBitDownloadSession) {
        static dispatch_once_t onceToken; // dispatch_once ensures that the block will only ever get executed once per application launch
        dispatch_once(&onceToken, ^{
            // notice the configuration here is "backgroundSessionConfiguration:"
            // that means that we will (eventually) get the results even if we are not the foreground application
            // even if our application crashed, it would get relaunched (eventually) to handle this URL's results!
            
            NSURLSessionConfiguration *urlSessionConfig;
            
            // To avoid deprecation warning on iOS 8
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >=8.0f)
            {
                urlSessionConfig =[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:JITBIT_FETCH];
            }
            else
            {
                urlSessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:JITBIT_FETCH];
            }
 
            NSString *authValue = [self encodedCredentials];
            [urlSessionConfig setHTTPAdditionalHeaders:@{@"Authorization": authValue}];
            
            _jitBitDownloadSession = [NSURLSession sessionWithConfiguration:urlSessionConfig
                                                                   delegate:self    // we MUST have a delegate for background configurations
                                                              delegateQueue:nil];   // nil means "a random, non-main-queue queue"
        });
    }
    return _jitBitDownloadSession;
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

// Creates a task performing a GET for each ticket id tickets dict
- (void)ticketDetailsFromJitBit:(NSDictionary *)tickets{
    
    
    
    for( NSDictionary *ticket in tickets){
        
        // Try getting IssueID
        NSString *issueID = [ticket[@"IssueID"] stringValue];
        
        if([issueID length] > 0){
            
            // Need to do a GET on this ticket
            NSString *apiStr = [NSString stringWithFormat:@"https://eaudit.jitbit.com/helpdesk/api/ticket?id=%@", issueID];
            
            NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
            [request setHTTPMethod:@"GET"];
            
            // Query on a particular ticket id
            NSURLSessionDownloadTask *task = [self.jitBitDownloadSession downloadTaskWithRequest:request];
            
            // Have to set description so we can differentiate from JITBIT_FETCH in didFinishDownloadingToURL method
            task.taskDescription = JITBIT_FETCH_TICKET;
            
            // Set the ticket Id so we can reference it when we get a result
            [task setAccessibilityLabel:issueID];
            
            [task resume]; // don't forget that all NSURLSession tasks start out suspended!
            
            // Now we also need to get the custom fields for this issue
            [self fetchAdditionalTicketDetails: issueID];
        }
    }
}



// Get additional ticket fields
- (void)fetchAdditionalTicketDetails:(NSString *)issueID{

            // Need to do a GET on this ticket
            NSString *apiStr = [NSString stringWithFormat:@"https://eaudit.jitbit.com/helpdesk/api/TicketCustomFields?id=%@", issueID];
            
            NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
            [request setHTTPMethod:@"GET"];
            
            // Query on a particular ticket id
            NSURLSessionDownloadTask *task = [self.jitBitDownloadSession downloadTaskWithRequest:request];
    
            task.taskDescription = JITBIT_FETCH_ADDITIONAL_FIELDS;
            
            // Set the ticket Id so we can reference it when we get a result
            [task setAccessibilityLabel:issueID];
            
            [task resume]; // don't forget that all NSURLSession tasks start out suspended!
}




#pragma mark - NSURLSessionDownloadDelegate


- (void)loadTicketsFromLocalURL:(NSURL *)localFile
                   downloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    
    if(![downloadTask error]){
        
        NSDictionary *tickets;
        
        NSData *jitbitTicketsJSONData = [NSData dataWithContentsOfURL:localFile];
        if (jitbitTicketsJSONData) {
            tickets = [NSJSONSerialization JSONObjectWithData:jitbitTicketsJSONData
                                                      options:0
                                                        error:NULL];
        }
        
        // We now have a note of all ticket ids - need to do a get on each one to get further ticket details
        [self ticketDetailsFromJitBit:tickets];
    }
    
}


- (void)loadIndividualTicketFromLocalURL:(NSURL *)localFile
                                downloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    
    if(![downloadTask error]){
        NSString *ticketID  = [downloadTask accessibilityLabel];
        NSDictionary *ticket;
        NSData *jitbitTicketsJSONData = [NSData dataWithContentsOfURL:localFile];
        
        if (jitbitTicketsJSONData) {
            ticket = [NSJSONSerialization JSONObjectWithData:jitbitTicketsJSONData
                                                     options:0
                                                       error:NULL];
            NSLog(@"Ticket found for %@", ticketID);
            
            NSLog(@"**********************************************");
            
            // Add result to dict
            [self.ticketsFromJitBit setObject:ticket forKey:ticketID];
            
            // Call completion handler to see if all tasks are complete
            [self ticketListMightBeComplete];
        }
    }
}


- (void)loadAdditionalTicketDetailsFromLocalURL:(NSURL *)localFile
                                downloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    
    if(![downloadTask error]){
        NSString *ticketID  = [downloadTask accessibilityLabel];
        NSDictionary *additonalTicketDetails;
        NSData *jitbitTicketsJSONData = [NSData dataWithContentsOfURL:localFile];
        
        if (jitbitTicketsJSONData) {
            additonalTicketDetails = [NSJSONSerialization JSONObjectWithData:jitbitTicketsJSONData
                                                     options:0
                                                       error:NULL];
            NSLog(@"Additional ticket details found for %@", ticketID);
            
            [self.ticketsCustomFieldsFromJitBit setObject:additonalTicketDetails forKey:ticketID];
            
            // Call completion handler to see if all tasks are complete
            [self ticketListMightBeComplete];
        }
    }
}


// required by the protocol
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)localFile
{

    // First task is to get a list of the issues relevant to this user
    if ([downloadTask.taskDescription isEqualToString:JITBIT_FETCH]) {
        
        [self loadTicketsFromLocalURL:localFile downloadTask:downloadTask];
    }
    
    // Check if this is task for downloading individual tickets
    if ([downloadTask.taskDescription isEqualToString:JITBIT_FETCH_TICKET]) {
        
        [self loadIndividualTicketFromLocalURL:localFile downloadTask:downloadTask];
        
    }
    
    // Get custom fields for each ticket
    if ([downloadTask.taskDescription isEqualToString:JITBIT_FETCH_ADDITIONAL_FIELDS]) {
        
        [self loadAdditionalTicketDetailsFromLocalURL:localFile downloadTask:downloadTask];
        
    }
    
}

// required by the protocol
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    // we don't support resuming an interrupted download task
}

// required by the protocol
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    // we don't report the progress of a download in our UI, but this is a cool method to do that with
}

// not required by the protocol, but we should definitely catch errors here
// so that we can avoid crashes
// and also so that we can detect that download tasks are (might be) complete
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error && (session == self.jitBitDownloadSession)) {
        NSLog(@"ticket download failed: %@", error.localizedDescription);
        [self ticketListMightBeComplete];
    }
}



- (void)ticketListMightBeComplete
{
    
//    if (self.jitBitDownloadBackgroundURLSessionCompletionHandler) {
    [self.jitBitDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        // we're doing this check for other downloads just to be theoretically "correct"
        //  but we don't actually need it (since we only ever fire off one download task at a time)
        // in addition, note that getTasksWithCompletionHandler: is ASYNCHRONOUS
        //  so we must check again when the block executes if the handler is still not nil
        //  (another thread might have sent it already in a multiple-tasks-at-once implementation)
        if (![downloadTasks count]) {  // any more ticket downloads left?
            NSLog(@"********* TICKET DOWNLOAD COMPLETE***********");
            
            
            // invoke jitBitDownloadBackgroundURLSessionCompletionHandler (if it's still not nil)
            void (^completionHandler)() = self.jitBitDownloadBackgroundURLSessionCompletionHandler;
            self.jitBitDownloadBackgroundURLSessionCompletionHandler = nil;
            if (completionHandler) {
                completionHandler();
            }
            
            
            // We can hide the refresh control on ReportsTable using this callback
            if (self.onCompletion) {
                self.onCompletion();
            }
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            // Load Reports into Core Data
            [Report loadReportsFromJitBitDictionary:self.ticketsFromJitBit
                                   withCustomFields:self.ticketsCustomFieldsFromJitBit
                           intoManagedObjectContext:self.reportDatabaseContext];
        
        }else{
            NSLog(@"%lu Tasks remaining", (unsigned long)[downloadTasks count]);
            
            // Nasty hack to get last task oterhwise we might never complete
            if([downloadTasks count] == 1){
                [NSThread sleepForTimeInterval:1];
                [self ticketListMightBeComplete];
                
        }}// else other downloads going, so let them call this method when they finish
    }];
//            }
}


@end
