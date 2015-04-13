//
//  AppDelegate+MOC.h
//  GoGeo Mobile
//
//  Created by Colin Gormley on 13/04/2015.
//  Copyright (c) 2014 EDINA. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate (MOC)

- (NSManagedObjectContext *)createMainQueueManagedObjectContext;

@end
