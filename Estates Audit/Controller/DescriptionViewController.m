//
//  DescriptionViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 16/04/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "DescriptionViewController.h"
#import "SummaryViewController.h"

@interface DescriptionViewController ()

@property (weak, nonatomic) IBOutlet UITextView *problemDescription;

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
    
    if ([[segue identifier] isEqualToString:@"Show Summary"]){
        if ([segue.destinationViewController isKindOfClass:[SummaryViewController class]]) {
            SummaryViewController *sumvc = (SummaryViewController *)segue.destinationViewController;
            
            self.report.desc = self.problemDescription.text;
            
            // Set report in next controller
            sumvc.report = self.report;
        }
    }
    
}

@end
