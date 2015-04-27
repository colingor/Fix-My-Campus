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

@interface ReportDetailsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *locationDescription;


@end

@implementation ReportDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.locationDescription.text =  self.report.loc_desc;
    self.photoCollectionView.delegate = self;
    self.photoCollectionView.dataSource = self;
    self.photos =  [NSArray arrayWithArray:[self.report.photos allObjects]];
    
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
            cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photo-frame.png"]];
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

@end
