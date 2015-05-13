//
//  ReportDetailsViewController.m
//  Estates Audit
//
//  Created by murray king on 27/04/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "ReportDetailsViewController.h"
#import "Photo+Create.h"
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
