//
//  AcceptsManagedContext.h
//  Estates Audit
//
//  Created by murray king on 23/04/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AcceptsManagedContext <NSObject>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@end
