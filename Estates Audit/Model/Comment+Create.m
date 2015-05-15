//
//  Comment+Create.m
//  Estates Audit
//
//  Created by Colin Gormley on 15/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "Comment+Create.h"
#import "Report.h"

@implementation Comment (Create)

+ (Comment *)commentWithBody:(NSString *)body
                      onDate:(NSDate *)date
                  fromReport:(Report *)report
      inManagedObjectContext:(NSManagedObjectContext *)context
{
    Comment *comment = nil;
    
    if ([body length]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Comment"];
        request.predicate = [NSPredicate predicateWithFormat:@"body = %@ && report.ticket_id = %@ && date = %@", body, report.ticket_id, date];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || ([matches count] > 1)) {
            // handle error
        } else if (![matches count]) {
            comment = [NSEntityDescription insertNewObjectForEntityForName:@"Comment"
                                                  inManagedObjectContext:context];
            comment.date = date;
            comment.body = body;
            comment.report = report;
            
            NSLog(@"+ Comment created for report: %@", report.ticket_id);
        } else {
            comment = [matches lastObject];
        }
    }
    
    return comment;
}
@end
