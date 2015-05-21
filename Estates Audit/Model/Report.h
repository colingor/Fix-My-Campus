//
//  Report.h
//  Estates Audit
//
//  Created by Colin Gormley on 15/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Comment, Photo;

@interface Report : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSDate * issue_date;
@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSString * loc_desc;
@property (nonatomic, retain) NSNumber * lon;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSNumber * ticket_id;
@property (nonatomic, retain) NSNumber * is_updated; 
@property (nonatomic, retain) NSSet *photos;
@property (nonatomic, retain) NSSet *comments;
@end

@interface Report (CoreDataGeneratedAccessors)

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end
