//
//  LocationViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 26/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import "LocationViewController.h"
@import MapKit;
@interface LocationViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;


@end

@implementation LocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = NO;
    [self.mapView setDelegate:self];
    [self.mapView setShowsUserLocation:YES];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    
   // zoom to region containing the user location
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
    
    // add the annotation
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = userLocation.coordinate;
    point.title = @"The Location";
    point.subtitle = @"Sub-title";
    [self.mapView addAnnotation:point];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
