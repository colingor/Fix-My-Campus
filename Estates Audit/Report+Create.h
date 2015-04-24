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

         
+(NSArray *) allReportsInManagedObjectContext:(NSManagedObjectContext *)context;

@end
