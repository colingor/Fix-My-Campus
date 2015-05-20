//
//  HomePageViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 26/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import "HomePageViewController.h"
#import "LocationViewController.h"
#import "AcceptsManagedContext.h"
#import "AppDelegate.h"
@interface HomePageViewController ()

@end

@implementation HomePageViewController

#define UNWIND_SEGUE_IDENTIFIER @"Login"


-(IBAction) unwindToHome:(UIStoryboardSegue *)segue {
    NSLog(@"Home page");
    //Maybe a call to syn with jitbit?
    
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
 
    // Check if logged in
    if(![appDelegate isLoggedIn]){
        // If not, pop up login view
        [self performSegueWithIdentifier:UNWIND_SEGUE_IDENTIFIER sender:self];
    }
 
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
    
   
    
    if ([segue.identifier isEqualToString:UNWIND_SEGUE_IDENTIFIER]) {
        NSLog(@"Calling login");
    }
    
    if ([segue.destinationViewController conformsToProtocol:@protocol(AcceptsManagedContext)]) {
            
        // Need to pass managedObjectContext through
        id<AcceptsManagedContext> controller = segue.destinationViewController;
        controller.managedObjectContext  = self.managedObjectContext;
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
