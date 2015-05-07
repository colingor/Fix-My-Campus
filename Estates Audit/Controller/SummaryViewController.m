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

@import MapKit;

@interface SummaryViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *locationDescription;
@property (weak, nonatomic) IBOutlet UITextView *problemDescription;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (copy, nonatomic) void (^assetsFailureBlock)();

@end

@implementation SummaryViewController


- (void)setReport:(Report *)report
{
    _report = report;
    
    self.assetsFailureBlock  = ^(NSError *myerror)
    {
        NSLog(@"Can't get image - %@",[myerror localizedDescription]);
    };
    
    // Try and load image as soon as possible (asynchronous) so it's there when page loads
    [self loadImageFromAssets];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.mapView setDelegate:self];
    
    // Zoom map to region and add pin
    [self setupMap];
    
    // Do any additional setup after loading the view.
    self.locationDescription.text = self.report.loc_desc;
    self.problemDescription.text = self.report.desc;
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
}

-(void)loadImageFromAssets{
    
    NSSet *photos = self.report.photos;
    
    NSArray *photoArray = [photos allObjects];
    
    if ([photoArray count] > 0){
        Photo *photo = [photoArray objectAtIndex:0];
        
        NSURL *assetUrl = [NSURL URLWithString:photo.url];
        
        ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
        {
            ALAssetRepresentation *rep = [myasset defaultRepresentation];
            CGImageRef iref = [rep fullResolutionImage];
            if (iref) {
                UIImage *largeimage = [UIImage imageWithCGImage:iref];
                
                [self.imageView setImage:largeimage];
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
    }
    
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

    NSString *postString = [NSString stringWithFormat:@"categoryId=0&body=%@&subject=%@&priorityId=0", body, @"Estates Audit Report"];
    
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    // TODO: Credentials in code is bad...
    [request setValue:@"Basic Y2dvcm1sZTFAc3RhZmZtYWlsLmVkLmFjLnVrOmVzdGF0ZXNhdWRpdDM=" forHTTPHeaderField:@"Authorization"];
    
    // another configuration option is backgroundSessionConfiguration (multitasking API required though)
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    // create the session without specifying a queue to run completion handler on (thus, not main queue)
    // we also don't specify a delegate (since completion handler is all we need)
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
   
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      // this handler is not executing on the main queue, so we can't do UI directly here
                                      if (!error) {
                                          if ([request.URL isEqual:apiUrl]) {
                                              NSString *ticketId = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                                              NSLog(@"%@",ticketId);
                                              
                                              // Set ticketId in report
                                              self.report.ticket_id = ticketId;
                                              
                                              // Save just to be sure
                                              [self.report.managedObjectContext save:NULL];
                                              
                                              // Post any additional photos
                                              if([self.report.photos count] > 0){
                                                  [self postPhotoToTicket:ticketId];
                                              }
                                              
                                              [self postCustomFieldsToTicket:ticketId];
                                              
                                          }
                                      }
                                  }];
    [task resume]; // don't forget that all NSURLSession tasks start out suspended!
    
}


-(void)postCustomFieldsToTicket: (NSString *)ticketId{
   
    
    // another configuration option is backgroundSessionConfiguration (multitasking API required though)
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    // create the session without specifying a queue to run completion handler on (thus, not main queue)
    // we also don't specify a delegate (since completion handler is all we need)
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSString *apiStr = [NSString stringWithFormat:@"https://eaudit.jitbit.com/helpdesk/api/SetCustomField"];
    
    NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
    [request setHTTPMethod:@"POST"];
   
    // TODO: Credentials in code is bad...
    [request setValue:@"Basic Y2dvcm1sZTFAc3RhZmZtYWlsLmVkLmFjLnVrOmVzdGF0ZXNhdWRpdDM=" forHTTPHeaderField:@"Authorization"];
    
    // Description
    NSString *postString = [NSString stringWithFormat:@"ticketId=%@&fieldId=%@&value=%@", ticketId, @"9434", self.report.desc];
    [self postField:request :postString :session];
    
    // Location Description
    postString = [NSString stringWithFormat:@"ticketId=%@&fieldId=%@&value=%@", ticketId, @"9435", self.report.loc_desc];
    [self postField:request :postString :session];
    
    // Lat lon
    postString = [NSString stringWithFormat:@"ticketId=%@&fieldId=%@&value=%@ %@", ticketId, @"9450", self.report.lat, self.report.lon];
    [self postField:request :postString :session];
    
    
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


- (void)postPhotoToTicket:(NSString *)ticketId
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
    NSData *imageData = UIImageJPEGRepresentation(self.imageView.image, 1.0);
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
    NSString *postLength = [NSString stringWithFormat:@"%d", [body length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    // TODO: Credentials in code is bad...
    [request setValue:@"Basic Y2dvcm1sZTFAc3RhZmZtYWlsLmVkLmFjLnVrOmVzdGF0ZXNhdWRpdDM=" forHTTPHeaderField:@"Authorization"];
    
    // another configuration option is backgroundSessionConfiguration (multitasking API required though)
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    // create the session without specifying a queue to run completion handler on (thus, not main queue)
    // we also don't specify a delegate (since completion handler is all we need)
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
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
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:self action:@selector(home:)];
        homevc.navigationItem.leftBarButtonItem=newBackButton;
    }
    
}


-(void)home:(UIBarButtonItem *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
