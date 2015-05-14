//
//  Report+SectionIdentifier.m
//  Estates Audit
//
//  Created by Colin Gormley on 14/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "Report+SectionIdentifier.h"

@implementation Report (SectionIdentifier)

// Return a readable date for section headers.
- (NSString *)sectionIdentifier
{
    return [NSDateFormatter localizedStringFromDate:self.issue_date
                                          dateStyle:NSDateFormatterLongStyle
                                          timeStyle:NSDateFormatterNoStyle];
}

@end
