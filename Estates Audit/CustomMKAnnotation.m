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
@synthesize source = _source;
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

- (BOOL)hasNestedBuildingInformation 
{
    if([[self.source valueForKeyPath:@"properties.information"] count] > 0){
        return YES;
    }
    return NO;
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

- (void)setSource:(NSDictionary *)source
{
    [self willChangeValueForKey:@"source"];
    _source = source;
    [self didChangeValueForKey:@"source"];
}

- (NSDictionary *)source
{
    return _source;
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
