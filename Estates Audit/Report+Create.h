//
//  Report+Create.h
//  Estates Audit
//
//  Created by Colin Gormley on 13/04/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//


#import "Report.h"

@interface Report (Create)

+ (Report *)reportFromReportInfo:(NSDictionary *)reportDictionary
         inManangedObjectContext:(NSManagedObjectContext *)context;

+(Report *)  insertNewObjectFromDict:(NSDictionary *)reportDictionary inManagedContext:(NSManagedObjectContext *)context ;


+(NSArray *) allReportsInManagedObjectContext:(NSManagedObjectContext *)context;

+ (NSDate *)extractJitBitDate:(NSString *)jitBitDateStr;

+ (void)loadReportsFromJitBitDictionary:(NSDictionary *)ticketsFromJitBit
                      withCustomFields :(NSDictionary *)ticketsCustomFieldsFromJitBit
               intoManagedObjectContext:(NSManagedObjectContext *)context;
@end
  