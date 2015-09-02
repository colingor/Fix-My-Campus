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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
   
    if ([[segue identifier] isEqualToString:@"Send"])
    {
        LocationDetailsViewController *loccationDetailsvc = (LocationDetailsViewController *)segue.destinationViewController;
    }
    
}


@end
