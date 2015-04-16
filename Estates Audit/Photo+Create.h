//
//  Photo+Create.h
//  Estates Audit
//
//  Created by Colin Gormley on 13/04/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//


#import "Photo.h"
@interface Photo (Create)

+ (Photo *)photoWithUrl:(NSString *)url
            fromReport:(Report *)report
 inManagedObjectContext:(NSManagedObjectContext *)context;

@end
