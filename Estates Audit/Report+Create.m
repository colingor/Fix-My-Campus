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
    
    //********* TODO ******** : Report needs a proper unique key, not the location description
    
    NSString *locDesc = (NSString *)[reportDictionary valueForKeyPath:@"loc_desc"];
    
    if ([locDesc length]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Report"];
        request.predicate = [NSPredicate predicateWithFormat:@"loc_desc = %@", locDesc];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || error || ([matches count] > 1 )) {
            // handle error
            NSLog(@"Something went wrong creating report with dectription: %@", locDesc);
        } else if (![matches count]) {
            report = [NSEntityDescription insertNewObjectForEntityForName:@"Report"
                                                    inManagedObjectContext:context];
            report.loc_desc = locDesc;
            report.lon = (NSNumber *)[reportDictionary valueForKeyPath:@"lon"];
            report.lat = (NSNumber *)[reportDictionary valueForKeyPath:@"lat"];
            report.status = (NSString *)[reportDictionary valueForKeyPath:@"status"];          
            
        } else {
            report = [matches lastObject];
        }
    }
    
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
