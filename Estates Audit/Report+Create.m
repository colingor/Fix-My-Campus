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
    
//    NSString *ticketId = (NSString *)[reportDictionary valueForKeyPath:@"ticket_id"];
    
//    NSNumber *myNumber = [numberFromString:[reportDictionary valueForKeyPath:@"ticket_id"]];
//    NSNumber *ticketId = @([[reportDictionary valueForKeyPath:@"ticket_id"] floatValue]);
    NSNumber *ticketId = [reportDictionary valueForKeyPath:@"ticket_id"];

    
//    if ([guid length]) {
    if (ticketId) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Report"];
//        request.predicate = [NSPredicate predicateWithFormat:@"guid = %@", guid];
        request.predicate = [NSPredicate predicateWithFormat:@"ticket_id = %@", ticketId];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || error || ([matches count] > 1 )) {
            // handle error
            NSLog(@"Something went wrong creating report : %@", ticketId);
//             NSLog(@"Something went wrong creating report : %@", guid);
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
    report.desc = (NSString *)[reportDictionary valueForKeyPath:@"desc"];
    report.lon = (NSNumber *)[reportDictionary valueForKeyPath:@"lon"];
    report.lat = (NSNumber *)[reportDictionary valueForKeyPath:@"lat"];
    report.status = (NSString *)[reportDictionary valueForKeyPath:@"status"];
    
    
    NSNumber *ticketId = [reportDictionary valueForKeyPath:@"ticket_id"];
    if(ticketId > 0){
        report.ticket_id = ticketId;
    }else{
        // TODO - needs a more robust solution - remote chance that a ticket id could have the same id
        NSInteger rdmNumber = arc4random()%500;
        report.ticket_id = [NSNumber numberWithInt: rdmNumber];
        
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



+ (void)loadReportsFromJitBitDictionary:(NSDictionary *)ticketsFromJitBit
                      withCustomFields :(NSDictionary *)ticketsCustomFieldsFromJitBit
               intoManagedObjectContext:(NSManagedObjectContext *)context
{
    
    // For each ticket, add a report to Core Data
    for(id key in ticketsFromJitBit){
        
        NSDictionary *ticket = [ticketsFromJitBit objectForKey:key];
        
        if(ticket){
            
            NSString *status = [ticket valueForKey:@"Status"];
            NSString *ticketId = [ticket valueForKey:@"TicketID"];
            
            // Create new report to add to Core Data
            NSMutableDictionary *report = [NSMutableDictionary dictionary];

            [report setValue: status forKey:@"status"];
            [report setValue: ticketId forKey:@"ticket_id"];
            
            NSArray *customFields = [ticketsCustomFieldsFromJitBit valueForKey:key];
         
            
            for (id customField in customFields) {
                // do something with object
                NSNumber *fieldId = [customField valueForKey:@"FieldID"];
                NSString *value = [customField valueForKey:@"Value"];
                
                //description
                if([fieldId isEqualToNumber: @9434]){
                    if(![value isKindOfClass:[NSNull class]]){
                        [report setValue: value forKey:@"desc"];

                    }
                }
                // Location Description
                else if ([fieldId isEqualToNumber: @9435]){
                    if(![value isKindOfClass:[NSNull class]]){
                        [report setValue: value forKey:@"loc_desc"];
                        
                    }
                }
                // Location coords
                else if ([fieldId isEqualToNumber: @9450]){
                    if(![value isKindOfClass:[NSNull class]]){
                        NSArray* coords = [value componentsSeparatedByString:@" "];
                        NSNumber *lat = @([coords[0] floatValue]);
                        NSNumber *lon = @([coords[1] floatValue]);
                        [report setValue: lat forKey:@"lat"];
                        [report setValue: lon forKey:@"lon"];
                        
                    }
                }
            }
            
            
            [self reportFromReportInfo:report inManangedObjectContext:context];
        }
    }
    
    // Save just to be sure
    [context save:NULL];
}


@end
