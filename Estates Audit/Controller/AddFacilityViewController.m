//
//  AddFacilityViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 01/09/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "AddFacilityViewController.h"
#import "LocationDetailsViewController.h"
#import "ElasticSearchAPI.h"
#import "ActionSheetLocalePicker.h"
#import "ActionSheetStringPicker.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ViewPhotoViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface AddFacilityViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *facilityDescription;

@property (weak, nonatomic) IBOutlet UITextView *facilityArea;

@property (weak, nonatomic) IBOutlet UITextView *facilityType;

@property (weak, nonatomic) IBOutlet UILabel *facilityLabel;

@property (weak, nonatomic) IBOutlet UILabel *selectedPictureLabel;

@property (strong, nonatomic) NSMutableArray *areas;

@property (weak, nonatomic) IBOutlet UICollectionView *photoCollectionView;

@property (strong, nonatomic) NSMutableArray *types;

@property (weak, nonatomic) IBOutlet UIImageView *cameraIcon;
@property (weak, nonatomic) IBOutlet UIImageView *cameraRoll;
@property (nonatomic) UIImagePickerController *imagePickerController;

@end

@implementation AddFacilityViewController 

NSString *const ADD_NEW_AREA = @"Add new area…";
NSString *const ADD_NEW_TYPE = @"Add new type…";

-(void)awakeFromNib{
    
    ElasticSearchAPI *esApi = [ElasticSearchAPI sharedInstance];
    
    _areas = [NSMutableArray array];
    _types = [NSMutableArray array];
    
    // Populate the areas and types pickers by querying ElasticSearch for
    // existing values.  Note that we only add 'Add new…' elements if iOS 8
    // or above as the current implementation of adding new fields is not supported in iOS 7
    [esApi getAllAreasWithCompletion:^(NSMutableArray *areas) {
        
        _areas = areas;
        if(IS_OS_8_OR_LATER) {
            [_areas addObject:ADD_NEW_AREA];
        }
    }];
    
    [esApi getAllTypesWithCompletion:^(NSMutableArray *types) {
        
        _types = types;
        if(IS_OS_8_OR_LATER){
            [_types addObject:ADD_NEW_TYPE];
        }
    }];
}

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
    
    NSString *buildingName = self.buildingInfo[@"buildingName"];

    self.facilityLabel.text = [NSString stringWithFormat:@"%@ %@", self.facilityLabel.text, buildingName];
    
    UITapGestureRecognizer *areaTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(areaTap)];
    [self.facilityArea addGestureRecognizer:areaTapGesture];
    
    UITapGestureRecognizer *typeTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(typeTap)];
    [self.facilityType addGestureRecognizer:typeTapGesture];
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [tap setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tap];
    
    
    [self.photoCollectionView setHidden:YES];
    [self.selectedPictureLabel setHidden:YES];

    
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

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)areaTap {
    
    [ActionSheetStringPicker showPickerWithTitle:@"Select an area"
                                            rows:self.areas
                                initialSelection:0
                                       doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                           
                                           NSLog(@"Selected Value: %@", selectedValue);
                                           
                                           if(IS_OS_8_OR_LATER) {
                                               if([selectedValue isEqualToString:ADD_NEW_AREA]){
                                                   
                                                   self.facilityArea.text = @"";
                                                   
                                                   UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add area"
                                                                                                                  message:@"Add a new area"
                                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                   [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                                                       // optionally configure the text field
                                                       textField.keyboardType = UIKeyboardTypeAlphabet;
                                                   }];
                                                   
                                                   
                                                   UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                      style:UIAlertActionStyleDefault
                                                                                                    handler:^(UIAlertAction *action) {
                                                                                                        UITextField *textField = [alert.textFields firstObject];
                                                                                                        self.facilityArea.text = textField.text;
                                                                                                    }];
                                                   [alert addAction:okAction];
                                                   
                                                   [self presentViewController:alert animated:YES completion:nil];
                                                   
                                                   
                                               }else{
                                                   self.facilityArea.text = selectedValue;
                                               }
                                           }else{
                                               self.facilityArea.text = selectedValue;
                                           }
                                           
                                       }
                                     cancelBlock:^(ActionSheetStringPicker *picker) {
                                         NSLog(@"Block Picker Canceled");
                                     }
                                          origin:self.facilityArea];
}

- (void)typeTap {
    
    [ActionSheetStringPicker showPickerWithTitle:@"Select a type"
                                            rows:self.types
                                initialSelection:0
                                       doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                           
                                           NSLog(@"Selected Value: %@", selectedValue);
                                           
                                           if(IS_OS_8_OR_LATER) {
                                               
                                               if([selectedValue isEqualToString:ADD_NEW_TYPE]){
                                                   
                                                   self.facilityType.text = @"";
                                                   
                                                   UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add type"
                                                                                                                  message:@"Add a new type"
                                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                   [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                                                       // optionally configure the text field
                                                       textField.keyboardType = UIKeyboardTypeAlphabet;
                                                   }];
                                                   
                                                   
                                                   UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                      style:UIAlertActionStyleDefault
                                                                                                    handler:^(UIAlertAction *action) {
                                                                                                        UITextField *textField = [alert.textFields firstObject];
                                                                                                        self.facilityType.text = textField.text;
                                                                                                    }];
                                                   [alert addAction:okAction];
                                                   
                                                   [self presentViewController:alert animated:YES completion:nil];
                                                   
                                                   
                                               }
                                               else{
                                                   self.facilityType.text = selectedValue;
                                               }
                                           }else{
                                               self.facilityType.text = selectedValue;
                                           }
                                           
                                       }
                                     cancelBlock:^(ActionSheetStringPicker *picker) {
                                         NSLog(@"Block Picker Canceled");
                                     }
                                          origin:self.facilityType];
}


- (void)finishAndUpdate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.photoCollectionView reloadData];
    });
}

- (void)deleteImage
{
    self.photo = nil;
    [self finishAndUpdate];
}


#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    [self.photoCollectionView setHidden:NO];
    [self.selectedPictureLabel setHidden:NO];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    NSURL *imageUrl = [info valueForKey:UIImagePickerControllerReferenceURL];
    
    if (imageUrl == nil) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            [library writeImageToSavedPhotosAlbum:((UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage]).CGImage
                                         metadata:[info objectForKey:UIImagePickerControllerMediaMetadata]
                                  completionBlock:^(NSURL *imageUrl, NSError *error) {
                                  
                                      NSString *url = [imageUrl absoluteString];
                                      self.photo = url;
                                      
                                      [self finishAndUpdate];
                                  }];
        });
        
    }else{
        // Get image url and add to Report
        NSString *url = [imageUrl absoluteString];
        self.photo = url;
        
        [self finishAndUpdate];
    }
    
    
}



#pragma mark - UICOLLECTION view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
  
    if(self.photo){
       return 1;
    }
    return 0;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"Cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
   
    NSURL *assetUrl = [NSURL URLWithString:self.photo];
    
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
    }  else {
        UIImageView *photoImageView = (UIImageView *)[cell viewWithTag:100];
        
        [photoImageView sd_setImageWithURL:[NSURL URLWithString:[self.photo stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                          placeholderImage:[UIImage imageNamed:DEFAULT_CELL_IMAGE]];
        
    }

    
    return cell;
}








- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}




#pragma mark - Navigation


#define UNWIND_SEGUE_IDENTIFIER @"Send"

- (void)alert:(NSString *)message
{
    [[[UIAlertView alloc] initWithTitle:@"Incomplete Information" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
   if (![identifier isEqualToString:UNWIND_SEGUE_IDENTIFIER]) {
       return NO;
   }
    
    NSString *facilityDescription = self.facilityDescription.text;
    NSString *facilityArea = self.facilityArea.text;
    NSString *facilityType = self.facilityType.text;
    
    if (![facilityArea length] || [facilityArea isEqualToString:@"Select an area…"]) {
        [self alert:@"Please enter an area"];
        return NO;
    }
    if (![facilityType length] || [facilityType isEqualToString:@"Select a type…"]) {
        [self alert:@"Please enter a type"];
        return NO;
    }
    if (![facilityDescription length]) {
        [self alert:@"Please enter a description"];
        return NO;
    }
    
   
    NSDictionary *f = @{
                        @"description" :facilityDescription,
                        @"notes" : @"",
                        @"image" : @"",
                        @"type": facilityType
                        };
    
    NSMutableDictionary *facility = [f mutableCopy];
    
    NSMutableArray *buildingAreas = [self.source valueForKeyPath:@"properties.information"];
    
    BOOL areaExists = NO;
    
    for (NSMutableDictionary *area in buildingAreas){

        if([area[@"area"] isEqualToString:facilityArea]){
         
            // Add to existing area
            NSMutableArray *areaItems = [area valueForKey:@"items"];
            [areaItems addObject:facility];
            areaExists = YES;
            break;
        }
    }
    
    if(!areaExists){
        // Add new area
        NSDictionary *newArea = @{@"area":facilityArea, @"items": @[facility]};
        [buildingAreas addObject:newArea];
        
    }
    
   
  
    

    // We do the actual POST in LocationDetailViewController as self.source contains the new facility
    return YES;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
   
    if ([[segue identifier] isEqualToString:UNWIND_SEGUE_IDENTIFIER])
    {
        LocationDetailsViewController *locationDetailsvc = (LocationDetailsViewController *)segue.destinationViewController;
        
        if(self.photo){
            

            NSString *facilityArea = self.facilityArea.text;
            
            [[ElasticSearchAPI sharedInstance] postImageToEstatesAPI:self.photo
                                                       forBuildingId:self.buildingInfo[@"buildingId"]
                                                              inArea:facilityArea
                                                      withCompletion:^(NSDictionary *result) {
                                                          
                                                          NSLog(@"Image posted successfully");
                                                          
                                                          NSDictionary *filesDict = [result valueForKeyPath:@"result.files"];
                                                          NSString *imageFileName = [[filesDict allKeys] objectAtIndex:0];
                                                          
                                                          // Add imageFileName to area
                                                          BOOL areaFound = NO;
                                                          
                                                          for (NSMutableDictionary *area in [self.source valueForKeyPath:@"properties.information"]){
                                                              
                                                              if(!areaFound){
                                                                  
                                                                  if([area[@"area"] isEqualToString:facilityArea]){
                                                                      
                                                                      // Add to existing area
                                                                      NSMutableArray *areaItems = [area valueForKey:@"items"];
                                                                      
                                                                      for (NSMutableDictionary *area in areaItems){
                                                                          
                                                                          // Find the correct item
                                                                          if([area[@"description"] isEqualToString:self.facilityDescription.text] &&
                                                                             [area[@"type"] isEqualToString:self.facilityType.text]){
                                                                              
                                                                              // Assume this is the area we want to update
                                                                              areaFound = YES;
                                                                              area[@"image"] = imageFileName;
                                                                              
                                                                              // Ensure this is posted to ElasticSearch
                                                                              [[ElasticSearchAPI sharedInstance] postBuildingFacilityToBuilding:self.buildingInfo[@"buildingId"] withQueryJson: self.source
                                                                                                                                 withCompletion:^(NSDictionary *result) {
                                                                                                                                     NSLog(@"Image name added to record");
                                                                                                                                     [locationDetailsvc refresh:nil];
                                                                                                                                 }];
                                                                              break;
                                                                          }
                                                                      }
                                                                      break;
                                                                  }
                                                              }
                                                          }
                                                      }];
            
        }

        
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle: nil];
    ViewPhotoViewController* controller = (ViewPhotoViewController*)[mainStoryboard instantiateViewControllerWithIdentifier:@"viewPhoto"];
    controller.photoUrl = self.photo;
    
    [self.navigationController pushViewController:controller animated:YES];
}


@end
