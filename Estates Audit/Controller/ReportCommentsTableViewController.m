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
#import "Comment+Create.h"
#import "Report+Create.h"

@interface ReportCommentsTableViewController ()

@end

@implementation ReportCommentsTableViewController


- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserverForName:ReportDatabaseAvailabilityNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      self.managedObjectContext = note.userInfo[ReportDatabaseAvailabilityContext];
                                                  }];
}

- (IBAction)refresh:(id)sender {
    
    [self.refreshControl beginRefreshing];
    [self processComments:self.report];
}

- (void)processComments:(Report *)report
{
    NSString *apiStr = [NSString stringWithFormat:@"https://eaudit.jitbit.com/helpdesk/api/comments?id=%@", report.ticket_id];
    
    NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
    
    // TODO: Credentials in code is bad...
    [request setValue:@"Basic Y2dvcm1sZTFAc3RhZmZtYWlsLmVkLmFjLnVrOmVzdGF0ZXNhdWRpdDM=" forHTTPHeaderField:@"Authorization"];
    
    // another configuration option is backgroundSessionConfiguration (multitasking API required though)
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    // create the session without specifying a queue to run completion handler on (thus, not main queue)
    // we also don't specify a delegate (since completion handler is all we need)
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"%@",error);
        }else{
            
            NSDictionary *comments;
            NSData *commentsJSONData = [NSData dataWithContentsOfURL:location];
            if (commentsJSONData) {
                comments = [NSJSONSerialization JSONObjectWithData:commentsJSONData
                                                           options:0
                                                             error:NULL];
                if(comments){
                    for(id comment in comments){
                        NSString *body = [comment valueForKey:@"Body"];
                        
                        NSString *commentDateStr = [comment objectForKey:@"CommentDate"];
                        NSDate *commentDate =  [Report extractJitBitDate:commentDateStr];
                        
                        [Comment commentWithBody:body onDate:commentDate fromReport:report inManagedObjectContext:report.managedObjectContext];
                        [report.managedObjectContext save:NULL];
                    }
                [self.refreshControl endRefreshing];
                }
               
            }
        }
        
    }];
    [task resume];
}



- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    [self fetchResults:managedObjectContext];
}


- (void)setReport:(Report *)report
{
    _report = report;
    [self processComments:self.report];
    [self fetchResults:report.managedObjectContext];
}


- (void)fetchResults:(NSManagedObjectContext *)context
{
    if (context) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Comment"];
        request.predicate = [NSPredicate predicateWithFormat:@"report = %@", self.report];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date"
                                                                  ascending:NO
                                                                   selector:@selector(compare:)]];
        
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


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

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
