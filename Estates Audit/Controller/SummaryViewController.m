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

@interface SummaryViewController ()

@property (weak, nonatomic) IBOutlet UITextView *locationDescription;
@property (weak, nonatomic) IBOutlet UITextView *problemDescription;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

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
    // Do any additional setup after loading the view.
    self.locationDescription.text = self.report.loc_desc;
    self.problemDescription.text = self.report.desc;
}



-(void)loadImageFromAssets{
    
    NSSet *photos = self.report.photos;
    
    NSArray *photoArray = [photos allObjects];
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



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
