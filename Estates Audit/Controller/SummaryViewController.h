//
//  SummaryViewController.h
//  Estates Audit
//
//  Created by Colin Gormley on 16/04/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Report.h"

@interface SummaryViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) Report *report;
@property (nonatomic, weak) IBOutlet UICollectionView *photoCollectionView;
@property (nonatomic, strong) NSArray *photos;

@end
