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
#import "ActionSheetLocalePicker.h"
#import "ActionSheetStringPicker.h"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface AddFacilityViewController ()

@property (weak, nonatomic) IBOutlet UITextView *facilityDescription;

@property (weak, nonatomic) IBOutlet UITextView *facilityArea;

@property (weak, nonatomic) IBOutlet UITextView *facilityType;

@property (weak, nonatomic) IBOutlet UILabel *facilityLabel;

@property (strong, nonatomic) NSMutableArray *areas;

@property (strong, nonatomic) NSMutableArray *types;

@end

@implementation AddFacilityViewController 

NSString *const ADD_NEW_AREA = @"Add new area…";
NSString *const ADD_NEW_TYPE = @"Add new type…";

- (void)viewDidLoad {
    [super viewDidLoad];

    _areas = [NSMutableArray array];
    [_areas addObject:@"General"];
    [_areas addObject:@"Basement"];
    [_areas addObject:@"First Floor"];
    [_areas addObject:@"Second Floor"];
    [_areas addObject:@"Third Floor"];
    
    if(IS_OS_8_OR_LATER) {
        [_areas addObject:ADD_NEW_AREA];
    }
    
    _types = [NSMutableArray array];
    [_types addObject:@"Car Park"];
    [_types addObject:@"Entrance"];
    [_types addObject:@"Stairs"];
    [_types addObject:@"Offices"];
    [_types addObject:@"Reception"];
    
    if(IS_OS_8_OR_LATER){
       [_types addObject:ADD_NEW_TYPE];
    }
    
    NSString *buildingName = self.buildingInfo[@"buildingName"];

    self.facilityLabel.text = [NSString stringWithFormat:@"%@ %@", self.facilityLabel.text, buildingName];
    
    UITapGestureRecognizer *areaTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(areaTap)];
    [self.facilityArea addGestureRecognizer:areaTapGesture];
    
    UITapGestureRecognizer *typeTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(typeTap)];
    [self.facilityType addGestureRecognizer:typeTapGesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)areaTap {
    
    [ActionSheetStringPicker showPickerWithTitle:@"Select an area"
                                            rows:self.areas
                                initialSelection:0
                                       doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                           
                                           NSLog(@"Selected Value: %@", selectedValue);
                                           
                                           if(IS_OS_8_OR_LATER) {
                                               if([selectedValue isEqualToString:ADD_NEW_AREA]){
                                                   
                                                   self.facilityArea.text = @"";
                                                   
                                                   UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add area"
                                                                                                                  message:@"Add a new area"
                                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                   [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                                                       // optionally configure the text field
                                                       textField.keyboardType = UIKeyboardTypeAlphabet;
                                                   }];
                                                   
                                                   
                                                   UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                      style:UIAlertActionStyleDefault
                                                                                                    handler:^(UIAlertAction *action) {
                                                                                                        UITextField *textField = [alert.textFields firstObject];
                                                                                                        self.facilityArea.text = textField.text;
                                                                                                    }];
                                                   [alert addAction:okAction];
                                                   
                                                   [self presentViewController:alert animated:YES completion:nil];
                                                   
                                                   
                                               }else{
                                                   self.facilityArea.text = selectedValue;
                                               }
                                           }else{
                                               self.facilityArea.text = selectedValue;
                                           }
                                           
                                       }
                                     cancelBlock:^(ActionSheetStringPicker *picker) {
                                         NSLog(@"Block Picker Canceled");
                                     }
                                          origin:self.facilityArea];
}

- (void)typeTap {
    
    [ActionSheetStringPicker showPickerWithTitle:@"Select an type"
                                            rows:self.types
                                initialSelection:0
                                       doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                           
                                           NSLog(@"Selected Value: %@", selectedValue);
                                           
                                           if(IS_OS_8_OR_LATER) {
                                               
                                               if([selectedValue isEqualToString:ADD_NEW_TYPE]){
                                                   
                                                   self.facilityType.text = @"";
                                                   
                                                   UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add type"
                                                                                                                  message:@"Add a new type"
                                                                                                           preferredStyle:UIAlertControllerStyleAlert];
                                                   [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                                                       // optionally configure the text field
                                                       textField.keyboardType = UIKeyboardTypeAlphabet;
                                                   }];
                                                   
                                                   
                                                   UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                      style:UIAlertActionStyleDefault
                                                                                                    handler:^(UIAlertAction *action) {
                                                                                                        UITextField *textField = [alert.textFields firstObject];
                                                                                                        self.facilityType.text = textField.text;
                                                                                                    }];
                                                   [alert addAction:okAction];
                                                   
                                                   [self presentViewController:alert animated:YES completion:nil];
                                                   
                                                   
                                               }
                                               else{
                                                   self.facilityType.text = selectedValue;
                                               }
                                           }else{
                                               self.facilityType.text = selectedValue;
                                           }
                                           
                                       }
                                     cancelBlock:^(ActionSheetStringPicker *picker) {
                                         NSLog(@"Block Picker Canceled");
                                     }
                                          origin:self.facilityType];
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
    if (![facilityArea length] || [facilityArea isEqualToString:@"Select an area…"]) {
        [self alert:@"Please enter an area"];
        return NO;
    }
    if (![facilityType length] || [facilityType isEqualToString:@"Select a type…"]) {
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
