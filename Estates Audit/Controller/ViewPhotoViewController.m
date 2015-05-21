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


- (void) loadImageAsset{
    NSURL *assetUrl = [NSURL URLWithString:self.photo.url];
    
    if([[assetUrl scheme] isEqualToString:@"assets-library"]){
        ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset){
            ALAssetRepresentation *rep = [myasset defaultRepresentation];
            CGImageRef iref = [rep fullResolutionImage];
            
            if (iref) {
                UIImage *image = [UIImage imageWithCGImage:iref];
                [self scaleThenPopulateImageViewWithImage:image];
            }
        };
        
        ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
        [assetslibrary assetForURL:assetUrl
                       resultBlock:resultblock
                      failureBlock: ^(NSError *myerror){
                          NSLog(@"Can't get image - %@",[myerror localizedDescription]);
                      }];
    } else if (([[assetUrl scheme] isEqualToString:@"http"]) || ([[assetUrl scheme] isEqualToString:@"https"])){
        NSData *imageData = [NSData dataWithContentsOfURL:assetUrl];
        UIImage *image = [UIImage imageWithData:imageData];
        [self scaleThenPopulateImageViewWithImage:image];
    } else {
        UIImage *image = [UIImage imageWithContentsOfFile:self.photo.url];
        [self scaleThenPopulateImageViewWithImage:image];
    }
}


- (void) scaleThenPopulateImageViewWithImage:(UIImage *)image {
    UIImage *scaledImage = [self imageWithImage:image
                               scaledToMaxWidth:[self.imageView bounds].size.width
                                      maxHeight:[self.imageView bounds].size.height];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self imageView].contentMode = UIViewContentModeScaleAspectFit;
        [self.imageView setImage:scaledImage];
    });
}


- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}


- (UIImage *)imageWithImage:(UIImage *)image scaledToMaxWidth:(CGFloat)width maxHeight:(CGFloat)height {
    CGFloat oldWidth = image.size.width;
    CGFloat oldHeight = image.size.height;
    
    CGFloat scaleFactor = (oldWidth > oldHeight) ? width / oldWidth : height / oldHeight;
    
    CGFloat newHeight = oldHeight * scaleFactor;
    CGFloat newWidth = oldWidth * scaleFactor;
    CGSize newSize = CGSizeMake(newWidth, newHeight);
    
    return [self imageWithImage:image scaledToSize:newSize];
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
