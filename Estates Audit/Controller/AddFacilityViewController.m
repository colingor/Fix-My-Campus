//
//  AddFacilityViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 01/09/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "AddFacilityViewController.h"
#import "LocationDetailsViewController.h"

@interface AddFacilityViewController ()

@property (weak, nonatomic) IBOutlet UITextView *facilityDescription;
@property (weak, nonatomic) IBOutlet UITextField *facilityType;

@property (weak, nonatomic) IBOutlet UILabel *facilityLabel;

@end

@implementation AddFacilityViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *buildingName = self.buildingInfo[@"buildingName"];
    NSString *buildingId = self.buildingInfo[@"buildingId"];
    
    self.facilityLabel.text = [NSString stringWithFormat:@"%@ %@", self.facilityLabel.text, buildingName];

}
- (IBAction)send:(id)sender {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation


#define UNWIND_SEGUE_IDENTIFIER @"Send"

- (void)alert:(NSString *)message
{
    [[[UIAlertView alloc] initWithTitle:@"Incomplete Information" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:UNWIND_SEGUE_IDENTIFIER]) {
        if (![self.facilityDescription.text length]) {
            [self alert:@"Please enter a description"];
            return NO;
        }
    }
    return YES;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
   
    if ([[segue identifier] isEqualToString:UNWIND_SEGUE_IDENTIFIER])
    {
        LocationDetailsViewController *loccationDetailsvc = (LocationDetailsViewController *)segue.destinationViewController;
    }
    
}


@end