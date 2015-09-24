//
//  ElasticSeachAPI.h
//  Estates Audit
//
//  Created by Colin Gormley on 02/09/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ElasticSearchAPI : NSObject

+ (ElasticSearchAPI *)sharedInstance;

- (void)getAllTypesWithCompletion:(void (^)(NSMutableArray *aggregations))completion;

- (void)getAllAreasWithCompletion:(void (^)(NSMutableArray *aggregations))completion;

- (void)postBuildingFacilityToBuilding:(NSString *) buildingId
                         withQueryJson:(NSDictionary *)queryJson
                        withCompletion:(void (^)(NSDictionary *locations))completion;

- (void)searchForBuildingWithId: (NSString *)buildingId
                 withCompletion:(void (^)(NSMutableDictionary *source))completion;

- (void)searchForBuildingsWithinBoundingBox: (NSDictionary *)bb
                             withCompletion:(void (^)(NSMutableDictionary *locations))completion;

- (void)searchForBuildingsNearCoordinate: (NSDictionary *)locationDict
                          withCompletion:(void (^)(NSMutableDictionary *locations))completion;

- (void)postImageToEstatesAPI:(NSString *)imageUrl
                forBuildingId:(NSString *)buildingId
                       inArea:(NSString *)facilityArea
               withCompletion:(void (^)(NSDictionary *result))completion;

@end
