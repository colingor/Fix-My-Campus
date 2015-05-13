//
//  ViewPhotoViewController.m
//  Estates Audit
//
//  Created by murray king on 13/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "ViewPhotoViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewPhotoViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
-(void) loadImageAsset;
@end

@implementation ViewPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self loadImageAsset];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void) loadImageAsset{
    NSURL *assetUrl = [NSURL URLWithString:self.photo.url];
    
    
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset){
        ALAssetRepresentation *rep = [myasset defaultRepresentation];
        CGImageRef iref = [rep fullResolutionImage];
        
        if (iref) {
            UIImage *fullSize = [UIImage imageWithCGImage:iref];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.imageView setImage:fullSize];
            });
            
            
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

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
