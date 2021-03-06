//
//  CustomAnnotation.h
//  Estates Audit
//
//  Created by Colin Gormley on 21/08/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <Foundation/Foundation.h>

@interface CustomMKAnnotation : NSObject <MKAnnotation>

@property (nonatomic, strong) NSString *buildingId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *imageUrl;

- (id)initWithLocation:(CLLocationCoordinate2D)coord;

@end



