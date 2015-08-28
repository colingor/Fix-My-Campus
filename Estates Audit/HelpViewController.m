//
//  HelpViewController.m
//  Estates Audit
//
//  Created by Colin Gormley on 27/08/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "HelpViewController.h"

@interface HelpViewController ()

@end

@implementation HelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated {
    // We need to do this explictely otherwise the navbar won't appear
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
}

@end
