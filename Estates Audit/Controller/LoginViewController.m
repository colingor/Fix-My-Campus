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

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
        
        // Dismiss
        [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
