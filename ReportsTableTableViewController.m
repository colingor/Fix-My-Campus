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
#import "ReportDatabaseAvailability.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "CustomTableViewCell.h"
#import "ReportCommentsTableViewController.h"

@interface ReportsTableTableViewController ()

@end

@implementation ReportsTableTableViewController

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserverForName:ReportDatabaseAvailabilityNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      self.managedObjectContext = note.userInfo[ReportDatabaseAvailabilityContext];
                                                  }];
}


- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Report"];
    //    request.predicate = [NSPredicate predicateWithFormat:@"active = %@", @YES];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"issue_date"
                                                                  ascending:NO
                                                                   selector:@selector(compare:)]];
    
    
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:@"sectionIdentifier"
                                                                                   cacheName:nil];
}


-(void) viewWillAppear:(BOOL)animated {
    // We need to do this explictely otherwise the navbar won't appear
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
}


- (void)viewDidLoad {
    [super viewDidLoad];

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


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    
    CustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reportcell" forIndexPath:indexPath];
    
    // Reset all the stuff that could have been changed
    cell.contentView.backgroundColor = nil;
    cell.contentView.superview.backgroundColor = [UIColor whiteColor];
    
    UILabel *textLabel = cell.textLabel;
    UILabel *detailTextLabel = cell.detailTextLabel;
    
    textLabel.backgroundColor = [UIColor whiteColor];
    detailTextLabel.backgroundColor = [UIColor whiteColor];
    
    detailTextLabel.font = [UIFont systemFontOfSize:12.0];
    textLabel.font = [UIFont systemFontOfSize:14.0];
    
    Report * report = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSMutableString *text = [NSMutableString string];

    [text appendString:[NSString stringWithFormat:@"ID: %@ ", report.ticket_id]];
    
    if([report.loc_desc length] > 0){
        [text appendString:[NSString stringWithFormat:@"%@", report.loc_desc]];
    }
    
    // Highlight reports marked as updated
    if(report.is_updated.boolValue){

        UIColor *highLightedBackground = [UIColor colorWithRed:0.90 green:0.94 blue:0.98 alpha:1.0];
        
        detailTextLabel.backgroundColor = highLightedBackground;
        detailTextLabel.font = [UIFont boldSystemFontOfSize:12.0];
        
        textLabel.backgroundColor=highLightedBackground;
        textLabel.font = [UIFont boldSystemFontOfSize:14.0];
        
        cell.contentView.superview.backgroundColor = highLightedBackground;
    }
    
    cell.textLabel.text = text;
    cell.detailTextLabel.text = report.status;
    
    NSSet * photos = report.photos;
    Photo * photo = [photos anyObject];
    
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
    }else{
        // TODO: Placeholder
        [cell.imageView sd_setImageWithURL:assetUrl
                          placeholderImage:[UIImage imageNamed:@"MapPinDefaultLeftCallout"]];
    }
    
    return cell;
}

// This overwrites the version in CoreDataTableViewController - if
// this wasn't here, we would have a list down the side of the tableview
// with the first letter of each month.  Comment out this method to
// see what this looks like.
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return nil;
}


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
        
        NSIndexPath *myIndexPath = [self.tableView indexPathForSelectedRow];
        
        Report *selectedReport = [self.fetchedResultsController objectAtIndexPath:myIndexPath];
        
        UITabBarController *tabar=segue.destinationViewController;
        
        
        // Set the report for each of the tabViewController tabs
        ReportDetailsViewController *rdcontroller = [tabar.viewControllers objectAtIndex:0];
        rdcontroller.report = selectedReport;
        
        
        ReportCommentsTableViewController *rccontroller = [tabar.viewControllers objectAtIndex:1];
        rccontroller.report = selectedReport;

    }
}

@end
