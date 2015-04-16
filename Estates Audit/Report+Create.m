//
//  Report+Create.m
//  Estates Audit
//
//  Created by Colin Gormley on 13/04/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "Report+Create.h"

@implementation Report (Create)

+ (Report *)reportFromReportInfo:(NSDictionary *)reportDictionary
               inManangedObjectContext:(NSManagedObjectContext *)context
{
    Report *report = nil;
    
    NSString *desc = (NSString *)[reportDictionary valueForKeyPath:@"desc"];
    
    if ([desc length]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Report"];
        request.predicate = [NSPredicate predicateWithFormat:@"desc = %@", desc];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || error || ([matches count] > 1 )) {
            // handle error
            NSLog(@"Something went wrong creating report with dectription: %@", desc);
        } else if (![matches count]) {
            report = [NSEntityDescription insertNewObjectForEntityForName:@"Report"
                                                    inManagedObjectContext:context];
            report.desc = desc;
          
        } else {
            report = [matches lastObject];
        }
    }
    
    return report;
}
@end
