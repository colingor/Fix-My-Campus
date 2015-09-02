//
//  LocationDetailsViewController.h
//  Estates Audit
//
//  Created by Ian Fieldhouse on 12/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LocationDetailsViewController : UIViewController<UITabBarDelegate>

@property (strong, nonatomic) NSDictionary *location;
@property (strong, nonatomic) NSString *buildingId;

@end
