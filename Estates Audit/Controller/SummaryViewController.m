//
//  SummaryViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 16/04/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "SummaryViewController.h"
#import "Photo.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AcceptsManagedContext.h"
#import "HomePageViewController.h"
#import "EmailSupportTicket.h"
#import "ViewPhotoViewController.h"
#import "AppDelegate.h"
#import <SDWebImage/UIImageView+WebCache.h>
@import MapKit;

@interface SummaryViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *locationDescription;
@property (weak, nonatomic) IBOutlet UITextView *problemDescription;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic, strong) NSString *encodedCredentials;
@property (copy, nonatomic) void (^assetsFailureBlock)();
@property (strong, nonatomic) NSURLSession *jitUploadSession;
@property (strong, nonatomic) AppDelegate *appDelegate;

-(void) postPhotos:(NSSet *) photos withTicketId:(NSString *) ticketId;
- (void)postPhoto: (NSData *)imageData ToTicket:(NSString *)ticketId;

@end

@implementation SummaryViewController


- (void)setReport:(Report *)report
{
    _report = report;
    
    
    self.encodedCredentials  = [self.appDelegate encodedCredentials];
    
    self.assetsFailureBlock  = ^(NSError *myerror)
    {
        NSLog(@"Can't get image - %@",[myerror localizedDescription]);
    };

}

-(AppDelegate *)appDelegate{
    if (!_appDelegate) {
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}


- (NSURLSession *)jitUploadSession
{
    if (!_jitUploadSession) {
        
        // another configuration option is backgroundSessionConfiguration (multitasking API required though)
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSString *authValue = [self encodedCredentials];
        [configuration setHTTPAdditionalHeaders:@{@"Authorization": authValue}];
        
        _jitUploadSession = [NSURLSession sessionWithConfiguration:configuration];
        
    }
    return _jitUploadSession;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.mapView setDelegate:self];
    
    // Hide map if voiceover is running when page loads as it's confusing
    if(!UIAccessibilityIsVoiceOverRunning()){
        // Zoom map to region and add pin
        [self setupMap];
    }else{
        [self.mapView setHidden:YES];
    }
    
    // Do any additional setup after loading the view.
    self.locationDescription.text = self.report.loc_desc;
    self.problemDescription.text = self.report.desc;
    
    self.photoCollectionView.delegate = self;
    self.photoCollectionView.dataSource = self;
    self.photos =  [NSArray arrayWithArray:[self.report.photos allObjects]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [tap setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tap];
}

-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    
    // Check in case we have to reload the data
    [self finishAndUpdate];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)finishAndUpdate
{
    self.photos =  [NSArray arrayWithArray:[self.report.photos allObjects]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.photoCollectionView reloadData];
    });
}

-(void)setupMap{
    [self.mapView setDelegate:self];
    
    NSNumber *lat = self.report.lat;
    NSNumber *lon = self.report.lon;
    
    NSLog(@"%@, %@", lat, lon);
    CLLocationCoordinate2D reportLocation = CLLocationCoordinate2DMake([lat doubleValue] ,[lon doubleValue]);
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(reportLocation, 800, 800);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
    
    //add the annotation
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    
    point.coordinate = reportLocation;
    point.title = @"Report Location";
    
    [self.mapView addAnnotation:point];
    
    // Disable map interaction
    self.mapView.userInteractionEnabled = NO;
}



-(void)postToJitBit{
    
    NSString *apiStr = @"https://eaudit.jitbit.com/helpdesk/api/ticket";
    
    NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
    [request setHTTPMethod:@"POST"];
    
    NSMutableString *body = [NSMutableString string];
    
    if([self.report.loc_desc length] != 0){
        [body appendString:[NSString stringWithFormat:@"[b]Location Description[/b]\n\n %@ \n", self.report.loc_desc]];
    }
    
    // Add link to map
    [body appendString:[NSString stringWithFormat:@"\n[b]Location Map[/b]\n\n [url]http://maps.google.com/maps?q=loc:%@+%@[/url]\n", self.report.lat, self.report.lon]];
    
    if([self.report.desc length] != 0){
        [body appendString:[NSString stringWithFormat:@"\n[b]Problem Description[/b]\n\n %@ \n\n", self.report.desc]];
    }

    
    NSMutableString *subject = [NSMutableString string];
    
    NSString *description = self.report.desc;
    const int clipLength = 50;
    if([description length]>clipLength)
    {
        description = [NSString stringWithFormat:@"%@…",[description substringToIndex:clipLength]];
    }
    
    
    [subject appendString:[NSString stringWithFormat:@"Fix My Campus Report: %@", description]];

    
    NSString *postString = [NSString stringWithFormat:@"categoryId=0&body=%@&subject=%@&priorityId=0", body, subject];
    
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLSessionDataTask *task = [self.jitUploadSession dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      // this handler is not executing on the main queue, so we can't do UI directly here
                                      if (!error) {
                                          if ([request.URL isEqual:apiUrl]) {
                                              NSString *ticketId = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                                              NSLog(@"%@",ticketId);
                                              
                                              // Set ticketId in report
                                              self.report.ticket_id = @([ticketId floatValue]);
                                              
                                              // Change status so it will now display in reports list
                                              self.report.status=@"New";
                                              
                                              // Save just to be sure
                                              [self.report.managedObjectContext save:NULL];
                                              
                                              // Post any additional photos
                                              
                                              [self postPhotos:self.report.photos withTicketId:ticketId];
                                              [self postCustomFieldsToTicket:ticketId];
                                              
                                          }
                                      }
                                  }];
    
    [task resume]; // don't forget that all NSURLSession tasks start out suspended!
    
}


-(void)postCustomFieldsToTicket: (NSString *)ticketId{
    
    NSString *apiStr = [NSString stringWithFormat:@"https://eaudit.jitbit.com/helpdesk/api/SetCustomField"];
    
    NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
    [request setHTTPMethod:@"POST"];

    // Description
    NSString *postString = [NSString stringWithFormat:@"ticketId=%@&fieldId=%@&value=%@", ticketId, @"9434", self.report.desc];
    [self postField:request :postString :self.jitUploadSession];
    
    // Location Description
    postString = [NSString stringWithFormat:@"ticketId=%@&fieldId=%@&value=%@", ticketId, @"9435", self.report.loc_desc];
    [self postField:request :postString :self.jitUploadSession];
    
    // Lat lon
    postString = [NSString stringWithFormat:@"ticketId=%@&fieldId=%@&value=%@ %@", ticketId, @"9450", self.report.lat, self.report.lon];
    [self postField:request :postString :self.jitUploadSession];
    
    
}

-(void) postPhotos:(NSSet *) photos withTicketId:(NSString *) ticketId{
    for( Photo * photo in photos){

        NSURL *assetUrl = [NSURL URLWithString:[photo.url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        if([[assetUrl scheme] isEqualToString:@"assets-library"]){
        
            ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset){
                ALAssetRepresentation *rep = [myasset defaultRepresentation];
                CGImageRef iref = [rep fullResolutionImage];
                
                if (iref) {
                    
                    UIImage *image = [UIImage imageWithCGImage:iref];
                    
                    CGImageRef cgRef = image.CGImage;
                    
                    // Have to get the orientation directly from the exif data as the orientation
                    // from image.imageOrientation is always UIImageOrientationUp for some reason.
                    NSDictionary *metadata = myasset.defaultRepresentation.metadata;
                    NSDictionary *imageMetadata = [[NSMutableDictionary alloc] initWithDictionary:metadata];
                    NSNumber *orientation = [imageMetadata valueForKey:@"Orientation"];
                    
                    NSLog(@"Orientation : %@", orientation);
                    
                    // We have to adjust the orientation in certain cases by creating a new image that has
                    // been rotated properly.
                    if([orientation isEqualToNumber:[NSNumber numberWithLong:6]]){
                        image = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationRight];
                    }else if([orientation isEqualToNumber:[NSNumber numberWithLong:3]]){
                        image = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationDown];
                    }else if([orientation isEqualToNumber:[NSNumber numberWithLong:8]]){
                        image = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationLeft];
                    }
                    
                    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
                    [self postPhoto:imageData ToTicket:ticketId];
                    
                }
            };
            
            ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
            [
             assetslibrary assetForURL:assetUrl
             resultBlock:resultblock
             failureBlock: ^(NSError *myerror)
             {
                 NSLog(@"Can't get image - %@",[myerror localizedDescription]);
             }];

        } else {
          
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                NSData * data = [[NSData alloc] initWithContentsOfURL: assetUrl];
                if ( data == nil )
                    return;
                [self postPhoto:data ToTicket:ticketId];
            });
            
        }
    
    }
    
    // Update - hopefully this will bring down the ticket id
    [self.appDelegate syncWithJitBit];
    
}


- (void) postField:(NSMutableURLRequest *)request
                  :(NSString *)postString
                  :(NSURLSession *)session
{
    
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      // this handler is not executing on the main queue, so we can't do UI directly here
                                      if (error) {
                                          NSLog(@"%@",error);
                                      }else{
                                          NSLog(@"Field posted successfully");
                                      }
                                      
                                  }];
    [task resume]; // don't forget that all NSURLSession tasks start out suspended!
}


- (void)postPhoto: (NSData *)imageData ToTicket:(NSString *)ticketId
{
    
    NSString *apiStr = [NSString stringWithFormat:@"https://eaudit.jitbit.com/helpdesk/api/AttachFile?id=%@", ticketId];
    
    NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
    [request setHTTPMethod:@"POST"];

    // post body
    NSMutableData *body = [NSMutableData data];
 
    // the boundary string : a random string, that will not repeat in post data, to separate post data fields.
    NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
    
    // set Content-Type in HTTP header
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BoundaryConstant];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    // string constant for the post parameter 'file'. My server uses this name: `file`. Your's may differ
    NSString* FileParamConstant = @"fn";
    
    // add image data
   
    if (imageData) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"image.jpg\"\r\n", FileParamConstant] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:imageData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // setting the body of the post to the reqeust
    [request setHTTPBody:body];
    
    // set the content-length
    NSString *postLength = [NSString stringWithFormat:@"%zd", [body length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    NSURLSessionDataTask *task = [self.jitUploadSession dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      // this handler is not executing on the main queue, so we can't do UI directly here
                                      // No content expected - only check for error
                                      if (error) {
                                          NSLog(@"%@",error);
                                      }else{
                                          NSLog(@"Image Uploaded successfully");
                                      }
                                      
                                  }];
    
    [task resume]; // don't forget that all NSURLSession tasks start out suspended!
    
}


- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if([self.appDelegate isNetworkAvailable]){
        return YES;
    }
    [self.appDelegate displayNetworkNotification];
    return NO;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // POST to JitBit API and store ticketId
    [self postToJitBit];
    // Ensure context is saved
    [self.report.managedObjectContext save:NULL];
    
    // Need to ensure the context is not nil
    if ([segue.destinationViewController conformsToProtocol:@protocol(AcceptsManagedContext)]) {
        
        // Need to pass managedObjectContext through
        id<AcceptsManagedContext> controller = segue.destinationViewController;
        controller.managedObjectContext  = self.report.managedObjectContext;
      
    }
    if ([[segue identifier] isEqualToString:@"Send"])
    {
        HomePageViewController *homevc = (HomePageViewController *)segue.destinationViewController;
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStylePlain target:self action:@selector(home:)];
        homevc.navigationItem.leftBarButtonItem=newBackButton;
    }
    
}


-(void)home:(UIBarButtonItem *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - UICOLLECTION view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    return [self.report.photos count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"Cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    

    Photo *photo = self.photos[indexPath.row];
    NSURL *assetUrl = [NSURL URLWithString:photo.url];
    
    if([[assetUrl scheme] isEqualToString:@"assets-library"]){
    
        ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
        {
            CGImageRef iref = [myasset thumbnail];
            if (iref) {
                UIImage *thumbImage = [UIImage imageWithCGImage:iref];
                   dispatch_async(dispatch_get_main_queue(), ^{
            /* This is the main thread again, where we set the tableView's image to
             be what we just fetched. */
        
                UIImageView *photoImageView = (UIImageView *)[cell viewWithTag:100];
                photoImageView.image = thumbImage;
                [cell setNeedsLayout];
                }
            );
                
         
            }
        };
        
        ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
        {
            NSLog(@"Can't get image - %@",[myerror localizedDescription]);
        };  
        
        ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
        [assetslibrary assetForURL:assetUrl
                       resultBlock:resultblock
                      failureBlock:failureblock];
    } else {
        UIImageView *photoImageView = (UIImageView *)[cell viewWithTag:100];
        [photoImageView sd_setImageWithURL:[NSURL URLWithString:[photo.url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                          placeholderImage:[UIImage imageNamed:@"MapPinDefaultLeftCallout"]];
    }
    
    return cell;
}



- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    //what photo chosen
    Photo *photo = self.photos[indexPath.row];
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main"
                                                     bundle: nil];
    ViewPhotoViewController* controller = (ViewPhotoViewController*)[mainStoryboard instantiateViewControllerWithIdentifier:@"viewPhoto"];

    controller.photo = photo;

    [self.navigationController pushViewController:controller animated:YES];
}







@end
