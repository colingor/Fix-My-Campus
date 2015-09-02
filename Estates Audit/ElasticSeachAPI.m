//
//  ElasticSeachAPI.m
//  Estates Audit
//
//  Created by Colin Gormley on 02/09/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "ElasticSeachAPI.h"
#import "AppDelegate.h"


@interface ElasticSeachAPI ()

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSURLSession *elasticSearchSession;
@end

@implementation ElasticSeachAPI


NSString *const BASE_ELASTICSEARCH_URL = @"http://dlib-brown.edina.ac.uk/buildings/";


- (NSURLSession *)elasticSearchSession
{
    if (!_elasticSearchSession) {
        
        // another configuration option is backgroundSessionConfiguration (multitasking API required though)
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        
        _elasticSearchSession = [NSURLSession sessionWithConfiguration:configuration];
        
    }
    return _elasticSearchSession;
}


+ (ElasticSeachAPI *)sharedInstance
{
    // Return single instance
    static ElasticSeachAPI *_sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[ElasticSeachAPI alloc] init];
    });
    return _sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        // do any initialisation
    }
    return self;
}

-(AppDelegate *)appDelegate{
    if (!_appDelegate) {
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    
    return _appDelegate;
}

- (void)searchForBuildingsWithQueryJson: (NSDictionary *)queryJson
                 withCompletion:(void (^)(NSDictionary *locations))completion
{
    if([self.appDelegate isNetworkAvailable]){

        // Construct search URL
        NSURL *apiUrl = [NSURL URLWithString:[[BASE_ELASTICSEARCH_URL stringByAppendingString:@"_search?size=500"]
                                              stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
        [request setHTTPMethod:@"POST"];
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:queryJson
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        
        NSString *jsonString = [[NSString alloc] init];
        if (!jsonData) {
            NSLog(@"Got an error: %@", error);
        } else {
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            //        NSLog(@"jsonString %@", jsonString);
        }
        
        [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLSessionDataTask *task = [self.elasticSearchSession dataTaskWithRequest:request
                                                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                      // this handler is not executing on the main queue, so we can't do UI directly here
                                                                      if (!error) {
                                                                          NSDictionary *locations = [NSJSONSerialization JSONObjectWithData:data
                                                                                                                                    options:0
                                                                                                                                      error:NULL];
                                                                          // Process in completion callback
                                                                          completion(locations);
                                                              
                                                                      }
                                                                  }];
        [task resume];
    }else{
        // Display notification
        [self.appDelegate displayNetworkNotification];
    }
}
@end
