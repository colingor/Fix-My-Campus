//
//  ReplyViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 22/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "ReplyViewController.h"

@interface ReplyViewController ()
@property (weak, nonatomic) IBOutlet UITextView *commentsTextView;

@end

@implementation ReplyViewController

#define UNWIND_SEGUE_IDENTIFIER @"goToComments"

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)send:(id)sender {
    
    NSLog(@"Send response to jitbit and return to comments page");
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
