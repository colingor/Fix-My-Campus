//
//  DescriptionViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 16/04/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "DescriptionViewController.h"

@interface DescriptionViewController ()

@end

@implementation DescriptionViewController



- (void)setReport:(Report *)report
{
    _report = report;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"Describe Problem"]){
        if ([segue.destinationViewController isKindOfClass:[DescriptionViewController class]]) {
            NSString *locDesc  =self.report.loc_desc;
            NSNumber *lat = self.report.lat;
            NSLog(@"%@  %@", locDesc, lat);
            DescriptionViewController *descvc = (DescriptionViewController *)segue.destinationViewController;
         
            
            // Set report in next controller
            descvc.report = self.report;
            
            
        }
    }
    
}

@end
