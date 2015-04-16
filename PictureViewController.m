//
//  PictureViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 26/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import "PictureViewController.h"
#import "DescriptionViewController.h"

@interface PictureViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) NSMutableArray *capturedImages;
@property (nonatomic) UIImagePickerController *imagePickerController;

@end

@implementation PictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
     self.capturedImages = [[NSMutableArray alloc] init];
    // Do any additional setup after loading the view.
}

- (void)setReport:(Report *)report
{
    _report = report;
   [self setupFetchedResultsController];
}

- (void)setupFetchedResultsController
{
//    NSManagedObjectContext *context = self.report.managedObjectContext;
//    
//    if (context) {
//        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Report"];
//        request.predicate = [NSPredicate predicateWithFormat:@"whoTook = %@", self.photographer];
//        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"title"
//                                                                  ascending:YES
//                                                                   selector:@selector(localizedStandardCompare:)]];
//        
//        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
//                                                                            managedObjectContext:context
//                                                                              sectionNameKeyPath:nil
//                                                                                       cacheName:nil];
//    } else {
//        self.fetchedResultsController = nil;
//    }
}

- (IBAction)showImagePickerForCamera:(id)sender {
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
}

- (IBAction)showImagePickerForPhotoPicker:(id)sender {
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    if (self.imageView.isAnimating)
    {
        [self.imageView stopAnimating];
    }
    
    if (self.capturedImages.count > 0)
    {
        [self.capturedImages removeAllObjects];
    }
    
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
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    if ([self.capturedImages count] > 0)
    {
        if ([self.capturedImages count] == 1)
        {
            // Camera took a single picture.
            [self.imageView setImage:[self.capturedImages objectAtIndex:0]];
        }
        else
        {
            // Camera took multiple pictures; use the list of images for animation.
            self.imageView.animationImages = self.capturedImages;
            self.imageView.animationDuration = 5.0;    // Show each captured photo for 5 seconds.
            self.imageView.animationRepeatCount = 0;   // Animate forever (show all photos).
            [self.imageView startAnimating];
        }
        
        // To be ready to start again, clear the captured images array.
        [self.capturedImages removeAllObjects];
    }
    
    self.imagePickerController = nil;
}


#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    [self.capturedImages addObject:image];
    
    
    [self finishAndUpdate];
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
@end
