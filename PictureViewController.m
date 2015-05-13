//
//  PictureViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 26/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import "PictureViewController.h"
#import "DescriptionViewController.h"
#import "Photo+Create.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ViewPhotoViewController.h"

@interface PictureViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>


@property (nonatomic) UIImagePickerController *imagePickerController;
@property (weak, nonatomic) IBOutlet UIImageView *cameraIcon;
@property (weak, nonatomic) IBOutlet UIImageView *cameraRoll;

@end

@implementation PictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
 

    [self.cameraIcon setUserInteractionEnabled:YES];
    UITapGestureRecognizer *cameraClick =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showImagePickerForCamera:)];
    [cameraClick setNumberOfTapsRequired:1];
    [self.cameraIcon addGestureRecognizer:cameraClick];
    
    [self.cameraRoll setUserInteractionEnabled:YES];
    UITapGestureRecognizer *cameraRollClick =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showImagePickerForPhotoPicker:)];
    [cameraRollClick setNumberOfTapsRequired:1];
    [self.cameraRoll addGestureRecognizer:cameraRollClick];
    
    self.photoCollectionView.delegate = self;
    self.photoCollectionView.dataSource = self;
    self.photos =  [NSArray arrayWithArray:[self.report.photos allObjects]];

}

- (void)setReport:(Report *)report
{
    _report = report;
}

- (IBAction)showImagePickerForCamera:(id)sender {
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
}

- (IBAction)showImagePickerForPhotoPicker:(id)sender {
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
  
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    
    if (sourceType == UIImagePickerControllerSourceTypeCamera)
    {
        /*
         The user wants to use the camera interface. Set up our custom overlay view for the camera.
         */
        imagePickerController.showsCameraControls = YES;
        
 
    }
    
    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (void)finishAndUpdate
{
    

    self.imagePickerController = nil;
    self.photos =  [NSArray arrayWithArray:[self.report.photos allObjects]];
    dispatch_async(dispatch_get_main_queue(), ^{
       [self.photoCollectionView reloadData];
    });
    
}


#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{

    [self dismissViewControllerAnimated:YES completion:NULL];
    
    NSURL *imageUrl = [info valueForKey:UIImagePickerControllerReferenceURL];
    
    if (imageUrl == nil) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [library writeImageToSavedPhotosAlbum:((UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage]).CGImage
                                     metadata:[info objectForKey:UIImagePickerControllerMediaMetadata]
                              completionBlock:^(NSURL *imageUrl, NSError *error) {
                                  
                                    NSLog(@"imageUrl %@", imageUrl);
                                    NSString *url = [imageUrl absoluteString];
                                    [Photo photoWithUrl:url fromReport:self.report inManagedObjectContext:self.report.managedObjectContext];
                                    [self finishAndUpdate];
    
                                  
        }];

    });

    }else{
        // Get image url and add to Report
        NSString *url = [imageUrl absoluteString];
        [Photo photoWithUrl:url fromReport:self.report inManagedObjectContext:self.report.managedObjectContext];
        
        [self finishAndUpdate];
    }
    
    
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

   
    
    
    return cell;


}








- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"Describe Problem"]){
        if ([segue.destinationViewController isKindOfClass:[DescriptionViewController class]]) {
            NSString *locDesc  =self.report.loc_desc;
            NSNumber *lat = self.report.lat;
            NSLog(@"%@  %@", locDesc, lat);
            DescriptionViewController *descvc = (DescriptionViewController *)segue.destinationViewController;

            // TODO: Save photo
            
            // Set report in next controller
            descvc.report = self.report;
        }
    }

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
