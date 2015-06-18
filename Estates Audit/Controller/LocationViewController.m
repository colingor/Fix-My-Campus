//
//  LocationViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 26/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import "LocationViewController.h"
#import "LocationDetailsViewController.h"
#import "PictureViewController.h"
#import "Report+Create.h"
#import <CoreLocation/CoreLocation.h>
#import "GeoJSONSerialization.h"
#import "Photo+Create.h"
#import "CustomMKPointAnnotation.h"
#import "AppDelegate.h"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@import MapKit;
@interface LocationViewController () <MKMapViewDelegate, CLLocationManagerDelegate, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITextView *descriptionText;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL userSpecfiedLocation;
@property (strong, nonatomic) Report *report;
@property (strong, nonatomic) NSArray *locations;
@property (strong, nonatomic) MKPointAnnotation *locationPin;
@property (strong, nonatomic) NSMutableArray *locationAnnotations;
@property (strong, nonatomic) NSURLSession *elasticSearchSession;
@property (strong, nonatomic) AppDelegate *appDelegate;
@property (nonatomic, strong) NSString *encodedCredentials;

@end

@implementation LocationViewController



- (NSMutableArray *)locationAnnotations
{
    if (!_locationAnnotations){
        _locationAnnotations = [[NSMutableArray alloc] init];
    }
    
    return _locationAnnotations;
}


- (void)setLocationPin:(MKPointAnnotation *)locationPin
{
    if (!_locationPin) {
        _locationPin = locationPin;
    }
}

-(AppDelegate *)appDelegate{
    if (!_appDelegate) {
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    self.encodedCredentials  = [_appDelegate encodedCredentials];

    return _appDelegate;
}


- (NSURLSession *)elasticSearchSession
{
    if (!_elasticSearchSession) {
        
        // another configuration option is backgroundSessionConfiguration (multitasking API required though)
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSString *authValue = [self encodedCredentials];
        [configuration setHTTPAdditionalHeaders:@{@"Authorization": authValue}];
        
        _elasticSearchSession = [NSURLSession sessionWithConfiguration:configuration];
        
    }
    return _elasticSearchSession;
}



-(IBAction) unwindToMainMenu:(UIStoryboardSegue *)segue {
    if ([self reportDict]){
        if ([self report]){
            // delete existing photo if there is one
            for (Photo *photo in [self.report.photos allObjects]) {
                [[self managedObjectContext] deleteObject:photo];
            }
        }
        self.descriptionText.text = [self.reportDict valueForKey:@"loc_desc"];
        self.userSpecfiedLocation = YES;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.encodedCredentials = [self.appDelegate encodedCredentials];
    
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = NO;
    
    
    [self.mapView setDelegate:self];
    self.descriptionText.delegate = self;
    
    if (nil == self.locationManager)
        self.locationManager = [[CLLocationManager alloc] init];
    
    self.locationManager.delegate = self;
   
    // Set a movement threshold for new events.
    self.locationManager.distanceFilter = 20; // meters
    
    
    if(IS_OS_8_OR_LATER) {
        //[self.locationManager requestWhenInUseAuthorization];
        [self.locationManager requestAlwaysAuthorization];
        [self.locationManager startUpdatingLocation];
    }
    [self.mapView setShowsUserLocation:YES];
    //[self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
   
    // Declare empty dict we can add report info to
    _reportDict = [NSMutableDictionary dictionary];
    
    // Use this to determine whether user overrides location from locationManager by movin pin
    _userSpecfiedLocation = NO;
    
    // load estates buildings information from geojson file and draw on map view
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"uoe-estates-buildings" withExtension:@"json"];
    NSData *data = [NSData dataWithContentsOfURL:URL];
    NSDictionary *geoJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    self.locations = [geoJSON valueForKeyPath:@"features"];
    
    NSArray *shapes = [GeoJSONSerialization shapesFromGeoJSONFeatureCollection:geoJSON error:nil];
    
    for (MKShape *shape in shapes) {
        if ([shape isKindOfClass:[MKPointAnnotation class]]) {
            [self.mapView addAnnotation:shape];
        } else if ([shape conformsToProtocol:@protocol(MKOverlay)]) {
            [self.mapView addOverlay:(id <MKOverlay>)shape];
        }
    }
    
    
    //Load buildings from estates json
    NSData *estatesData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"estates" withExtension:@"json"]];
    NSDictionary *estatesGeoJSON = [NSJSONSerialization JSONObjectWithData:estatesData options:0 error:nil];
    NSArray *locs = [estatesGeoJSON valueForKeyPath:@"locations"];
    
    /*NSMutableArray *locationAnnotations = [[NSMutableArray alloc] init];
    
    for(id location in locs){

        NSString * name = [location valueForKey:@"name"];
        NSString * lat = [location valueForKey:@"latitude"];
        NSString * lon = [location valueForKey:@"longitude"];
        NSString * address = [location valueForKey:@"address"];
        
        //add the annotation
        CustomMKPointAnnotation *point = [[CustomMKPointAnnotation alloc] init];
       
        CLLocationCoordinate2D coord;
        coord.latitude = [lat floatValue];
        coord.longitude = [lon floatValue];
        
        point.coordinate = coord;
        point.title = name;
        point.subtitle = address;
        point.hierarchical = YES;
        
        [locationAnnotations addObject:point];
        [self.locationAnnotations addObject:point];
    }
    
    [self.mapView addAnnotations:locationAnnotations];*/
    
    // Set up listener to move location pin on long press
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.0; //user needs to press for 1 second
    [self.mapView addGestureRecognizer:lpgr];
   
    self.tableView.hidden = YES;
    
    // Set up tableView delegates
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // If voiceover is on, display the list rather than the map
    if(UIAccessibilityIsVoiceOverRunning()){
        [self.segmentedController setSelectedSegmentIndex:1];
        self.mapView.hidden = YES;
        self.tableView.hidden = NO;
    }
    
}

- (BOOL)mapViewRegionDidChangeFromUserInteraction
{
    UIView *view = self.mapView.subviews.firstObject;
    //  Look through gesture recognizers to determine whether this region change is from user interaction
    for(UIGestureRecognizer *recognizer in view.gestureRecognizers) {
        if(recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateEnded) {
            return YES;
        }
    }
    
    return NO;
}

static BOOL mapChangedFromUserInteraction = NO;

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    mapChangedFromUserInteraction = [self mapViewRegionDidChangeFromUserInteraction];
    
    if (mapChangedFromUserInteraction) {
        // user changed map region
        // Send call to ElasticSearch to update annotations
        [self displayBuildingsInBoundingBox];
        
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (mapChangedFromUserInteraction) {
        // user changed map region
    }
}



-(void)displayBuildingsInBoundingBox{
    
    MKMapRect mRect = self.mapView.visibleMapRect;
    NSMutableDictionary *bb = [self getBoundingBox:mRect];
    
    NSString *apiStr = @"http://dlib-goatfell.ucs.ed.ac.uk:9200/estates/_search?size=500";
    
    NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
    [request setHTTPMethod:@"POST"];


    NSDictionary *queryDict = @{ @"query" : @{ @"match_all": @{}} };
    NSDictionary *filterDict = @{@"filter" : @{ @"geo_bounding_box": @{@"location":bb }} };
    
    NSMutableDictionary *jsonPayload =  [[NSMutableDictionary alloc] init];
   
    [jsonPayload addEntriesFromDictionary:queryDict];
    [jsonPayload addEntriesFromDictionary:filterDict];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonPayload
                                                       options:NSJSONWritingPrettyPrinted 
                                                         error:&error];

    NSString *jsonString = [[NSString alloc] init];
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//        NSLog(@"jsonString %@", jsonString);
    }
    
    [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *task = [self.elasticSearchSession dataTaskWithRequest:request
                                                              completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      // this handler is not executing on the main queue, so we can't do UI directly here
                                      if (!error) {
                                          NSDictionary *locations = [NSJSONSerialization JSONObjectWithData:data
                                                                                                    options:0
                                                                                                      error:NULL];
                                          
                                          NSArray *hits = [[locations valueForKey:@"hits"] valueForKey:@"hits"];
                                     
                                         // localAnnotations used to populate building list table
                                          [self.locationAnnotations removeAllObjects];
                 
                                          for (id hit in hits){
                                              NSDictionary * location = [hit valueForKey:@"_source"];
                                              
                                              NSString * name = [location valueForKey:@"name"];
                                              NSString * lat = [location valueForKey:@"latitude"];
                                              NSString * lon = [location valueForKey:@"longitude"];
                                              NSString * address = [location valueForKey:@"address"];
                                              
                                              // Check if annotation already exists on map
                                              NSArray *existingAnnotations = self.mapView.annotations;
                                              
                                              BOOL found = NO;
                                              
                                              for(MKPointAnnotation *existing in existingAnnotations){
                                                  
                                                  NSString *existingTitle = existing.title;
                                              
                                                  NSNumber *existinglatNumber = [NSNumber numberWithDouble:existing.coordinate.latitude];
                                                  NSNumber *newlatNumber = @([lat floatValue]);
                                                  
                                                  NSNumber *existinglonNumber = [NSNumber numberWithDouble:existing.coordinate.longitude];
                                                  NSNumber *newlonNumber = @([lon floatValue]);
                                                  
                                                  if([existingTitle isEqualToString:name] &&
                                                     ([existinglatNumber isEqualToNumber:newlatNumber]) &&
                                                     ([existinglonNumber isEqualToNumber:newlonNumber])){
                                                      found = YES;
                                                      break;
                                                  }
                                              }
                                              
                                              CustomMKPointAnnotation *point = [[CustomMKPointAnnotation alloc] init];
                                              
                                              CLLocationCoordinate2D coord;
                                              coord.latitude = [lat floatValue];
                                              coord.longitude = [lon floatValue];
                                              
                                              point.coordinate = coord;
                                              point.title = name;
                                              point.subtitle = address;
                                              point.hierarchical = YES;
                                              
                                              // Add to the building list
                                              [self.locationAnnotations addObject:point];
                                              
                                              if(!found){
                                                  [self.mapView addAnnotation:point];
                                              }
                                          }
                                          
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              [self.tableView reloadData];
                                          });
                                      }
                                  }];
    [task resume];
    
}




#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.locationAnnotations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"BuildingCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
    }
    
    CustomMKPointAnnotation *point = [self.locationAnnotations objectAtIndex:indexPath.row];
    cell.textLabel.text = point.title;
    cell.detailTextLabel.text  = point.subtitle;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CustomMKPointAnnotation *point = [self.locationAnnotations objectAtIndex:indexPath.row];
    
    // Find the corresponding annotation on the map as point won't be the same instance
    for(MKPointAnnotation *existing in self.mapView.annotations){
        
        NSString *existingTitle = existing.title;
        
        NSNumber *existinglatNumber = [NSNumber numberWithDouble:existing.coordinate.latitude];
        NSNumber *newlatNumber = [NSNumber numberWithDouble:point.coordinate.latitude];
        
        NSNumber *existinglonNumber = [NSNumber numberWithDouble:existing.coordinate.longitude];
        NSNumber *newlonNumber = [NSNumber numberWithDouble:point.coordinate.longitude];
        
        if([existingTitle isEqualToString:point.title] &&
           ([existinglatNumber isEqualToNumber:newlatNumber]) &&
           ([existinglonNumber isEqualToNumber:newlonNumber])){
            
            NSMutableString *text;
            text = [self generateDescriptionFromAnnotation:point];
            self.descriptionText.text = text;
            
            self.locationPin.coordinate = existing.coordinate;
            
            CLLocationDegrees lat = existing.coordinate.latitude;
            CLLocationDegrees lon = existing.coordinate.longitude;
            
            [self.reportDict setValue:[NSNumber numberWithDouble:lat] forKey:@"lat"];
            [self.reportDict setValue:[NSNumber numberWithDouble:lon] forKey:@"lon"];
            
            // Centre map on point
            MKCoordinateRegion region = { { 0.0, 0.0 }, { 0.0, 0.0 } };
            region.center.latitude = lat;
            region.center.longitude = lon;
            region.span.latitudeDelta = 0.0003;
            region.span.longitudeDelta = 0.0003;
            [self.mapView setRegion:region animated:YES];
            
            [self.mapView selectAnnotation:existing animated:YES];

            break;
        }
    }
}

- (IBAction)toggleBuildingsView:(id)sender {
    
    switch ([sender selectedSegmentIndex]) {
        case 0:
        {
            self.mapView.hidden = NO;
            self.tableView.hidden = YES;
            break;
        }
        case 1:
        {
            self.mapView.hidden = YES;
            self.tableView.hidden = NO;
            break;
        }
        default:
            break;
    }
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate =
    [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    // Maybe move original location pin rather than create a new pin
    self.locationPin.coordinate = touchMapCoordinate;

    // Update location
    [self.reportDict setValue:[NSNumber numberWithDouble:touchMapCoordinate.latitude] forKey:@"lat"];
    [self.reportDict setValue:[NSNumber numberWithDouble:touchMapCoordinate.longitude] forKey:@"lon"];

}


#pragma mark - MapView
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self updateVisibleRegion];
}

-(void)updateVisibleRegion {
    MKCoordinateRegion region = { { 0.0, 0.0 }, { 0.0, 0.0 } };
    region.center.latitude = self.locationManager.location.coordinate.latitude;
    region.center.longitude = self.locationManager.location.coordinate.longitude;
    region.span.latitudeDelta = 0.0003;
    region.span.longitudeDelta = 0.0003;
    [self.mapView setRegion:region animated:YES];
}


-(CLLocationCoordinate2D)getNECoordinate:(MKMapRect)mRect{
    return [self getCoordinateFromMapRectanglePoint:MKMapRectGetMaxX(mRect) y:mRect.origin.y];
}
-(CLLocationCoordinate2D)getNWCoordinate:(MKMapRect)mRect{
    return [self getCoordinateFromMapRectanglePoint:MKMapRectGetMinX(mRect) y:mRect.origin.y];
}
-(CLLocationCoordinate2D)getSECoordinate:(MKMapRect)mRect{
    return [self getCoordinateFromMapRectanglePoint:MKMapRectGetMaxX(mRect) y:MKMapRectGetMaxY(mRect)];
}
-(CLLocationCoordinate2D)getSWCoordinate:(MKMapRect)mRect{
    return [self getCoordinateFromMapRectanglePoint:mRect.origin.x y:MKMapRectGetMaxY(mRect)];
}


-(CLLocationCoordinate2D)getCoordinateFromMapRectanglePoint:(double)x y:(double)y{
    MKMapPoint swMapPoint = MKMapPointMake(x, y);
    return MKCoordinateForMapPoint(swMapPoint);
}


-(NSMutableDictionary *)getBoundingBox:(MKMapRect)mRect{
    CLLocationCoordinate2D topLeft = [self getNWCoordinate:mRect];
    CLLocationCoordinate2D bottomRight = [self getSECoordinate:mRect];
    
    
    NSDictionary *topLeftDict = @{ @"top_left" : @{ @"lat": [NSNumber numberWithDouble:topLeft.latitude] , @"lon":[NSNumber numberWithDouble:topLeft.longitude]}};
    NSDictionary *bottomRightDict = @{ @"bottom_right" : @{ @"lat": [NSNumber numberWithDouble:bottomRight.latitude], @"lon":[NSNumber numberWithDouble:bottomRight.longitude]}};
    
    
    NSMutableDictionary *bb =  [[NSMutableDictionary alloc] init];
    
    [bb addEntriesFromDictionary:topLeftDict];
    [bb addEntriesFromDictionary:bottomRightDict];
    
    return bb;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {

    // Ensure we're not zoomed out to the extent of all annotations
   [self updateVisibleRegion];
    
    NSString *const LOCATION_PIN_TITLE = @"Report Location";
    
    CLLocationCoordinate2D coord = [userLocation coordinate];
    
    // Check if location annotation has been added previously
    NSArray *annotations =  [self.mapView annotations];
    
    BOOL locationAlreadyOnMap = NO;
    
    for (id annotation in annotations){
        
        if ([annotation isKindOfClass:[MKPointAnnotation class]]){
            NSString *title = [annotation title];
            if ([title isEqualToString:LOCATION_PIN_TITLE]) {
                // Pin is already on the map so we don't need to create a new one
                // Just update it's position
                [annotation setCoordinate:coord];
                locationAlreadyOnMap = YES;
                break;
            }
        }
    }
    
    //otherwise create new annotation
    if (!locationAlreadyOnMap) {

        //add the annotation
        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
        point.coordinate = coord;
        point.title = LOCATION_PIN_TITLE;
        point.subtitle = @"(Drag pin if location is incorrect)";
        
        // Keep track of the location pin so we can move it as necessary
        self.locationPin = point;
        
        [self.mapView addAnnotation:point];
    }
    
    // Only update value to be stored if user hasn't specified a location manually
    if (!self.userSpecfiedLocation) {
        [self.reportDict setValue:[NSNumber numberWithDouble:coord.latitude] forKey:@"lat"];
        [self.reportDict setValue:[NSNumber numberWithDouble:coord.longitude] forKey:@"lon"];
    }
    
}


- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKPinAnnotationView *)view{
    
    MKPointAnnotation *annotation = view.annotation;
    
    if (![annotation isKindOfClass:[MKUserLocation class]]){
        if ([annotation isKindOfClass:[CustomMKPointAnnotation class]]){
           
            self.descriptionText.text = [self generateDescriptionFromAnnotation:annotation];
            
            view.pinColor = MKPinAnnotationColorGreen;
            
            // Move location pin and update reportDict
            self.locationPin.coordinate = annotation.coordinate;
            
            [self.reportDict setValue:[NSNumber numberWithDouble:annotation.coordinate.latitude] forKey:@"lat"];
            [self.reportDict setValue:[NSNumber numberWithDouble:annotation.coordinate.longitude] forKey:@"lon"];
        }
        else if (![annotation.title isEqualToString:@"Report Location"]){
            
            view.pinColor = MKPinAnnotationColorGreen;
            // Move location pin and update reportDict
            self.locationPin.coordinate = annotation.coordinate;
        }
        
    }
}


- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKPinAnnotationView *)view{
    
    MKPointAnnotation *annotation =  view.annotation;
    
    if (![annotation isKindOfClass:[MKUserLocation class]]){
        // Reset pin colour
        if (![annotation isKindOfClass:[CustomMKPointAnnotation class]]  && ![annotation.title isEqualToString:@"Report Location"]){
            
            view.pinColor = MKPinAnnotationColorPurple;
        }
        else if (![annotation.title isEqualToString:@"Report Location"]){
            
            view.pinColor = MKPinAnnotationColorRed;
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    static NSString *reuseId = @"pin";
    static NSString *purpleReuseId = @"purplePin";
    static NSString *greenReuseId = @"greenPin";
    
    MKPinAnnotationView *pav = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseId];
    MKPinAnnotationView *pavPurple = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:purpleReuseId];
    MKPinAnnotationView *pavGreen = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:greenReuseId];
    
    
    if (![annotation isKindOfClass:[CustomMKPointAnnotation class]] && ![annotation.title isEqualToString:@"Report Location" ]){
        if (pavPurple == nil){
            
            pavPurple = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:purpleReuseId];
            pavPurple.animatesDrop = NO;
            UIImageView *leftIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MapPinDefaultLeftCallout" ]];
            leftIconView.frame = CGRectMake(0,0,53,53);
            pavPurple.leftCalloutAccessoryView = leftIconView;
            
            UIButton *rightIconView = [UIButton buttonWithType:UIButtonTypeInfoDark];
            rightIconView.tintColor = [UIColor darkTextColor];
            pavPurple.rightCalloutAccessoryView = rightIconView;
            pavPurple.pinColor = MKPinAnnotationColorPurple;
            pavPurple.canShowCallout = YES;
            return pavPurple;
            
        }
        else
        {
            pavPurple.annotation = annotation;
            return pavPurple;
        }
    }
    
    if([annotation.title isEqualToString:@"Report Location"]){
        
        if(pavGreen == nil){
            pavGreen = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:greenReuseId];
            UIImageView *leftIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MapPinDefaultLeftCallout" ]];
            leftIconView.frame = CGRectMake(0,0,53,53);
            pavGreen.leftCalloutAccessoryView = leftIconView;
            pavGreen.draggable = YES;
            pavGreen.animatesDrop = YES;
            pavGreen.pinColor = MKPinAnnotationColorGreen;
            pavGreen.canShowCallout = YES;
            pavGreen.annotation = annotation;
            return pavGreen;
        }
        else
        {
            pavGreen.annotation = annotation;
            return pavGreen;
        }
    }
    
    if (pav == nil){
        
        pav = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseId];
        pav.animatesDrop = NO;
        UIImageView *leftIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MapPinDefaultLeftCallout" ]];
        leftIconView.frame = CGRectMake(0,0,53,53);
        pav.leftCalloutAccessoryView = leftIconView;
        pav.canShowCallout = YES;
    }
    else
    {
        pav.annotation = annotation;
    }
    
    return pav;
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    [self performSegueWithIdentifier:@"Location Details" sender:view];
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
        if (newState == MKAnnotationViewDragStateEnding)
        {
            CLLocationCoordinate2D droppedAt = annotationView.annotation.coordinate;
            NSLog(@"dropped at %f,%f", droppedAt.latitude, droppedAt.longitude);
         
            [self.reportDict setValue:[NSNumber numberWithDouble:droppedAt.latitude] forKey:@"lat"];
            [self.reportDict setValue:[NSNumber numberWithDouble:droppedAt.longitude] forKey:@"lon"];
            
            self.userSpecfiedLocation = YES;
        }
   }

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    NSString *trimmedDescription = [self.descriptionText.text stringByTrimmingCharactersInSet:
                                    [NSCharacterSet whitespaceCharacterSet]];
    
    if ( trimmedDescription == nil || [trimmedDescription isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Location Description" message: @"Please Enter a Location Description" delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return NO;
    } else {
        
        return YES;
    }
}


- (NSMutableString *)generateDescriptionFromAnnotation:(MKPointAnnotation *)point
{
    NSMutableString *text = [NSMutableString string];
    [text appendString:[NSString stringWithFormat:@"%@ \n", point.title]];
    [text appendString:point.subtitle];
    return text;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    
    if ([[segue identifier] isEqualToString:@"Take Picture"]){
        if ([segue.destinationViewController isKindOfClass:[PictureViewController class]]) {
            
            PictureViewController *picvc = (PictureViewController *)segue.destinationViewController;
            
            NSString *locationDescription = self.descriptionText.text;
            NSLog(@" %@", locationDescription);
            
            if(self.report){
                self.report.loc_desc = locationDescription;
                self.report.lon = [self.reportDict valueForKey:@"lon"];
                self.report.lat = [self.reportDict valueForKey:@"lat"];
            } else {
                [self.reportDict setValue:locationDescription forKey:@"loc_desc"];
                [self.reportDict setValue:@"unsubmitted" forKey:@"status"];
                
                Report *report = [Report reportFromReportInfo:self.reportDict inManangedObjectContext:self.managedObjectContext];
                self.report = report;
            }
            // Associate any photo in reportDict to the report
            [Photo photoWithUrl:[self.reportDict valueForKey:@"photo_url"] fromReport:self.report inManagedObjectContext:self.report.managedObjectContext];
            
            // Set report in next controller
            picvc.report = self.report;


        }
    } else if ([[segue identifier] isEqualToString:@"Location Details"]){
        if ([segue.destinationViewController isKindOfClass:[LocationDetailsViewController class]]) {
            MKAnnotationView *annotationView = (MKAnnotationView *) sender;
            
            for (NSDictionary *location in self.locations) {
                NSString *title = [location valueForKeyPath:@"properties.title"];
                if ([title isEqualToString:annotationView.annotation.title]){
                    LocationDetailsViewController *ldvc = (LocationDetailsViewController *)segue.destinationViewController;
                    ldvc.location = location;
                    break;
                }
            }
        }
    }
}

@end
