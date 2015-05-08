//
//  ReportsTableTableViewController.h
//  Estates Audit
//
//  Created by Colin Gormley on 26/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "AcceptsManagedContext.h"
#import "CoreDataTableViewController.h"

@interface ReportsTableTableViewController : CoreDataTableViewController<AcceptsManagedContext, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
