//
//  LocationDetailsViewController.m
//  Estates Audit
//
//  Created by Ian Fieldhouse on 12/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "LocationViewController.h"
#import "LocationDetailsViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "AddFacilityViewController.h"
#import "ElasticSeachAPI.h"

@interface LocationDetailsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *buildingAreas;
@property (strong, nonatomic) NSMutableArray *buildingItems;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UILabel *subheaderLabel;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@end

@implementation LocationDetailsViewController

NSString *const IMAGE_SUFFIX = @".JPG";
NSString *const DEFAULT_CELL_IMAGE = @"MapPinDefaultLeftCallout";
NSString *const BASE_IMAGE_URL = @"http://dlib-brown.edina.ac.uk/buildings/images/";

-(void)viewWillAppear:(BOOL)animated{
  
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tabBar.delegate = self;
    
    // Populate table with call the ElasticSearch with buildingId
    [self refresh:nil];
    
    [self styleTabBar];
}

- (void)viewDidLoad {
    [super viewDidLoad];
  
    // Have to manually add refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

    [self.tableView addSubview:refreshControl];
    
    self.headerLabel.textColor = [[self view]tintColor];
    self.subheaderLabel.textColor = [[self view]tintColor];
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    
    [[ElasticSeachAPI sharedInstance] searchForBuildingWithId:self.buildingId
                                               withCompletion:^(NSMutableDictionary *source) {
                                                   
                                                   self.source = source;
                                                   
                                               
                                                   NSString *imageStem = [self.source valueForKeyPath:@"properties.image"];
                                                   NSString *imagePath = [NSString stringWithFormat:@"%@%@%@", BASE_IMAGE_URL, imageStem, IMAGE_SUFFIX];
                             
                                                   
                                                   [self.imageView sd_setImageWithURL:[NSURL URLWithString:[imagePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                                                                     placeholderImage:[UIImage imageNamed:DEFAULT_CELL_IMAGE]];
                                                   
                                                   self.buildingAreas = [self.source valueForKeyPath:@"properties.information"];
                                                   
                                                   // Important to clear this first otherwise table won't be updated
                                                   self.buildingItems = nil;
                                                   
                                                   for (NSDictionary *area in self.buildingAreas){
                                                       NSArray *areaItems = [area valueForKey:@"items"];
                                                       for (NSDictionary *item in areaItems){
                                                           [self.buildingItems addObject:item];
                                                       }
                                                   }
                     
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       
                                                       self.headerLabel.text = [self.source valueForKeyPath:@"properties.title"];
                                                       self.subheaderLabel.text = [self.source valueForKeyPath:@"properties.subtitle"];
                                                       
                                                       [self.tableView reloadData];
                                                       
                                                       if(refreshControl){
                                                            [refreshControl endRefreshing];
                                                       }
                                                      
                                                   });
                                               }];
   
}


- (void) styleTabBar{
    // Get rid of tabbar gradient
    [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
    
    
    // Selected image tint colour
    [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    
    
    [self.tabBar setSelectedItem:[self.tabBar.items objectAtIndex:0]];
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:15.0f],
                                                        NSForegroundColorAttributeName : [UIColor whiteColor]
                                                        } forState:UIControlStateSelected];
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:15.0f],
                                                        NSBackgroundColorAttributeName : [UIColor whiteColor]
                                                        } forState:UIControlStateNormal];
}


- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    if ([item.title isEqualToString:@"Add Facility"]) { // or whatever your title is
        [self performSegueWithIdentifier:@"Add Facility" sender:self];
    }
}


-(IBAction) unwindToLocationDetails:(UIStoryboardSegue *)segue {
    
    // POST to ElasticSearch (Note that self.source has been updated in AddFacilityViewController with new facility at this point)
    [[ElasticSeachAPI sharedInstance] postBuildingFacilityToBuilding:self.buildingId withQueryJson: self.source
                                                      withCompletion:^(NSDictionary *result) {
                                                          NSLog(@"Facility added");
                                                          
                                                          // Refresh to ensure new facility is added to table
                                                          [self refresh:nil];
                                                          
                                                      }];
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
    
    NSString *address = [self.source valueForKeyPath:@"properties.title"];
    NSString *department = [self.source valueForKeyPath:@"properties.subtitle"];
    
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
    
    NSString *lonStr = [NSString stringWithFormat:@"%@", [self.source valueForKeyPath:@"geometry.location"][0]];
    NSNumber *lon = [f numberFromString:lonStr];
    
    NSString *latStr = [NSString stringWithFormat:@"%@", [self.source valueForKeyPath:@"geometry.location"][1]];
    NSNumber *lat = [f numberFromString:latStr];
    
    NSString *imageStem = [item valueForKeyPath:@"image"];
    
    NSString *imagePath = [NSString stringWithFormat:@"%@%@%@", BASE_IMAGE_URL, imageStem, IMAGE_SUFFIX];

    [reportDictionary setValue:loc_desc forKey:@"loc_desc"];
    [reportDictionary setValue:lon forKey:@"lon"];
    [reportDictionary setValue:lat forKey:@"lat"];
    
    if([imageStem length] > 0){
        [reportDictionary setValue:imagePath forKey:@"photo_url"];
    }
    return reportDictionary;
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
    cell.textLabel.text = @"";
    NSUInteger offset = [self offsetForSection:indexPath.section];
    NSDictionary *item = [self.buildingItems objectAtIndex:indexPath.row + offset];
    if (item) {
        cell.imageView.image = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell setTintColor:[UIColor darkTextColor]];
        NSString *imageStem = [item valueForKeyPath:@"image"];
        
        NSString *imagePath = [NSString stringWithFormat:@"%@%@%@", BASE_IMAGE_URL, imageStem, IMAGE_SUFFIX];
     
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[imagePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                          placeholderImage:[UIImage imageNamed:@"MapPinDefaultLeftCallout"]];
        
        
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
    if ([[segue identifier] isEqualToString:@"Add Facility"]){
        if ([segue.destinationViewController isKindOfClass:[AddFacilityViewController class]]) {
            AddFacilityViewController *afvc = (AddFacilityViewController *)segue.destinationViewController;
          
            NSDictionary *buildingInfo = @{ @"buildingId" : self.buildingId, @"buildingName": self.headerLabel.text};
            afvc.buildingInfo = buildingInfo;
            afvc.source = self.source;
        }
    }
}


@end
