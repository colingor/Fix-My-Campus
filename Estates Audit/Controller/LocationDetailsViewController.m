//
//  LocationDetailsViewController.m
//  Estates Audit
//
//  Created by Ian Fieldhouse on 12/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "LocationViewController.h"
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
NSString *const DEFAULT_CELL_IMAGE = @"MapPinDefaultLeftCallout";


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


enum AlertButtonIndex : NSInteger
{
    AlertButtonNo,
    AlertButtonYes
};


- (void)useLocationAlert
{
    [[[UIAlertView alloc] initWithTitle:@"Location selected" message:@"Use this location for report?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index
{
    if (index == AlertButtonYes){
        [self performSegueWithIdentifier:@"Return To Location" sender:self];
    } else {
        NSLog(@"No clicked");
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}


- (NSMutableDictionary *)reportDictionary {
    NSMutableDictionary *reportDictionary = [[NSMutableDictionary alloc] init];
    
    NSString *address = [self.location valueForKeyPath:@"properties.title"];
    NSString *department = [self.location valueForKeyPath:@"properties.subtitle"];
    
    NSDictionary *areaDict = [[self buildingAreas] objectAtIndex:[[self.tableView indexPathForSelectedRow] section]];
    NSString *area= [areaDict valueForKey:@"area"];
    
    NSArray *items = [areaDict valueForKey:@"items"];
    NSDictionary *item = [items objectAtIndex:[[self.tableView indexPathForSelectedRow] row]];
    NSString *type = [item valueForKey:@"type"];
    NSString *description = [item valueForKey:@"description"];
    
    NSString *loc_desc = [NSString stringWithFormat:@"Address: %@\n", address];
    loc_desc = [loc_desc stringByAppendingString:[NSString stringWithFormat:@"Department: %@\n", department]];
    loc_desc = [loc_desc stringByAppendingString:[NSString stringWithFormat:@"Area of Building: %@\n", area]];
    loc_desc = [loc_desc stringByAppendingString:[NSString stringWithFormat:@"Location Type: %@\n", type]];
    loc_desc = [loc_desc stringByAppendingString:[NSString stringWithFormat:@"Description: %@\n", description]];
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    
    NSString *lonStr = [NSString stringWithFormat:@"%@", [self.location valueForKeyPath:@"geometry.coordinates"][0]];
    NSNumber *lon = [f numberFromString:lonStr];
    
    NSString *latStr = [NSString stringWithFormat:@"%@", [self.location valueForKeyPath:@"geometry.coordinates"][1]];
    NSNumber *lat = [f numberFromString:latStr];
    
    NSString *imageStem = [item valueForKeyPath:@"image"];
    NSString *imagePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingFormat:@"/%@/%@%@", IMAGES_DIR, imageStem, IMAGE_SUFFIX];
    
    [reportDictionary setValue:loc_desc forKey:@"loc_desc"];
    [reportDictionary setValue:lon forKey:@"lon"];
    [reportDictionary setValue:lat forKey:@"lat"];
    [reportDictionary setValue:imagePath forKey:@"photo_url"];
    
    return reportDictionary;
}


- (UIImage *)thumbnailImageFromImage:(UIImage *)image {
    
    UIImage *originalImage = image;
    CGSize destinationSize = CGSizeMake(60.0, 60.0);
    UIGraphicsBeginImageContext(destinationSize);
    [originalImage drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
    UIImage *thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return thumbnailImage;
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
    NSUInteger offset = [self offsetForSection:indexPath.section];
    NSDictionary *item = [self.buildingItems objectAtIndex:indexPath.row + offset];
    if (item) {
        cell.imageView.image = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell setTintColor:[UIColor darkTextColor]];
        NSString *imageStem = [item valueForKeyPath:@"image"];
        UIImage *thumbnail;
        if ([imageStem length] != 0) {
            NSString *imagePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingFormat:@"/%@/%@%@", IMAGES_DIR, imageStem, IMAGE_SUFFIX];
            thumbnail = [self thumbnailImageFromImage:[UIImage imageWithContentsOfFile:imagePath]];
        } else {
            thumbnail = [self thumbnailImageFromImage:[UIImage imageNamed:DEFAULT_CELL_IMAGE]];
        }
        cell.imageView.image = thumbnail;
        cell.textLabel.text = [item valueForKeyPath:@"description"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Type: %@", [item valueForKey:@"type"]];
    }
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [self useLocationAlert];
}


- (NSUInteger)offsetForSection:(NSInteger)section{
    NSUInteger offset = 0;
    NSUInteger count = 0;
    while (count < section){
        NSDictionary *buildingArea = [self.buildingAreas objectAtIndex:count];
        NSArray *areaItems = [buildingArea objectForKey:@"items"];
        offset = offset + [areaItems count];
        count++;
    }
    return offset;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"Return To Location"]){
        if ([segue.destinationViewController isKindOfClass:[LocationViewController class]]) {
            LocationViewController *lvc = (LocationViewController *)segue.destinationViewController;
            lvc.reportDict = [self reportDictionary];
        }
    }
}


@end
