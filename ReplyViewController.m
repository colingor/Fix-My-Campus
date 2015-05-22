//
//  ReplyViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 22/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "ReplyViewController.h"
#import "AppDelegate.h"
#import "Report.h"
@interface ReplyViewController ()
@property (weak, nonatomic) IBOutlet UITextView *commentsTextView;
@property (strong, nonatomic) AppDelegate *appDelegate;

@end


@implementation ReplyViewController

#define UNWIND_SEGUE_IDENTIFIER @"goToComments"

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void)setReport:(Report *)report
{
    _report = report;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(AppDelegate *)appDelegate{
    if (!_appDelegate) {
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}

- (IBAction)send:(id)sender {
    
    NSLog(@"Send response to jitbit and return to comments page");
    
    // Post comment to jitBit
    NSString *text = self.commentsTextView.text;
    
    //TODO: Check length of text
    
    NSString *apiStr = @"https://eaudit.jitbit.com/helpdesk/api/comment";
    
    NSURL *apiUrl = [NSURL URLWithString:[apiStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiUrl];
    [request setHTTPMethod:@"POST"];
    
    NSString *postString = [NSString stringWithFormat:@"id=%@&body=%@", self.report.ticket_id, text];
    
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    // another configuration option is backgroundSessionConfiguration (multitasking API required though)
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
   
    NSString *authValue = [self.appDelegate encodedCredentials];
    [configuration setHTTPAdditionalHeaders:@{@"Authorization": authValue}];
    
    NSURLSession *session  = [NSURLSession sessionWithConfiguration:configuration];

    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      // this handler is not executing on the main queue, so we can't do UI directly here
                                      if (error) {
                                          NSLog(@"%@",error);
                                      }else{
                                          NSLog(@"Comment posted successfully");
                                      }
                                      
                                  }];
    [task resume]; // don't forget that all NSURLSession tasks start out suspended!
    
    
    [self dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSLog(@"HERE %@", [segue identifier] );
    
    if ([[segue identifier] isEqualToString:UNWIND_SEGUE_IDENTIFIER])
    {
        NSLog(@"Heading back to comments page");
    }else{
        NSLog(@"HEre");
    }
}


@end
