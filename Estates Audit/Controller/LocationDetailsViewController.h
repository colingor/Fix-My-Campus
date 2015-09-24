//
//  LocationDetailsViewController.h
//  Estates Audit
//
//  Created by Ian Fieldhouse on 12/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LocationDetailsViewController : UIViewController<UITabBarDelegate>

@property (strong, nonatomic) NSMutableDictionary *source;
@property (strong, nonatomic) NSString *buildingId;

extern NSString *const DEFAULT_CELL_IMAGE;
extern NSString *const BASE_IMAGE_URL;


- (void)refresh:(UIRefreshControl *)refreshControl;

@end
