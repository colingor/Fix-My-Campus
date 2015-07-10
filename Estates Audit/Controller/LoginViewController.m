//
//  LoginViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 20/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

#define UNWIND_SEGUE_IDENTIFIER @"goHome"


@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = NO;
    [[UITextField appearance] setTintColor:[UIColor blackColor]];
    [self.usernameTextField becomeFirstResponder];
    // Do any additional setup after loading the view.
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginClicked:(id)sender {
    // Do jitBit login stuff
    
    NSString *username = [self.usernameTextField text];
    NSString *password = [self.passwordTextField text];
    
    if([self checkLoginDetailsWithUser:username password:password]){
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate setUserName:(NSString *)username withPassword:(NSString *)password];
        
        
        //Check credentials are valid
        
        NSString *apiStr = [NSString stringWithFormat:@"https://eaudit.jitbit.com/helpdesk/api/categories"];
        
        NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
        
        
        // another configuration option is backgroundSessionConfiguration (multitasking API required though)
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSString *authValue = [appDelegate encodedCredentials];
        [configuration setHTTPAdditionalHeaders:@{@"Authorization": authValue}];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
        
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (error) {
                
                // Ensure we're on the main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // Delete username and pass from keychain
                    [appDelegate deleteCredentialsForUser: username];
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login problem"
                                                                    message:@"Please supply a valid username and password"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                 
                });
            }else{
                // Don't care about results - just the fact there wasn't an error means the credentials are ok. Dismiss login modal.
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Have to perform segue on main thread
                    [self performSegueWithIdentifier:UNWIND_SEGUE_IDENTIFIER sender:self];
                });
            }
            
        }];
        [task resume];
        
        
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login problem"
                                                        message:@"Please supply a username and password"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
}


-(BOOL)checkLoginDetailsWithUser:(NSString *) username password:(NSString *)password
{
    if([password length] >0 && [username length]> 0){
        return TRUE;
    }
    return FALSE;
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:UNWIND_SEGUE_IDENTIFIER]) {
        NSLog(@"Returning home");
    }
    
}


@end
