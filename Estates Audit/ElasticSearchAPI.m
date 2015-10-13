//
//  ElasticSeachAPI.m
//  Estates Audit
//
//  Created by Colin Gormley on 02/09/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "ElasticSearchAPI.h"
#import "AppDelegate.h"
#import <AssetsLibrary/AssetsLibrary.h>


@interface ElasticSearchAPI ()

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSURLSession *elasticSearchSession;
@end

@implementation ElasticSearchAPI


NSString *const BASE_ELASTICSEARCH_URL = @"http://dlib-brown.edina.ac.uk/buildings/";
NSString *const BASE_ESTATES_API_URL = @"http://dlib-brown.edina.ac.uk/api/";

- (NSURLSession *)elasticSearchSession
{
    if (!_elasticSearchSession) {
        
        // another configuration option is backgroundSessionConfiguration (multitasking API required though)
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        
        _elasticSearchSession = [NSURLSession sessionWithConfiguration:configuration];
        
    }
    return _elasticSearchSession;
}


+ (ElasticSearchAPI *)sharedInstance
{
    // Return single instance
    static ElasticSearchAPI *_sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[ElasticSearchAPI alloc] init];
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


- (void)getAllTypesWithCompletion:(void (^)(NSMutableArray *types))completion{
    
    // List of distinct types using the type raw field (so results are not tokenised)
    [self getAggregationsForCustomField:@"properties.information.items.type.raw" withCompletion:^(NSMutableArray *types) {
        completion(types);
    }];

}

- (void)getAllAreasWithCompletion:(void (^)(NSMutableArray *areas))completion{
    
    // List of distinct areas using the area raw field (so results are not tokenised)
    [self getAggregationsForCustomField:@"properties.information.area.raw" withCompletion:^(NSMutableArray *areas) {
        completion(areas);
    }];
    
}

- (void)getAggregationsForCustomField: (NSString *)customField
                         withCompletion:(void (^)(NSMutableArray *aggregations))completion{
    
    if([self checkNetworkAvailablityAndDisplayNotification]){
        
        NSURL *apiUrl = [NSURL URLWithString:[[NSString stringWithFormat:@"%@_search", BASE_ELASTICSEARCH_URL]
                                              stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        
        // We set size = 0 to avoid returning any acutal hits - we're just interested in the aggregations
        NSDictionary *queryJson = @{
                                    @"aggs":@{
                                            @"aggregation":@{
                                                    @"terms":@{@"field" : customField, @"order":@{@"_term":@"asc"}},
                                                   
                                                    }
                                            },
                                    @"size":@"0"
                                    };
        
        NSMutableURLRequest *request = [self setupRequest:apiUrl queryJson:queryJson];
        
        NSURLSessionDataTask *task = [self.elasticSearchSession dataTaskWithRequest:request
                                                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                      // this handler is not executing on the main queue, so we can't do UI directly here
                                                                      if (!error) {
                                                                          
                                                                          // Note results are mutable here in case we add a new facility
                                                                          NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:data
                                                                                                                                           options:0
                                                                                                                                             error:NULL];
                                                                          
                                                                          // the buckets element contains the information we are interested in
                                                                          NSArray *aggregations = [resultDict valueForKeyPath:@"aggregations.aggregation.buckets"];
                                                                          
                                                                          NSMutableArray *results = [NSMutableArray array];
                                                                          for (NSDictionary *item in aggregations) {
                                                                               [results addObject:item[@"key"]];
                                                                          }
                                                                          // Turn off network activity
                                                                          [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                                                          
                                                                          
                                                                          // Remove any blank values from results
                                                                          [results removeObject:@""];
                                                                          
                                                                          // Process in completion callback
                                                                          completion(results);
                                                                          
                                                                      }
                                                                  }];
        // Turn on network activity
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [task resume];
    }
    
}

- (void)searchForBuildingsNearCoordinate: (NSDictionary *)locationDict
                          withCompletion:(void (^)(NSMutableDictionary *locations))completion{
    
    [self searchForBuildingsWithDict:locationDict withCompletion:^(NSMutableDictionary *locations) {
        completion(locations);
    }];
}


- (void)searchForBuildingsWithinBoundingBox: (NSDictionary *)bb
                         withCompletion:(void (^)(NSMutableDictionary *locations))completion
{
    [self searchForBuildingsWithDict:bb withCompletion:^(NSMutableDictionary *locations) {
        completion(locations);
    }];
}


- (void)searchForBuildingsWithDict: (NSDictionary *)dict
                             withCompletion:(void (^)(NSMutableDictionary *locations))completion{
    if([self checkNetworkAvailablityAndDisplayNotification]){
        
        // Construct search URL
        NSURL *apiUrl = [NSURL URLWithString:[[BASE_ELASTICSEARCH_URL stringByAppendingString:@"_search?size=500"]
                                              stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSMutableDictionary *queryJson =  [[NSMutableDictionary alloc] init];
        NSDictionary *filterDict = [[NSDictionary alloc] init];

        
        
        NSDictionary *queryDict = @{ @"query" : @{ @"match_all": @{}} };
        
        // Construct appropriate search json query
        if([dict objectForKey:@"top_left"]){
            // Bounding box search
            
            filterDict = @{@"filter" : @{ @"geo_bounding_box": @{@"location":dict }} };
            
        }else{
            // Distance search
            
            filterDict = @{@"filter" : @{
                                   @"geo_distance": @{
                                           @"distance":@"0.5km",
                                           @"location":dict
                                           }
                                   }
                           };
        }
        
        [queryJson addEntriesFromDictionary:queryDict];
        [queryJson addEntriesFromDictionary:filterDict];

        
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
                                                                          // Turn off network activity
                                                                          [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                                                          
                                                                          // Process in completion callback
                                                                          completion(buildingInfo);
                                                                          
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




- (void)postImageContainerToEstatesAPIForBuilding:(NSString *) buildingId
                        withCompletion:(void (^)(NSDictionary *result))completion{
    
    
    if([self checkNetworkAvailablityAndDisplayNotification]){
        
        NSLog(@"Posting to %@", buildingId);
        
        NSURL *apiUrl = [NSURL URLWithString:[[NSString stringWithFormat:@"%@images", BASE_ESTATES_API_URL]
                                              stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSDictionary *queryJson = @{@"name" : buildingId};
        
        NSMutableURLRequest *request = [self setupRequest:apiUrl queryJson:queryJson];
        
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        NSURLSessionDownloadTask *task = [self.elasticSearchSession downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"%@",error);
                completion(nil);
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

- (void)postImageToEstatesAPI:(NSString *)imageUrl
                forBuildingId:(NSString *)buildingId
                inArea:(NSString *)facilityArea
               withCompletion:(void (^)(NSDictionary *result))completion{
    
    
    
    if([self checkNetworkAvailablityAndDisplayNotification]){
        
        
        // Create image container - if already exists this request will do no harm
        [self postImageContainerToEstatesAPIForBuilding:buildingId withCompletion:^(NSDictionary *result) {
            
            
            NSURL *apiUrl = [NSURL URLWithString:[[NSString stringWithFormat:@"%@images/%@/upload", BASE_ESTATES_API_URL, buildingId]
                                                  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            
            NSMutableURLRequest *request = [self setupRequest:apiUrl queryJson:nil];
            [request setHTTPMethod:@"POST"];
            
            
            NSMutableData *body = [NSMutableData data];
            
            // the boundary string : a random string, that will not repeat in post data, to separate post data fields.
            NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
            
            // set Content-Type in HTTP header
            NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BoundaryConstant];
            [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
            
      
            
            NSURL *assetUrl = [NSURL URLWithString:[imageUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
       
            
            if([[assetUrl scheme] isEqualToString:@"assets-library"]){
                
                ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset){
                    ALAssetRepresentation *rep = [myasset defaultRepresentation];
                    CGImageRef iref = [rep fullResolutionImage];
                    
                    if (iref) {
                        
                        UIImage *image = [UIImage imageWithCGImage:iref];
                        
                        CGImageRef cgRef = image.CGImage;
                        
                        // Have to get the orientation directly from the exif data as the orientation
                        // from image.imageOrientation is always UIImageOrientationUp for some reason.
                        NSDictionary *metadata = myasset.defaultRepresentation.metadata;
                        NSDictionary *imageMetadata = [[NSMutableDictionary alloc] initWithDictionary:metadata];
                        NSNumber *orientation = [imageMetadata valueForKey:@"Orientation"];
                        
                        NSLog(@"Orientation : %@", orientation);
                        
                        // We have to adjust the orientation in certain cases by creating a new image that has
                        // been rotated properly.
                        if([orientation isEqualToNumber:[NSNumber numberWithLong:6]]){
                            image = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationRight];
                        }else if([orientation isEqualToNumber:[NSNumber numberWithLong:3]]){
                            image = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationDown];
                        }else if([orientation isEqualToNumber:[NSNumber numberWithLong:8]]){
                            image = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationLeft];
                        }
                       
                        int timestamp = [[NSDate date] timeIntervalSince1970];
                        NSString *imageFileName = [NSString stringWithFormat:@"%@_%d.JPG",facilityArea,timestamp];
                        
                        NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
                        // add image data
                        
                        if (imageData) {
                            [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
                            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", imageFileName, imageFileName] dataUsingEncoding:NSUTF8StringEncoding]];
                            [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                            [body appendData:imageData];
                            [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
                        }
                        
                        [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
                        
                        // setting the body of the post to the reqeust
                        [request setHTTPBody:body];
                        
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
                                    NSLog(@"Posted image to EstatesAPI");
                                    
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
                };
                
                ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
                [
                 assetslibrary assetForURL:assetUrl
                 resultBlock:resultblock
                 failureBlock: ^(NSError *myerror)
                 {
                     NSLog(@"Can't get image - %@",[myerror localizedDescription]);
                 }];
                
            }
        }];
    }
}

@end
