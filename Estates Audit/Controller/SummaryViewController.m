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

@end

@implementation SummaryViewController


- (void)setReport:(Report *)report
{
    _report = report;
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
        
        ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
        {
            NSLog(@"Can't get image - %@",[myerror localizedDescription]);
        };
        
        ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
        [assetslibrary assetForURL:assetUrl
                       resultBlock:resultblock
                      failureBlock:failureblock];
    }

}

-(void)postToJitBit{
    
    NSString *apiStr = @"https://eaudit.jitbit.com/helpdesk/api/ticket";
    
    
    NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
    [request setHTTPMethod:@"POST"];
    
    
    NSString *body = [NSString stringWithFormat:@"%@", self.report.loc_desc];
    
    NSString *postString = [NSString stringWithFormat:@"categoryId=0&body=%@&subject=%@&priorityId=0", body, @"Estates Audit Report"];
    
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    // TODO: Credentials in code is bad...
    [request setValue:@"Basic Y2dvcm1sZTFAc3RhZmZtYWlsLmVkLmFjLnVrOmVzdGF0ZXNhdWRpdDM=" forHTTPHeaderField:@"Authorization"];
    
    // another configuration option is backgroundSessionConfiguration (multitasking API required though)
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    // create the session without specifying a queue to run completion handler on (thus, not main queue)
    // we also don't specify a delegate (since completion handler is all we need)
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                    completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
                                                        // this handler is not executing on the main queue, so we can't do UI directly here
                                                        if (!error) {
                                                            if ([request.URL isEqual:apiUrl]) {
                                                          
                                                                NSData *contents = [NSData dataWithContentsOfURL:localfile];
                                                                NSString *ticketId = [[NSString alloc]initWithData:contents encoding:NSUTF8StringEncoding];
                                                                NSLog(@"%@",ticketId);
                                                                
                                                                //TODO: Set ticketId in report
                                                      
                                                                dispatch_async(dispatch_get_main_queue(), ^{});
                                                            }
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
