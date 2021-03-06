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
#import "CustomMKAnnotation.h"
#import "AppDelegate.h"
#import "ElasticSearchAPI.h"
#import <SDWebImage/UIImageView+WebCache.h>

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

@end

@implementation LocationViewController

NSString *const LOCATION_PIN_TITLE = @"Report Location";
#define LOCATION_DETAILS_SEGUE_IDENTIFIER @"Location Details"
#define TAKE_PICTURE_SEGUE_IDENTIFIER @"Take Picture"

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

    return _appDelegate;
}


- (NSURLSession *)elasticSearchSession
{
    if (!_elasticSearchSession) {
        
        // another configuration option is backgroundSessionConfiguration (multitasking API required though)
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        
        _elasticSearchSession = [NSURLSession sessionWithConfiguration:configuration];
        
    }
    return _elasticSearchSession;
}



-(IBAction) unwindToMainMenu:(UIStoryboardSegue *)segue {
    [self removePhotos];
}


-(void) removePhotos{
    if ([self reportDict]){
        if ([self report]){
            // delete existing photo if there is one
            for (Photo *photo in [self.report.photos allObjects]) {
                [[self managedObjectContext] deleteObject:photo];
            }
            // Save just to be sure
            [self.managedObjectContext save:NULL];
            
        }
//        [self.reportDict removeObjectForKey:@"photo_url"];
        self.descriptionText.text = [self.reportDict valueForKey:@"loc_desc"];
        self.userSpecfiedLocation = YES;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.mapView setDelegate:self];
    
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
   
    // Declare empty dict we can add report info to
    _reportDict = [NSMutableDictionary dictionary];
    
    // Use this to determine whether user overrides location from locationManager by movin pin
    _userSpecfiedLocation = NO;
    
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
    
    // Get buildings within 500m of current location
    [self listBuildingsNearCurrentLocation];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [tap setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tap];
    
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
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

-(void)processSearchResults:(NSMutableDictionary *) locations{
    
    NSArray *hits = [[locations valueForKey:@"hits"] valueForKey:@"hits"];
    
    // localAnnotations used to populate building list table
    [self.locationAnnotations removeAllObjects];
    
    for (id hit in hits){
        
        NSMutableDictionary * source = [hit valueForKey:@"_source"];
        NSString *buildingId = hit[@"_id"];
        
        NSArray *loc = source[@"geometry"][@"location"];
        NSString * lat = loc[1];
        NSString * lon = loc[0];
        
        NSDictionary *properties = source[@"properties"];
        NSString * name = properties[@"title"];
        NSString * address = properties[@"subtitle"];
        
        // Check if annotation already exists on map
        NSArray *existingAnnotations = self.mapView.annotations;
        
        BOOL found = NO;
        
        for(CustomMKAnnotation *existing in existingAnnotations){
            if ([existing isKindOfClass:[CustomMKAnnotation class]]){
                
                if([existing.buildingId isEqualToString:buildingId]){
                    found = YES;
                    break;
                }
            }
        }
        
        CLLocationCoordinate2D coord;
        coord.latitude = [lat floatValue];
        coord.longitude = [lon floatValue];
        
        CustomMKAnnotation *point = [[CustomMKAnnotation alloc] initWithLocation:coord];
        
        point.buildingId = buildingId;
        point.title = name;
        point.subtitle = address;
        
        NSString *imageName = [source valueForKeyPath:@"properties.image"];
        
        if([imageName length] > 0){
            NSString *imagePath = [NSString stringWithFormat:@"%@%@/download/%@", BASE_IMAGE_URL,  buildingId,  imageName];
            
            point.imageUrl = imagePath;
        }
  
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

-(void)displayBuildingsInBoundingBox{
    
    MKMapRect mRect = self.mapView.visibleMapRect;
    NSDictionary *bb = [self getBoundingBox:mRect];
    
    [[ElasticSearchAPI sharedInstance] searchForBuildingsWithinBoundingBox:bb withCentre:[self centreCoords] withCompletion:^(NSMutableDictionary *locations) {
        [self processSearchResults:locations];
    }];
}


-(void)listBuildingsNearCurrentLocation{
    
    [[ElasticSearchAPI sharedInstance] searchForBuildingsNearCoordinate:[self centreCoords] withCompletion:^(NSMutableDictionary *locations) {
        [self processSearchResults:locations];
    }];
}

-(NSDictionary *)centreCoords{
    return  @{ @"lat": [NSNumber numberWithDouble:self.locationManager.location.coordinate.latitude],
               @"lon":[NSNumber numberWithDouble:self.locationManager.location.coordinate.longitude]};
}


#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.locationAnnotations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"BuildingCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessibilityHint = nil;

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
    }
   
    @try {
        CustomMKAnnotation *point = [self.locationAnnotations objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.accessibilityHint = [point.title stringByAppendingString:point.subtitle];
        
        cell.textLabel.text = point.title;
        cell.detailTextLabel.text  = point.subtitle;
        
        
        NSURL *assetUrl = [NSURL URLWithString:[point.imageUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        [cell.imageView sd_setImageWithURL:assetUrl
                          placeholderImage:[UIImage imageNamed:@"fix-my-campus-building"]];
    }
    @catch (NSException *exception) {
        NSLog(@"Problem creating custom point: %@", exception.reason);
    }

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CustomMKAnnotation *point = [self.locationAnnotations objectAtIndex:indexPath.row];
    
    // Find the corresponding annotation on the map as point won't be the same instance
    for(CustomMKAnnotation *existing in self.mapView.annotations){
        if ([existing isKindOfClass:[CustomMKAnnotation class]]){
            
            if([existing.buildingId isEqualToString:point.buildingId]){

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
                
                [self performSegueWithIdentifier:@"Location Details" sender:existing];
                
                break;
            }
        }
    }
}

- (IBAction)toggleBuildingsView:(id)sender {
    
    [self dismissKeyboard];
    
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
    
    
    // Close any selected annotations
    NSArray *selectedAnnotations = self.mapView.selectedAnnotations;
    for(id annotation in selectedAnnotations) {
        [self.mapView deselectAnnotation:annotation animated:NO];
    }
    self.userSpecfiedLocation = YES;
    
    
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
    [self displayBuildingsInBoundingBox];
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


-(NSDictionary *)getBoundingBox:(MKMapRect)mRect{
    CLLocationCoordinate2D topLeft = [self getNWCoordinate:mRect];
    CLLocationCoordinate2D bottomRight = [self getSECoordinate:mRect];
    
    NSDictionary *bb = @{ @"top_left":@{
                                  @"lat":[NSNumber numberWithDouble:topLeft.latitude],
                                  @"lon":[NSNumber numberWithDouble:topLeft.longitude]
                                  },
                          @"bottom_right":@{
                                  @"lat": [NSNumber numberWithDouble:bottomRight.latitude],
                                  @"lon":[NSNumber numberWithDouble:bottomRight.longitude]
                                  }
                          };

    return bb;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {

    // Ensure we're not zoomed out to the extent of all annotations
//   [self updateVisibleRegion];
    

    
    CLLocationCoordinate2D coord = [userLocation coordinate];
    
    // Check if location annotation has been added previously
    NSArray *annotations =  [self.mapView annotations];
    
    BOOL locationAlreadyOnMap = NO;
    
    for (id annotation in annotations){
        
        if ([annotation isKindOfClass:[MKPointAnnotation class]]){
            NSString *title = [annotation title];
            if ([title isEqualToString:LOCATION_PIN_TITLE]) {
                // Pin is already on the map so we don't need to create a new one
                // Just update it's position if the user hasn't specified a location manually
                if(!self.userSpecfiedLocation){
                    [annotation setCoordinate:coord];
                }
                
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
    
    self.userSpecfiedLocation = YES;
    
    MKPointAnnotation *annotation = view.annotation;
    
    // Remove any photos that may have been associated if the user has been looking at a nested annotation
    [self removePhotos];
            [self.reportDict removeObjectForKey:@"photo_url"];
    
    if (![annotation isKindOfClass:[MKUserLocation class]]){
        if ([annotation isKindOfClass:[CustomMKAnnotation class]]){
           
            self.descriptionText.text = [self generateDescriptionFromAnnotation:(CustomMKAnnotation *)annotation];
            
            view.pinColor = MKPinAnnotationColorGreen;
            
            // Move location pin and update reportDict
            self.locationPin.coordinate = annotation.coordinate;
            
            [self.reportDict setValue:[NSNumber numberWithDouble:annotation.coordinate.latitude] forKey:@"lat"];
            [self.reportDict setValue:[NSNumber numberWithDouble:annotation.coordinate.longitude] forKey:@"lon"];
        }
        else if (![annotation.title isEqualToString:LOCATION_PIN_TITLE]){
            
            view.pinColor = MKPinAnnotationColorGreen;
            // Move location pin and update reportDict
            self.locationPin.coordinate = annotation.coordinate;
        }
        
    }
}


- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKPinAnnotationView *)view{
    
    self.userSpecfiedLocation = NO;
    
    MKPointAnnotation *annotation =  view.annotation;
    
    if (![annotation isKindOfClass:[MKUserLocation class]]){
        // Reset pin colour
        if ([annotation isKindOfClass:[CustomMKAnnotation class]]  && ![annotation.title isEqualToString:LOCATION_PIN_TITLE]){
            view.pinColor = MKPinAnnotationColorRed;
        }
        else if ([annotation.title isEqualToString:LOCATION_PIN_TITLE]){
            // If the report location annotation has been deselected, we don't want to reset to the default location
            self.userSpecfiedLocation = YES;
        }

    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    static NSString *reuseId = @"pin";
    static NSString *greenReuseId = @"greenPin";
    
    MKPinAnnotationView *pav = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseId];
    MKPinAnnotationView *pavGreen = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:greenReuseId];

    if ([annotation isKindOfClass:[CustomMKAnnotation class]] && ![annotation.title isEqualToString:LOCATION_PIN_TITLE ]){

        CustomMKAnnotation *customMKAnnotation = (CustomMKAnnotation *)annotation;
      

            if (pav == nil){
                
                pav = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseId];
                pav.animatesDrop = NO;
                
                // Add image thumbnail if present
                NSString *imageUrl = [customMKAnnotation imageUrl];
                
                if(imageUrl){
                    UIImageView *leftIconView = [[UIImageView alloc] initWithImage:nil];
                    leftIconView.frame = CGRectMake(0,0,53,53);
                    pav.leftCalloutAccessoryView = leftIconView;
                    
                    [leftIconView sd_setImageWithURL:[NSURL URLWithString:[imageUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                                    placeholderImage:[UIImage imageNamed:DEFAULT_CELL_IMAGE]];
                }
                
                UIButton *rightIconView = [UIButton buttonWithType:UIButtonTypeInfoDark];
                rightIconView.tintColor = [UIColor darkTextColor];
                pav.rightCalloutAccessoryView = rightIconView;

                pav.canShowCallout = YES;
                return pav;
                
            }
            else
            {
                pav.annotation = annotation;
                return pav;
            }
    }
    
    if([annotation.title isEqualToString:LOCATION_PIN_TITLE]){
        
        if(pavGreen == nil){
            pavGreen = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:greenReuseId];
            UIImageView *leftIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:DEFAULT_CELL_IMAGE ]];
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
    
    return pav;
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    [self performSegueWithIdentifier:LOCATION_DETAILS_SEGUE_IDENTIFIER sender:view];
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


- (NSMutableString *)generateDescriptionFromAnnotation:(CustomMKAnnotation *)point
{
    NSMutableString *text = [NSMutableString string];
    [text appendString:[NSString stringWithFormat:@"%@ \n", point.title]];
    [text appendString:point.subtitle];
    return text;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    

    
    if ([[segue identifier] isEqualToString:TAKE_PICTURE_SEGUE_IDENTIFIER]){
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
    } else if ([[segue identifier] isEqualToString:LOCATION_DETAILS_SEGUE_IDENTIFIER]){
        if ([segue.destinationViewController isKindOfClass:[LocationDetailsViewController class]]) {
            
            LocationDetailsViewController *ldvc = (LocationDetailsViewController *)segue.destinationViewController;
            CustomMKAnnotation  *customMKAnnotation = nil;
            
            if([sender isKindOfClass:[CustomMKAnnotation class]]){
                
                customMKAnnotation = (CustomMKAnnotation *)sender;
                
            }else if([sender isKindOfClass:[MKAnnotationView class]]){
                
                MKAnnotationView *annotationView = (MKAnnotationView *) sender;
                customMKAnnotation = (CustomMKAnnotation *)annotationView.annotation;
                
            }

            ldvc.buildingId = customMKAnnotation.buildingId;

        }
    }
}

@end
