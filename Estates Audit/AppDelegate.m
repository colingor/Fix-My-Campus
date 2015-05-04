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
@interface AppDelegate () <NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSManagedObjectContext *reportDatabaseContext;
@property (strong, nonatomic) NSURLSession *jitBitDownloadSession;
@property (strong, nonatomic) NSMutableDictionary *ticketsFromJitBit;
@end

// name of the Flickr fetching background download session
#define JITBIT_FETCH @"Fetch tickets from JitBit"
#define JITBIT_FETCH_TICKET @"Fetch individual ticket from JitBit"


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
    [self syncWithJitBit];
    
    
    return YES;
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
            
            NSString *apiStr = @"https://eaudit.jitbit.com/helpdesk/api/Tickets";
            
            NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
            [request setHTTPMethod:@"GET"];
            
            // TODO: Credentials in code is bad...
            [request setValue:@"Basic Y2dvcm1sZTFAc3RhZmZtYWlsLmVkLmFjLnVrOmVzdGF0ZXNhdWRpdDM=" forHTTPHeaderField:@"Authorization"];
            
            NSURLSessionDownloadTask *task = [self.jitBitDownloadSession downloadTaskWithRequest:request];
            task.taskDescription = JITBIT_FETCH;
            
            [task resume];
            
        } else {
            // ... we are working on a fetch (let's make sure it (they) is (are) running while we're here)
            for (NSURLSessionDownloadTask *task in downloadTasks) [task resume];
        }
    }];
}


- (NSURLSession *)jitBitDownloadSession // the NSURLSession we will use to fetch Flickr data in the background
{
    if (!_jitBitDownloadSession) {
        static dispatch_once_t onceToken; // dispatch_once ensures that the block will only ever get executed once per application launch
        dispatch_once(&onceToken, ^{
            // notice the configuration here is "backgroundSessionConfiguration:"
            // that means that we will (eventually) get the results even if we are not the foreground application
            // even if our application crashed, it would get relaunched (eventually) to handle this URL's results!
            NSURLSessionConfiguration *urlSessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:JITBIT_FETCH];
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
            
            // TODO: Credentials in code is bad...
            [request setValue:@"Basic Y2dvcm1sZTFAc3RhZmZtYWlsLmVkLmFjLnVrOmVzdGF0ZXNhdWRpdDM=" forHTTPHeaderField:@"Authorization"];
            
            // Query on a particular ticket id
            NSURLSessionDownloadTask *task = [self.jitBitDownloadSession downloadTaskWithRequest:request];
            
            // Have to set description so we can differentiate from JITBIT_FETCH in didFinishDownloadingToURL method
            task.taskDescription = JITBIT_FETCH_TICKET;
            
            // Set the ticket Id so we can reference it when we get a result
            [task setAccessibilityLabel:issueID];
            
            [task resume]; // don't forget that all NSURLSession tasks start out suspended!
        }
    }
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


- (void)loadLoadIndividualTicketFromLocalURL:(NSURL *)localFile
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
        
        [self loadLoadIndividualTicketFromLocalURL:localFile downloadTask:downloadTask];
        
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
    
    //        if (self.flickrDownloadBackgroundURLSessionCompletionHandler) {
    [self.jitBitDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        // we're doing this check for other downloads just to be theoretically "correct"
        //  but we don't actually need it (since we only ever fire off one download task at a time)
        // in addition, note that getTasksWithCompletionHandler: is ASYNCHRONOUS
        //  so we must check again when the block executes if the handler is still not nil
        //  (another thread might have sent it already in a multiple-tasks-at-once implementation)
        if (![downloadTasks count]) {  // any more ticket downloads left?
            NSLog(@"********* TICKET DOWNLOAD COMPLETE***********");
            NSLog(@"%@", self.ticketsFromJitBit);
            
            // Now we need to write appropriate ticket info to core data
            
            // nope, then invoke flickrDownloadBackgroundURLSessionCompletionHandler (if it's still not nil)
            //                    void (^completionHandler)() = self.flickrDownloadBackgroundURLSessionCompletionHandler;
            //                    self.flickrDownloadBackgroundURLSessionCompletionHandler = nil;
            //                    if (completionHandler) {
            //                        completionHandler();
            //                    }
        }else{
            NSLog(@"Ticket download still ongoing");
        }// else other downloads going, so let them call this method when they finish
    }];
    //        }
}


@end
