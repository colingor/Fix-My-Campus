//
//  AddFacilityViewController.h
//  Estates Audit
//
//  Created by Colin Gormley on 01/09/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddFacilityViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) NSDictionary *buildingInfo;
@property (strong, nonatomic) NSMutableDictionary *source;
@property (nonatomic, strong) NSString *photo;

- (void)deleteImage;

@end
