//
//  LocationViewController.h
//  Estates Audit
//
//  Created by Colin Gormley on 26/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AcceptsManagedContext.h"
@interface LocationViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, AcceptsManagedContext>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSMutableDictionary *reportDict;

@end
