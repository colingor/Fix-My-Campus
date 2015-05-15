//
//  Comment+Create.h
//  Estates Audit
//
//  Created by Colin Gormley on 15/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "Comment.h"

@interface Comment (Create)

+ (Comment *)commentWithBody:(NSString *)body
                      onDate:(NSDate *)date
             fromReport:(Report *)report
 inManagedObjectContext:(NSManagedObjectContext *)context;

@end
