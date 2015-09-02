//
//  ElasticSeachAPI.h
//  Estates Audit
//
//  Created by Colin Gormley on 02/09/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ElasticSeachAPI : NSObject

+ (ElasticSeachAPI *)sharedInstance;

- (void)searchForBuildingsWithQueryJson: (NSDictionary *)queryJson
                         withCompletion:(void (^)(NSDictionary *locations))completion;

@end
