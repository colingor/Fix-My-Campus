//
//  ReportDetailsViewController.m
//  Estates Audit
//
//  Created by murray king on 27/04/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "ReportDetailsViewController.h"
#import "Photo+Create.h"
#import "Report+Create.h"
#import "Comment+Create.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "ViewPhotoViewController.h"
@import MapKit;

@interface ReportDetailsViewController ()<MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *locationDescription;
@property (weak, nonatomic) IBOutlet UITextView *fullDescription;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation ReportDetailsViewController


- (void) setReport:(Report *)report
{

    [self styleTabBar];
    report.is_updated = @NO;
    [self processComments:report]; // don't forget that all NSURLSession tasks start out suspended!
    [report.managedObjectContext save:NULL];
    _report = report;
}

- (void) styleTabBar{
    // Get rid of tabbar gradient
    [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
    
    [[UITabBar appearance] setSelectedImageTintColor:[UIColor whiteColor]];
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0f],
                                                        NSForegroundColorAttributeName : [UIColor whiteColor]
                                                        } forState:UIControlStateSelected];
    
    
    // doing this results in an easier to read unselected state then the default iOS 7 one
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0f],
                                                        NSForegroundColorAttributeName : [UIColor colorWithRed:.5 green:.5 blue:.5 alpha:1]
                                                        } forState:UIControlStateNormal];
    
}


- (void)processComments:(Report *)report
{
    NSString *apiStr = [NSString stringWithFormat:@"https://eaudit.jitbit.com/helpdesk/api/comments?id=%@", report.ticket_id];
    
    NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
    
    // TODO: Credentials in code is bad...
    [request setValue:@"Basic Y2dvcm1sZTFAc3RhZmZtYWlsLmVkLmFjLnVrOmVzdGF0ZXNhdWRpdDM=" forHTTPHeaderField:@"Authorization"];
    
    // another configuration option is backgroundSessionConfiguration (multitasking API required though)
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    // create the session without specifying a queue to run completion handler on (thus, not main queue)
    // we also don't specify a delegate (since completion handler is all we need)
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"%@",error);
        }else{
            NSLog(@"Image Uploaded successfully");
            
            NSDictionary *comments;
            NSData *commentsJSONData = [NSData dataWithContentsOfURL:location];
            if (commentsJSONData) {
                comments = [NSJSONSerialization JSONObjectWithData:commentsJSONData
                                                           options:0
                                                             error:NULL];
                if(comments){
                    for(id comment in comments){
                        NSString *body = [comment valueForKey:@"Body"];
                        NSLog(@"body: %@", body);
                        
                        NSString *commentDateStr = [comment objectForKey:@"CommentDate"];
                        NSDate *commentDate =  [Report extractJitBitDate:commentDateStr];
                        
                        NSLog(@"%@", commentDate);
                        [Comment commentWithBody:body onDate:commentDate fromReport:report inManagedObjectContext:report.managedObjectContext];
                        [report.managedObjectContext save:NULL];
                    }
                }
               
            }
        }
        
    }];
    [task resume];
}




- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.locationDescription.text =  self.report.loc_desc;
    self.fullDescription.text = self.report.desc;
    self.photoCollectionView.delegate = self;
    self.photoCollectionView.dataSource = self;
    self.photos =  [NSArray arrayWithArray:[self.report.photos allObjects]];
    // Zoom map to region and add pin
    [self setupMap];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
    }else{
        
        UIImageView *photoImageView = (UIImageView *)[cell viewWithTag:100];
        [photoImageView sd_setImageWithURL:assetUrl
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
