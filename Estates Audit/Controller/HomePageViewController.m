//
//  HomePageViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 26/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import "HomePageViewController.h"
#import "LocationViewController.h"

@interface HomePageViewController ()

@end

@implementation HomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = YES;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
   
    if ([[segue identifier] isEqualToString:@"Describe"]){
        if ([segue.destinationViewController isKindOfClass:[LocationViewController class]]) {
            
            // Need to pass managedObjectContext through
            LocationViewController *locvc = (LocationViewController *)segue.destinationViewController;
            locvc.managedObjectContext  = self.managedObjectContext;
        }
    }
}


/*

Example to call messaging


- (IBAction)sendEmail:(id)sender {
    EmailSupportTicket *emailSupportTicket = [[EmailSupportTicket alloc] initWithSubject:@"Subject from iphone" message:@"message from i" imageAttachment:[UIImage imageNamed:@"screenshot"] viewController:self];
    
    [emailSupportTicket sendSupportEmail];


}


- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result) {
        case MFMailComposeResultSent:
            NSLog(@"You sent the email.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"You saved a draft of this email");
            break;
        case MFMailComposeResultCancelled:
            NSLog(@"You cancelled sending this email.");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed:  An error occurred when trying to compose this email");
            break;
        default:
            NSLog(@"An error occurred when trying to compose this email");
            break;
    }
 
    [self dismissViewControllerAnimated:YES completion:NULL];
}



*/

@end
