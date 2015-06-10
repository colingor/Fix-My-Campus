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


#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@import MapKit;
@interface LocationViewController () <MKMapViewDelegate, CLLocationManagerDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *descriptionText;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL userSpecfiedLocation;
@property (strong, nonatomic) Report *report;
@property (strong, nonatomic) NSArray *locations;
@property (strong, nonatomic) MKPointAnnotation *locationPin;
@end

@implementation LocationViewController

- (void)setLocationPin:(MKPointAnnotation *)locationPin
{
    if (!_locationPin) {
        _locationPin = locationPin;
    }
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
    
    NSMutableArray *locationAnnotations = [NSMutableArray array];
    
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
    }
    
    [self.mapView addAnnotations:locationAnnotations];
    
    // Set up listener to move location pin on long press
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.0; //user needs to press for 1 second
    [self.mapView addGestureRecognizer:lpgr];
   
    
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

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}


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
            NSMutableString *text = [NSMutableString string];
            [text appendString:[NSString stringWithFormat:@"%@ \n", annotation.title]];
            [text appendString:annotation.subtitle];
            self.descriptionText.text = text;
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
