//
//  CustomAnnotation.m
//  Estates Audit
//
//  Created by Colin Gormley on 21/08/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "CustomMKAnnotation.h"

@implementation CustomMKAnnotation

@synthesize coordinate = _coordinate;
@synthesize buildingId = _buildingId;
@synthesize properties = _properties;
@synthesize title = _title;
@synthesize subtitle = _subtitle;

- (id)initWithLocation:(CLLocationCoordinate2D)coord
{
    self = [super init];
    if (self) {
        self.coordinate = coord;
    }
    return self;
}


- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    [self willChangeValueForKey:@"coordinate"];
    _coordinate = newCoordinate;
    [self didChangeValueForKey:@"coordinate"];
    
}

- (CLLocationCoordinate2D)coordinate
{
    return _coordinate;
}

- (void)setBuildingId:(NSString *)buildingId
{
    [self willChangeValueForKey:@"buildingId"];
    _buildingId = buildingId;
    [self didChangeValueForKey:@"buildingId"];
}

- (NSString *)buildingId
{
    return _buildingId;
}

- (void)setProperties:(NSDictionary *)properties
{
    [self willChangeValueForKey:@"properties"];
    _properties = properties;
    [self didChangeValueForKey:@"properties"];
}

- (NSDictionary *)properties
{
    return _properties;
}

- (void)setTitle:(NSString *)title
{
    if (_title != title) {
        [self willChangeValueForKey:@"title"];
        _title = title;
        [self didChangeValueForKey:@"title"];
    }
}

- (NSString *)title
{
    return _title;
}

- (NSString *)subtitle
{
    return _subtitle;
}

- (void)setSubtitle:(NSString *)subtitle
{
    if (_subtitle != subtitle) {
        [self willChangeValueForKey:@"subtitle"];
        _subtitle = subtitle;
        [self didChangeValueForKey:@"subtitle"];
    }
}





@end
