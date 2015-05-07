//
//  Report.h
//  Estates Audit
//
//  Created by Colin Gormley on 24/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Report : NSManagedObject

@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * lon;
@property (nonatomic, retain) NSString * loc_desc;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * guid;
@property (nonatomic, retain) NSSet *photos;
@property (nonatomic, retain) NSNumber * ticket_id;
@end

@interface Report (CoreDataGeneratedAccessors)

- (void)addPhotosObject:(NSManagedObject *)value;
- (void)removePhotosObject:(NSManagedObject *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

@end
