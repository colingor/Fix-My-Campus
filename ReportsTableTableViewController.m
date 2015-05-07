//
//  ReportsTableTableViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 26/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import "ReportsTableTableViewController.h"
#import "Report+Create.h"
#import "Photo+Create.h"
#import "AppDelegate.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ReportDetailsViewController.h"

@interface ReportsTableTableViewController ()

@end

@implementation ReportsTableTableViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = NO;
    
    //get the saved reports

    
    NSArray *reports = [Report allReportsInManagedObjectContext:self.managedObjectContext];
    self.reports = reports;
    NSLog(@"reports %@ ", reports);
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (IBAction)refresh:(id)sender {
   
    NSLog(@"Refreshing");
    
    [self.refreshControl beginRefreshing];
    
    // Trigger calls to jitBit
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate syncWithJitBit];
 
    appDelegate.onCompletion = ^{
        [self.refreshControl endRefreshing];
        NSLog(@"End refreshing");
    };
}



#pragma mark - Table view data source


 - (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {     
    return 1;
}



 - (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.reports count];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reportcell" forIndexPath:indexPath];
    Report * report = [self.reports objectAtIndex:indexPath.row];
    
    cell.textLabel.text = report.loc_desc ;
    NSSet * photos = report.photos;
    Photo * photo = [photos anyObject];
    
    NSURL *assetUrl = [NSURL URLWithString:photo.url];
    
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        CGImageRef iref = [myasset thumbnail];
        if (iref) {
            UIImage *thumbImage = [UIImage imageWithCGImage:iref];
               dispatch_async(dispatch_get_main_queue(), ^{
        /* This is the main thread again, where we set the tableView's image to
         be what we just fetched. */
            cell.imageView.image = thumbImage;
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


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    // Ensure context is set if we want to create a new report
    if ([segue.destinationViewController conformsToProtocol:@protocol(AcceptsManagedContext)]) {
        
        // Need to pass managedObjectContext through
        id<AcceptsManagedContext> controller = segue.destinationViewController;
        controller.managedObjectContext  = self.managedObjectContext;
    }
    
    
    if ([[segue identifier] isEqualToString:@"ReportDetails"])
    {
        ReportDetailsViewController *detailViewController =
        [segue destinationViewController];

        NSIndexPath *myIndexPath = [self.tableView
                                    indexPathForSelectedRow];

        Report *selectedReport  = self.reports[myIndexPath.row];
        detailViewController.report = selectedReport;
        
        
    }
}

@end
