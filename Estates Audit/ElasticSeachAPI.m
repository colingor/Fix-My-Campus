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


- (NSMutableURLRequest *)setupRequest:(NSURL *)apiUrl queryJson:(NSDictionary *)queryJson
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
    
    
    if(queryJson){
        
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
    }else{
        [request setHTTPMethod:@"GET"];
    }
    
    
    return request;
}

-(BOOL)checkNetworkAvailablityAndDisplayNotification{
    
    if(![self.appDelegate isNetworkAvailable]){
        // Display notification
        [self.appDelegate displayNetworkNotification];
        return NO;
    }
    return YES;
}


- (void)searchForBuildingsWithQueryJson: (NSDictionary *)queryJson
                         withCompletion:(void (^)(NSMutableDictionary *locations))completion
{
    if([self checkNetworkAvailablityAndDisplayNotification]){

        // Construct search URL
        NSURL *apiUrl = [NSURL URLWithString:[[BASE_ELASTICSEARCH_URL stringByAppendingString:@"_search?size=500"]
                                              stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSMutableURLRequest *request = [self setupRequest:apiUrl queryJson:queryJson];
        
        
        
        NSURLSessionDataTask *task = [self.elasticSearchSession dataTaskWithRequest:request
                                                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                      // this handler is not executing on the main queue, so we can't do UI directly here
                                                                      if (!error) {
                                                                          
                                                                          // Note results are mutable here in case we add a new facility
                                                                          NSMutableDictionary *locations = [NSJSONSerialization JSONObjectWithData:data
                                                                                                                                           options:NSJSONReadingMutableContainers
                                                                                                                                             error:NULL];
                                                                          // Turn off network activity
                                                                          [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                                                          
                                                                          // Process in completion callback
                                                                          completion(locations);
                                                              
                                                                      }
                                                                  }];
        // Turn on network activity
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [task resume];
    }
}


- (void)searchForBuildingWithId: (NSString *)buildingId
                 withCompletion:(void (^)(NSMutableDictionary *source))completion
{
    if([self checkNetworkAvailablityAndDisplayNotification]){
        
        
        NSLog(@"Searching for %@", buildingId);
        // Construct search URL
        NSURL *apiUrl = [NSURL URLWithString:[[NSString stringWithFormat:@"%@building/%@", BASE_ELASTICSEARCH_URL, buildingId]
                                              stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSMutableURLRequest *request = [self setupRequest:apiUrl queryJson:nil];
    
        NSURLSessionDataTask *task = [self.elasticSearchSession dataTaskWithRequest:request
                                                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                      // this handler is not executing on the main queue, so we can't do UI directly here
                                                                      if (!error) {
                                                                          
                                                                          // Note results are mutable here in case we add a new facility
                                                                          NSMutableDictionary *buildingInfo = [NSJSONSerialization JSONObjectWithData:data
                                                                                                                                           options:NSJSONReadingMutableContainers
                                                                                                                                             error:NULL];
                                                                          
                                                                          NSMutableDictionary * source = [buildingInfo valueForKey:@"_source"];
                                                                          // Turn off network activity
                                                                          [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                                                          
                                                                          // Process in completion callback
                                                                          completion(source);
                                                                          
                                                                      }
                                                                  }];
        // Turn on network activity
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [task resume];
    }
}



- (void)postBuildingFacilityToBuilding:(NSString *) buildingId
                         withQueryJson:(NSDictionary *)queryJson
                        withCompletion:(void (^)(NSDictionary *result))completion{
    
   /*
    Need to post something of the form:
    curl -XPOST "http://dlib-brown.edina.ac.uk:9200/buildings/building/3" -d'
    {
        "geometry": {
            "type": "Point",
            "location": [
                         -3.1952404975891113,
                         55.94966839561511
                         ]
        },
        "type": "Feature",
        "properties": {
            "information": [
                            {
                                "items": [
                                          {
                                              "notes": "This is to test the notes",
                                              "image": "url",
                                              "type": "type",
                                              "description": "d"
                                          },
                                          {
                                              "notes": "This is to test the notes 2",
                                              "image": "url",
                                              "type": "type",
                                              "description": "d"
                                          }
                                          ],
                                "area": "General"
                            }
                            ],
            "image": "url",
            "title": "New College",
            "subtitle": "1 Mound Place  Edinburgh EH1 2LU",
            "area": [
                     "Central area"
                     ]
        }
    }'*/
    
    if([self checkNetworkAvailablityAndDisplayNotification]){
        
        NSLog(@"Posting to %@", buildingId);
        
        NSURL *apiUrl = [NSURL URLWithString:[[NSString stringWithFormat:@"%@building/%@", BASE_ELASTICSEARCH_URL, buildingId]
                                              stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSMutableURLRequest *request = [self setupRequest:apiUrl queryJson:queryJson];
        
        NSURLSessionDownloadTask *task = [self.elasticSearchSession downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"%@",error);
            }else{
                
                NSDictionary *result;
                NSData *locationJSONData = [NSData dataWithContentsOfURL:location];
                if (locationJSONData) {
                    result = [NSJSONSerialization JSONObjectWithData:locationJSONData
                                                             options:0
                                                               error:NULL];
                    // Turn off network activity
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

                    completion(result);
                }
            }
            
        }];
        
        // Turn on network activity
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

        [task resume];
    }
}

@end
