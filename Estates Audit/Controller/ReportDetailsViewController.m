//
//  ReportDetailsViewController.m
//  Estates Audit
//
//  Created by murray king on 27/04/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "ReportDetailsViewController.h"

@interface ReportDetailsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *locationDescription;


@end

@implementation ReportDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.locationDescription.text =  self.report.loc_desc;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
