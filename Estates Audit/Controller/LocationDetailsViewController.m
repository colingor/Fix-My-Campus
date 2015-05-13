//
//  LocationDetailsViewController.m
//  Estates Audit
//
//  Created by Ian Fieldhouse on 12/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "LocationDetailsViewController.h"

@interface LocationDetailsViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation LocationDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%@", self.location);
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
