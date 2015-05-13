//
//  LocationDetailsViewController.m
//  Estates Audit
//
//  Created by Ian Fieldhouse on 12/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "LocationDetailsViewController.h"

@interface LocationDetailsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *buildingAreas;
@property (strong, nonatomic) NSMutableArray *buildingItems;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UILabel *subheaderLabel;

@end

@implementation LocationDetailsViewController

NSString *const IMAGES_DIR = @"EstatesBuildingsImages";
NSString *const IMAGE_SUFFIX = @".JPG";


- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.headerLabel.textColor = [[self view]tintColor];
    self.subheaderLabel.textColor = [[self view]tintColor];
    self.headerLabel.text = [self.location valueForKeyPath:@"properties.title"];
    self.subheaderLabel.text = [self.location valueForKeyPath:@"properties.subtitle"];
    
    NSString *imageStem = [self.location valueForKeyPath:@"properties.image"];
    NSString *imagePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingFormat:@"/%@/%@%@", IMAGES_DIR, imageStem, IMAGE_SUFFIX];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    UIImage *locationStreetView = [UIImage imageWithContentsOfFile:imagePath];
    self.imageView.image = locationStreetView;
    
    self.buildingAreas = [self.location valueForKeyPath:@"properties.information"];
    for (NSDictionary *area in self.buildingAreas){
        NSArray *areaItems = [area valueForKey:@"items"];
        for (NSDictionary *item in areaItems){
            [self.buildingItems addObject:item];
        }
    }
}

- (NSMutableArray *)buildingItems
{
    if (!_buildingItems){
        _buildingItems = [[NSMutableArray alloc] init];
    }
    
    return _buildingItems;
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.buildingAreas count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *buildingArea = [self.buildingAreas objectAtIndex:section];
    NSArray *areaItems = [buildingArea objectForKey:@"items"];
    return [areaItems count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *buildingArea = [self.buildingAreas objectAtIndex:section];
    NSString *areaTitle = [buildingArea valueForKey:@"area"];
    return areaTitle;
}

    
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Building Area Detail" forIndexPath:indexPath];
    NSDictionary *item = [self.buildingItems objectAtIndex:indexPath.row];
    if (item) {
        cell.textLabel.text = [item valueForKeyPath:@"description"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Type: %@", [item valueForKey:@"type"]];
    }
    return cell;
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
