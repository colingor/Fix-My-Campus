//
//  ReportCommentsTableViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 18/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "ReportCommentsTableViewController.h"
#import "ReportDatabaseAvailability.h"
#import "Comment.h"
@interface ReportCommentsTableViewController ()

@end

@implementation ReportCommentsTableViewController



- (void)setReport:(Report *)report
{
    _report = report;
    //    self.title = photographer.name;
    [self setupFetchedResultsController];
}



- (void)setupFetchedResultsController
{
    NSManagedObjectContext *context = self.report.managedObjectContext;
    
    if (context) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Comment"];
        request.predicate = [NSPredicate predicateWithFormat:@"report = %@", self.report];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date"
                                                                  ascending:YES
                                                                   selector:@selector(localizedStandardCompare:)]];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:context
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:nil];
    } else {
        self.fetchedResultsController = nil;
    }
}



- (void)viewDidLoad {
    [super viewDidLoad];
}



#pragma mark - Table view data source
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"commentCell" forIndexPath:indexPath];
    
    // Display comment details
    Comment * comment = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = comment.body;
    cell.detailTextLabel.text = [NSDateFormatter localizedStringFromDate:comment.date
                                                          dateStyle:NSDateFormatterLongStyle
                                                          timeStyle:NSDateFormatterNoStyle];
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
    
}


@end
