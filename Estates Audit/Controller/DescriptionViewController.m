//
//  DescriptionViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 16/04/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "DescriptionViewController.h"
#import "SummaryViewController.h"

@interface DescriptionViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *problemDescription;

@end

@implementation DescriptionViewController


- (void)setReport:(Report *)report
{
    _report = report;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Ensure the UITextView is selected automatically
    [self.problemDescription becomeFirstResponder];
    
    self.problemDescription.text = self.report.desc;
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [tap setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tap];

}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    NSString *trimmedDescription = [self.problemDescription.text stringByTrimmingCharactersInSet:
                                    [NSCharacterSet whitespaceCharacterSet]];
    
    if ( trimmedDescription == nil || [trimmedDescription isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Problem Description" message: @"Please Enter a Problem Description" delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return NO;
    } else {
        
        return YES;
    }
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
