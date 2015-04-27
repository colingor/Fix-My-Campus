//
//  Photo+Create.m
//  Estates Audit
//
//  Created by Colin Gormley on 13/04/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "Photo+Create.h"
#import "Report+Create.h"

@implementation Photo (Create)

+ (Photo *)photoWithUrl:(NSString *)url
            fromReport:(Report *)report
 inManagedObjectContext:(NSManagedObjectContext *)context
{
    Photo *photo = nil;
    
    if ([url length]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
        request.predicate = [NSPredicate predicateWithFormat:@"url = %@ && report.guid = %@", url, report.guid];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || ([matches count] > 1)) {
            // handle error
        } else if (![matches count]) {
            photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo"
                                                         inManagedObjectContext:context];
            photo.url = url;
            photo.report = report;
            
            NSLog(@"+ Photo created: %@", photo.url);
        } else {
            photo = [matches lastObject];
        }
    }
    
    return photo;
    
    return nil;
}
    


@end
