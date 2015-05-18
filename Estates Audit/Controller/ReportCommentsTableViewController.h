//
//  ReportCommentsTableViewController.h
//  Estates Audit
//
//  Created by Colin Gormley on 18/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "AcceptsManagedContext.h"
#import "CoreDataTableViewController.h"
#import "Report.h"

@interface ReportCommentsTableViewController : CoreDataTableViewController<AcceptsManagedContext, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong)Report * report;

@end
