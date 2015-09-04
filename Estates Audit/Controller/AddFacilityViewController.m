//
//  AddFacilityViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 01/09/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "AddFacilityViewController.h"
#import "LocationDetailsViewController.h"
#import "ElasticSeachAPI.h"

@interface AddFacilityViewController ()


@property (weak, nonatomic) IBOutlet UITextView *facilityDescription;

@property (weak, nonatomic) IBOutlet UITextView *facilityArea;

@property (weak, nonatomic) IBOutlet UITextView *facilityType;

@property (weak, nonatomic) IBOutlet UILabel *facilityLabel;

@end

@implementation AddFacilityViewController



- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *buildingName = self.buildingInfo[@"buildingName"];
    
    self.facilityLabel.text = [NSString stringWithFormat:@"%@ %@", self.facilityLabel.text, buildingName];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Navigation


#define UNWIND_SEGUE_IDENTIFIER @"Send"

- (void)alert:(NSString *)message
{
    [[[UIAlertView alloc] initWithTitle:@"Incomplete Information" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
   if (![identifier isEqualToString:UNWIND_SEGUE_IDENTIFIER]) {
       return NO;
   }
    
    NSString *facilityDescription = self.facilityDescription.text;
    NSString *facilityArea = self.facilityArea.text;
    NSString *facilityType = self.facilityType.text;
    
    if (![facilityDescription length]) {
        [self alert:@"Please enter a description"];
        return NO;
    }
    if (![facilityArea length]) {
        [self alert:@"Please enter an area"];
        return NO;
    }
    if (![facilityType length]) {
        [self alert:@"Please enter a type"];
        return NO;
    }

    NSDictionary *facility = @{
                               @"description" :facilityDescription,
                               @"notes" : @"",
                               @"image" : @"",
                               @"type": facilityType
                               };
    
    
    NSMutableArray *buildingAreas = [self.source valueForKeyPath:@"properties.information"];
    
    BOOL areaExists = NO;
    
    for (NSMutableDictionary *area in buildingAreas){

        if([area[@"area"] isEqualToString:facilityArea]){
         
            // Add to existing area
            NSMutableArray *areaItems = [area valueForKey:@"items"];
            [areaItems addObject:facility];
            areaExists = YES;
            break;
        }
    }
    
    if(!areaExists){
        // Add new area
        NSDictionary *newArea = @{@"area":facilityArea, @"items": @[facility]};
        [buildingAreas addObject:newArea];
        
    }

    // We do the actual POST in LocationDetailViewController as self.source contains the new facility
    return YES;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
   
//    if ([[segue identifier] isEqualToString:UNWIND_SEGUE_IDENTIFIER])
//    {
//        LocationDetailsViewController *locationDetailsvc = (LocationDetailsViewController *)segue.destinationViewController;
//    }
    
}


@end
