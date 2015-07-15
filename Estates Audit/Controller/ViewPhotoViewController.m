//
//  ViewPhotoViewController.m
//  Estates Audit
//
//  Created by murray king on 13/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "ViewPhotoViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "Report.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ViewPhotoViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
-(void) loadImageAsset;
@end

@implementation ViewPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *status = self.photo.report.status;
    
    // Only allow option to delete unsubmitted reports at present
    if([status isEqualToString:@"unsubmitted"]){
        self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(deleteAction:)];
    }
    
    // Do any additional setup after loading the view.
    [self loadImageAsset];
    
    self.scrollView.delegate=self;
    
    self.scrollView.minimumZoomScale=0.5;
    
    self.scrollView.maximumZoomScale=6.0;
    
    self.scrollView.contentSize=self.imageView.frame.size;
    
    self.spinner.hidesWhenStopped = YES;

    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

enum AlertButtonIndex : NSInteger
{
    AlertButtonNo,
    AlertButtonYes
};


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView

{
    
    return self.imageView;
    
}


-(void)deleteAction:(UIBarButtonItem *)sender{
    
    [[[UIAlertView alloc] initWithTitle:@"Delete Photo" message:@"Are you sure you want to delete this photo?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index
{
    if (index == AlertButtonYes){
        
        NSManagedObjectContext *managedObjectContext = self.photo.managedObjectContext;

        [managedObjectContext deleteObject:self.photo];
        [managedObjectContext save:NULL];
   
        // Return to previous controller
        [self.navigationController popViewControllerAnimated:YES];
    }
}


                                            
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) loadImageAsset{
    
    [self.spinner startAnimating];
    
    NSURL *assetUrl = [NSURL URLWithString:self.photo.url];
    __block UIImage *image;
    
    if([[assetUrl scheme] isEqualToString:@"assets-library"]){
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library assetForURL:assetUrl
                 resultBlock:^(ALAsset *asset)  {
                     NSDictionary *metadata = asset.defaultRepresentation.metadata;
                     
                     // Have to check orientation from exif as using image.imageOrientation always returns UIImageOrientationUp
                     // which isn't necessarily the case
                     NSDictionary *imageMetadata = [[NSMutableDictionary alloc] initWithDictionary:metadata];
                     NSNumber *orientation = [imageMetadata valueForKey:@"Orientation"];
                     
                     NSLog(@"Orientation : %@", orientation);
                     
                     ALAssetRepresentation *rep = [asset defaultRepresentation];
                     CGImageRef iref = [rep fullResolutionImage];
                     
                     if (iref) {
                         UIImage *image = [UIImage imageWithCGImage:iref];
                         
                         CGImageRef cgRef = image.CGImage;
                         
                         // recreate image with adjusted orientation if appropriate
                         if([orientation isEqualToNumber:[NSNumber numberWithLong:6]]){
                             image = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationRight];
                         }else if([orientation isEqualToNumber:[NSNumber numberWithLong:3]]){
                             image = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationDown];
                         }else if([orientation isEqualToNumber:[NSNumber numberWithLong:8]]){
                             image = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationLeft];
                         }
                         
                         [self setImageAndStopSpinner:image];
                         
                     }
                 }
                failureBlock:^(NSError *error) {
                    NSLog(@"Error attempting to load image from assets: %@", error);
                }];
        
        
    } else if (([[assetUrl scheme] isEqualToString:@"http"]) || ([[assetUrl scheme] isEqualToString:@"https"])){
        
        // Load image from JitBit with SDWebImage so it handles caching
        [self.imageView sd_setImageWithURL:assetUrl
                          placeholderImage:nil
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                     NSLog(@"Image loading completed");
                                     [self setImageAndStopSpinner:image];
                                 }];
        
    } else {
        image = [UIImage imageWithContentsOfFile:self.photo.url];
        [self setImageAndStopSpinner:image];
    }
    
}


- (void) setImageAndStopSpinner:(UIImage *)image {

    [self.imageView setImage:image];
    [self.spinner stopAnimating];
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
