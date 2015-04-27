//
//  Report+Create.m
//  Estates Audit
//
//  Created by Colin Gormley on 13/04/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "Report+Create.h"
#import "Photo+Create.h"

@implementation Report (Create)

+ (Report *)reportFromReportInfo:(NSDictionary *)reportDictionary
         inManangedObjectContext:(NSManagedObjectContext *)context
{
    Report *report = nil;
    
    NSString *guid = (NSString *)[reportDictionary valueForKeyPath:@"guid"];
    
    if ([guid length]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Report"];
        request.predicate = [NSPredicate predicateWithFormat:@"guid = %@", guid];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || error || ([matches count] > 1 )) {
            // handle error
            NSLog(@"Something went wrong creating report with dectription: %@", guid);
        } else if (![matches count]) {
            //record guid doesn't exist for whatever reason just create a new one
            report = [Report insertNewObjectFromDict:reportDictionary inManagedContext:context];
            
        } else {
            report = [matches lastObject];
        }
    } else {
        report = [Report insertNewObjectFromDict:reportDictionary inManagedContext:context];
        
    }
    
    return report;
}

+(Report *)  insertNewObjectFromDict:(NSDictionary *)reportDictionary inManagedContext:(NSManagedObjectContext *)context {
    Report * report = [NSEntityDescription insertNewObjectForEntityForName:@"Report"
                                                    inManagedObjectContext:context];
    report.loc_desc = (NSString *)[reportDictionary valueForKeyPath:@"loc_desc"];
    report.lon = (NSNumber *)[reportDictionary valueForKeyPath:@"lon"];
    report.lat = (NSNumber *)[reportDictionary valueForKeyPath:@"lat"];
    report.status = (NSString *)[reportDictionary valueForKeyPath:@"status"];
    NSUUID  *UUID = [NSUUID UUID];
    NSString* stringUUID = [UUID UUIDString];
    report.guid = stringUUID;
    return report;
}

+(NSArray *) allReportsInManagedObjectContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Report"];
    
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    if(error){
        NSLog(@"%@",[error localizedDescription]);
        return [[NSArray alloc] init];
    }
    return matches;
}
@end
